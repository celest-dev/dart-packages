@internal
library;

import 'dart:convert';
import 'dart:math';

import 'package:http_sfv/http_sfv.dart';
import 'package:http_sfv/src/character.dart';
import 'package:http_sfv/src/item_value.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

final class StructuredFieldValueParser {
  factory StructuredFieldValueParser(String value) {
    return StructuredFieldValueParser._(
      SourceSpan(
        SourceLocation(0),
        SourceLocation(value.length),
        value,
      ),
      value.codeUnits as List<Character>,
    );
  }

  StructuredFieldValueParser._(this._span, this._codeUnits);

  final SourceSpan _span;
  String get _value => _span.text;
  final List<Character> _codeUnits;
  int _offset = 0;

  bool get isEof => _offset == _codeUnits.length;

  Never _unexpectedEof() => _fail('Unexpected end of input');

  Never _unexpectedChar([String? message]) =>
      _fail(message ?? 'Unexpected character', _offset, 1);

  Never _fail(String message, [int? start, int? length]) {
    int tokenStart;
    if (start == null) {
      tokenStart = _offset;
      while (tokenStart.isWithin(0, _codeUnits.length) &&
          !_codeUnits[tokenStart].isOptionalWhitespace) {
        tokenStart--;
      }
    } else {
      tokenStart = start.clamp(0, _codeUnits.length);
    }
    assert(tokenStart >= 0);
    int tokenEnd = tokenStart;
    if (length == null) {
      tokenEnd = _offset;
      while (tokenEnd < _codeUnits.length &&
          !_codeUnits[tokenEnd].isOptionalWhitespace) {
        tokenEnd++;
      }
    } else {
      tokenEnd = min(tokenEnd + length, _codeUnits.length);
    }
    assert(tokenEnd <= _codeUnits.length);
    final tokenSpan = SourceSpanWithContext(
      SourceLocation(tokenStart),
      SourceLocation(tokenEnd),
      _value.substring(tokenStart, tokenEnd),
      _value,
    );
    throw FormatException('$message:\n${tokenSpan.highlight()}');
  }

  Character _peek() {
    if (isEof) _unexpectedEof();
    return _codeUnits[_offset];
  }

  Character _take() {
    if (isEof) _unexpectedEof();
    final char = _codeUnits[_offset];
    _offset++;
    return char;
  }

  void _skipSpaces() {
    while (!isEof) {
      if (_peek() != Character.space) {
        return;
      }
      _offset++;
    }
  }

  void _skipOptionalWhitespace() {
    while (!isEof) {
      final char = _peek();
      if (char != Character.space && char != Character.tab) {
        return;
      }
      _offset++;
    }
  }

  /// Parses a value with the given [type] as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#text-parse
  StructuredFieldValue parseValue(StructuredFieldValueType type) {
    _skipSpaces();
    final value = switch (type) {
      StructuredFieldValueType.item => parseItem(),
      StructuredFieldValueType.list => parseList(),
      StructuredFieldValueType.dictionary => parseDictionary(),
    };
    _skipSpaces();
    if (!isEof) {
      _unexpectedChar('Unexpected trailing characters');
    }
    return value;
  }

  /// Parses a bare item as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-bare-item
  StructuredFieldItemValue parseItemValue() {
    final char = _peek();
    return switch (char) {
      Character.minus => _parseNumber(),
      _ when char.isDigit => _parseNumber(),
      Character.doubleQuote => parseString(),
      Character.star => parseToken() as StructuredFieldItemValue,
      _ when char.isAlpha => parseToken() as StructuredFieldItemValue,
      Character.colon => parseBytes(),
      Character.questionMark => parseBool(),
      _ => _unexpectedChar(),
    };
  }

  /// Parses a string value as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-string
  StructuredFieldItemValueString parseString() {
    if (_take() != Character.doubleQuote) {
      _unexpectedChar('Expected a double quote (")');
    }

    final s = StringBuffer();
    while (!isEof) {
      final char = _take();
      switch (char) {
        case Character.backslash:
          final next = _take();
          if (next != Character.doubleQuote && next != Character.backslash) {
            _unexpectedChar('Invalid escape sequence');
          }
          s.writeCharCode(next);
        case Character.doubleQuote:
          return StructuredFieldItemValueString(s.toString());
        case _ when char.isInvalidAscii:
          _unexpectedChar('Invalid ASCII character');
        default:
          s.writeCharCode(char);
      }
    }

    _unexpectedChar('Missing closing double quote (")');
  }

  /// Parses a boolean value as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-boolean
  StructureFieldItemValueBool parseBool() {
    if (_take() != Character.questionMark) {
      _unexpectedChar('Expected a question mark (?)');
    }
    final next = _take();
    return switch (next) {
      Character.one => const StructureFieldItemValueBool(true),
      Character.zero => const StructureFieldItemValueBool(false),
      _ => _unexpectedChar('Expected a 0 or 1'),
    };
  }

  /// Parses a byte sequence as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-binary
  StructuredFieldItemValueBinary parseBytes() {
    if (_take() != Character.colon) {
      _unexpectedChar('Expected a colon (:)');
    }

    final start = _offset;
    while (!isEof) {
      final char = _take();
      if (char == Character.colon) {
        return StructuredFieldItemValueBinary(
          base64.decode(_value.substring(start, _offset - 1)),
        );
      }
      if (!char.isValidBase64) {
        _unexpectedChar('Invalid base64 character');
      }
    }

    _unexpectedChar('Missing closing colon (:)');
  }

  StructuredFieldItemValueNumber _parseNumber() {
    final (:value, :isNegative, :decimalOffset) = _parseNumberState();
    if (decimalOffset != null) {
      return _parseDecimal(value, isNegative, decimalOffset);
    }
    return _parseInteger(value, isNegative);
  }

  /// Parses an integer or decimal number as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-number
  _NumberState _parseNumberState() {
    final isNegative = _peek() == Character.minus;
    if (isNegative) _offset++;
    if (!_peek().isDigit) {
      _unexpectedChar('Expected a digit');
    }

    final start = _offset;

    int? decimalOffset;
    var isDecimal = false;
    while (!isEof) {
      final char = _peek();
      if (char.isDigit) {
        _offset++;
        continue;
      }

      if (!isDecimal && char == Character.decimal) {
        // The maximum number of characters for the input string.
        const maxInputLength = 12;
        final size = _offset - start;
        if (size > maxInputLength) {
          _unexpectedChar('Too many characters before the decimal point');
        }

        isDecimal = true;
        decimalOffset = _offset;
        _offset++;
        continue;
      }

      break;
    }

    final value = _value.substring(start, _offset);

    final maxTotalLength = isDecimal ? 16 : 15;
    if (value.length > maxTotalLength) {
      _unexpectedChar('Input is too large: ${value.length} > $maxTotalLength');
    }
    if (value.codeUnits.last == Character.decimal) {
      _unexpectedChar('Unexpected decimal point');
    }

    return (
      value: value,
      isNegative: isNegative,
      decimalOffset: decimalOffset,
    );
  }

  StructuredFieldItemValueInteger parseInteger() {
    final (:value, :isNegative, :decimalOffset) = _parseNumberState();
    if (decimalOffset != null) {
      _unexpectedChar('Expected an integer, but got a double');
    }
    return _parseInteger(value, isNegative);
  }

  StructuredFieldItemValueInteger _parseInteger(String value, bool isNegative) {
    var integer = int.parse(value);
    if (isNegative) {
      integer = -integer;
    }
    if (integer < StructuredFieldItemValueInteger.$min ||
        integer > StructuredFieldItemValueInteger.$max) {
      _unexpectedChar('Number is out of range');
    }
    return StructuredFieldItemValueInteger(integer);
  }

  StructuredFieldItemValueDecimal parseDecimal() {
    final (:value, :isNegative, :decimalOffset) = _parseNumberState();
    if (decimalOffset == null) {
      _unexpectedChar('Expected a digit after the decimal point');
    }
    return _parseDecimal(value, isNegative, decimalOffset);
  }

  StructuredFieldItemValueDecimal _parseDecimal(
    String value,
    bool isNegative,
    int decimalOffset,
  ) {
    const maxDecimalDigits = 3;
    if (_offset - (decimalOffset + 1) > maxDecimalDigits) {
      _unexpectedChar('Too many digits after the decimal point');
    }
    final decimal = double.parse(value);
    return StructuredFieldItemValueDecimal(isNegative ? -decimal : decimal);
  }

  /// Parses a token as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-token
  StructuredFieldItemValueToken parseToken() {
    final start = _offset;
    final first = _take();
    if (!first.isAlpha && first != Character.star) {
      _unexpectedChar('Token must start with an alpha character or "*"');
    }

    while (!isEof) {
      if (!_peek().isExtendedTokenCharacter) {
        break;
      }
      _offset++;
    }

    return StructuredFieldItemValueToken(_value.substring(start, _offset));
  }

  /// Parses a key as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-key
  Key parseKey() {
    final start = _offset;
    final first = _take();
    if (!first.isLowerAlpha && first != Character.star) {
      _unexpectedChar('Key must start with an alpha character or "*"');
    }

    while (!isEof) {
      if (!_peek().isKeyCharacter) {
        break;
      }
      _offset++;
    }

    return Key(_value.substring(start, _offset));
  }

  /// Parses a parameters map as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-param
  StructuredFieldParameters parseParameters() {
    final values = <Key, StructuredFieldItemValue>{};
    while (!isEof) {
      if (_peek() != Character.semiColon) {
        break;
      }
      _offset++;
      _skipSpaces();

      final key = parseKey();
      StructuredFieldItemValue value = const StructureFieldItemValueBool(true);
      if (!isEof && _peek() == Character.equals) {
        _offset++;
        value = parseItemValue();
      }
      values[key] = value;
    }
    return StructuredFieldParameters(values);
  }

  /// Parses a list as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-list
  StructuredFieldList parseList() {
    final members = <StructuredFieldMember>[];
    while (!isEof) {
      final member = parseMember();
      members.add(member);
      _skipOptionalWhitespace();
      if (isEof) {
        break;
      }
      if (_take() != Character.comma) {
        _unexpectedChar('Expected a comma (,)');
      }
      _skipOptionalWhitespace();
      if (isEof) {
        _unexpectedChar('Unexpected trailing comma');
      }
    }
    return StructuredFieldList(members);
  }

  /// Parses an inner list as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-innerlist
  StructuredFieldInnerList parseInnerList() {
    if (_take() != Character.openParen) {
      _unexpectedChar('Expected an open parenthesis `(`');
    }
    final innerList = <StructuredFieldItem>[];
    while (!isEof) {
      _skipSpaces();
      if (_peek() == Character.closeParen) {
        _offset++;
        final parameters = parseParameters();
        return StructuredFieldInnerList(innerList, parameters: parameters);
      }
      final item = parseItem();
      innerList.add(item);

      final next = _peek();
      if (next != Character.space && next != Character.closeParen) {
        _unexpectedChar('Expected a space or close parenthesis `)`');
      }
    }

    _unexpectedChar('Missing closing parenthesis `)`');
  }

  /// Parses an item as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-item
  StructuredFieldItem parseItem() {
    final bareItem = parseItemValue();
    final parameters = parseParameters();
    return StructuredFieldItem(
      bareItem,
      parameters: parameters,
    );
  }

  /// Parses an item or inner list as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-item-or-list
  StructuredFieldMember parseMember() {
    if (_peek() == Character.openParen) {
      return parseInnerList();
    }
    return parseItem();
  }

  /// Parses a dictionary as specified in RFC8941:
  /// https://httpwg.org/specs/rfc8941.html#parse-dictionary
  StructuredFieldDictionary parseDictionary() {
    final values = <Key, StructuredFieldMember>{};
    while (!isEof) {
      final key = parseKey();
      StructuredFieldMember value;
      if (!isEof && _peek() == Character.equals) {
        _offset++;
        final member = parseMember();
        value = member;
      } else {
        final parameters = parseParameters();
        value = StructuredFieldItem(
          const StructureFieldItemValueBool(true),
          parameters: parameters,
        );
      }
      values[key] = value;
      _skipOptionalWhitespace();
      if (isEof) {
        break;
      }
      if (_take() != Character.comma) {
        _unexpectedChar('Expected a comma (,)');
      }
      _skipOptionalWhitespace();
      if (isEof) {
        _unexpectedChar('Unexpected trailing comma');
      }
    }
    return StructuredFieldDictionary(values);
  }
}

typedef _NumberState = ({
  String value,
  bool isNegative,
  int? decimalOffset,
});

extension on int {
  bool isWithin(int start, int end) => this >= start && this < end;
}
