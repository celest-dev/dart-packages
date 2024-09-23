import 'dart:collection';

// ignore: implementation_imports
import 'package:http_sfv/src/character.dart';

/// {@template cloud_http.tracestate}
/// The parsed value of the `tracestate` header as defined in the W3C Trace
/// Context specification.
///
/// See: https://www.w3.org/TR/trace-context-2/#tracestate-header
/// {@endtemplate}
final class Tracestate extends UnmodifiableMapBase<TracestateKey, String> {
  /// {@macro cloud_http.tracestate}
  Tracestate(this._map);

  /// Creates a [Tracestate] from a [Map].
  ///
  /// Throws a [FormatException] if the map contains invalid keys or values.
  factory Tracestate.from(Map<String, String> map) {
    return Tracestate(
      map.map((k, v) => MapEntry(TracestateKey.parse(k), v)),
    );
  }

  /// Parses the [tracestate] header.
  ///
  /// Throws a [FormatException] for invalid header formats. Use [tryParse] to
  /// discard parsing errors.
  factory Tracestate.parse(String tracestate) {
    final parser = _TracestateParser(tracestate);
    final values = parser.parse();
    final numValues = values.length;
    final maxValues = 32;
    if (numValues > maxValues) {
      throw FormatException(
        'Too many entries ($numValues > $maxValues)',
        tracestate,
      );
    }
    return Tracestate(values);
  }

  /// Tries to parse the [tracestate] header.
  static Tracestate? tryParse(String tracestate) {
    try {
      return Tracestate.parse(tracestate);
    } on FormatException {
      return null;
    }
  }

  final Map<TracestateKey, String> _map;

  @override
  String? operator [](Object? key) => _map[key as TracestateKey];

  @override
  Iterable<TracestateKey> get keys => _map.keys;

  @override
  String toString() {
    return _map.entries.map((entry) => '${entry.key}=${entry.value}').join(',');
  }
}

final class _TracestateParser {
  _TracestateParser(this.header)
      : _codeUnits = header.codeUnits as List<Character>;

  final String header;
  final List<Character> _codeUnits;
  int _offset = 0;

  bool get isEof => _offset == _codeUnits.length;
  Never _unexpectedEof() => throw FormatException('Unexpected end of input');

  Character _peek() {
    if (isEof) _unexpectedEof();
    return _codeUnits[_offset];
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

  TracestateKey _parseKey() {
    final start = _offset;
    while (!isEof) {
      final char = _peek();
      if (!char.isValidTracestateKeyChar && char != Character.at) {
        break;
      }
      _offset++;
    }
    final key = header.substring(start, _offset);
    return TracestateKey.parse(key);
  }

  String _parseValue() {
    final start = _offset;
    int? end;
    var leadingWhitespace = true;
    while (!isEof) {
      final char = _peek();
      if (char == Character.comma) {
        break;
      }
      // All leading spaces MUST be preserved as part of the value.
      //
      // All trailing spaces are considered to be optional whitespace characters
      // not part of the value. Optional trailing whitespace MAY be excluded
      // when propagating the header.
      if (char == Character.space) {
        _offset++;
        if (!leadingWhitespace) {
          end ??= _offset;
        }
        continue;
      }
      if (!char.isValidTracestateValueChar) {
        throw FormatException('Invalid value character', header, _offset);
      }
      leadingWhitespace = false;
      end = ++_offset;
    }
    end ??= _offset;
    if (start == end || leadingWhitespace) {
      throw FormatException('Empty value', header, end);
    }
    final length = end - start;
    const maxLength = 256;
    if (length > maxLength) {
      throw FormatException(
        'Value too long ($length > $maxLength)',
        header,
        end,
      );
    }
    final value = header.substring(start, end);
    return value;
  }

  Map<TracestateKey, String> parse() {
    final values = <TracestateKey, String>{};

    while (!isEof) {
      _skipOptionalWhitespace();
      final key = _parseKey();
      _skipOptionalWhitespace();
      if (_peek() case != Character.equals && != Character.at) {
        throw FormatException('Expected "="');
      }
      _offset++;
      final value = _parseValue();
      values[key] = value;
      if (!isEof && _peek() == Character.comma) {
        _offset++;
      }
    }

    return values;
  }
}

sealed class TracestateKey {
  const TracestateKey._();

  factory TracestateKey.parse(String key) {
    final at = key.indexOf('@');
    if (at == -1) {
      return TracestateSimpleKey(key);
    }
    return TracestateMultiTenantKey(
      tenantId: key.substring(0, at),
      systemId: key.substring(at + 1),
    );
  }

  String get key;

  @override
  bool operator ==(Object other) {
    return other is TracestateKey && key == other.key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

extension TracestateCharacter on Character {
  /// Section [3.3.2.2.1](https://www.w3.org/TR/trace-context-2/#key)
  ///
  ///     key = ( lcalpha / DIGIT ) 0*255 ( keychar )
  ///     keychar    = lcalpha / DIGIT / "_" / "-"/ "*" / "/" / "@"
  ///     lcalpha    = %x61-7A ; a-z
  bool get isValidTracestateKeyChar =>
      isLowerAlpha ||
      isDigit ||
      this == Character.underscore ||
      this == Character.dash ||
      this == Character.star ||
      this == Character.slash;

  /// Section [3.3.2.2.2](https://www.w3.org/TR/trace-context-2/#value)
  ///
  ///     value    = 0*255(chr) nblk-chr
  ///     nblk-chr = %x21-2B / %x2D-3C / %x3E-7E
  ///     chr      = %x20 / nblk-chr
  bool get isValidTracestateValueChar =>
      (this >= 0x21 && this <= 0x2B) ||
      (this >= 0x2D && this <= 0x3C) ||
      (this >= 0x3E && this <= 0x7E);
}

final class TracestateSimpleKey extends TracestateKey {
  factory TracestateSimpleKey(String key) {
    if (key.isEmpty || key.length > maxLength) {
      _badKey(key);
    }
    final codeUnits = key.codeUnits as List<Character>;
    if (!codeUnits[0].isLowerAlpha ||
        codeUnits.any((char) => !char.isValidTracestateKeyChar)) {
      _badKey(key);
    }
    return TracestateSimpleKey.raw(key);
  }

  const TracestateSimpleKey.raw(this.key) : super._();

  static const int maxLength = 256;
  static Never _badKey(String key) => throw FormatException(
        'key "$key" must conform to the ABNF grammar: '
        'simple-key = lcalpha 0*255( lcalpha / DIGIT / "_" / "-"/ "*" / "/" )',
      );

  @override
  final String key;
}

final class TracestateMultiTenantKey extends TracestateKey {
  factory TracestateMultiTenantKey({
    required String tenantId,
    required String systemId,
  }) {
    if (tenantId.isEmpty || tenantId.length > _tenantIdMaxLength) {
      _badTenantId(tenantId);
    }
    final tenantIdCodeUnits = tenantId.codeUnits as List<Character>;
    if (!tenantIdCodeUnits[0].isLowerAlpha && !tenantIdCodeUnits[0].isDigit) {
      _badTenantId(tenantId);
    }
    if (tenantIdCodeUnits.any((char) => !char.isValidTracestateKeyChar)) {
      _badTenantId(tenantId);
    }

    if (systemId.isEmpty || systemId.length > _systemIdMaxLength) {
      _badSystemId(systemId);
    }
    final systemIdCodeUnits = systemId.codeUnits as List<Character>;
    if (!systemIdCodeUnits[0].isLowerAlpha) {
      _badSystemId(systemId);
    }
    if (systemIdCodeUnits.any((char) => !char.isValidTracestateKeyChar)) {
      _badSystemId(systemId);
    }
    return TracestateMultiTenantKey.raw(
      tenantId: tenantId,
      systemId: systemId,
    );
  }

  const TracestateMultiTenantKey.raw({
    required this.tenantId,
    required this.systemId,
  }) : super._();

  static const int _tenantIdMaxLength = 241;
  static Never _badTenantId(String tenantId) => throw FormatException(
        'tenantId "$tenantId" must conform to the ABNF grammar: '
        'tenant-id = ( lcalpha / DIGIT ) 0*240( lcalpha / DIGIT / "_" / "-"/ "*" / "/" )',
      );

  static const int _systemIdMaxLength = 14;
  static Never _badSystemId(String systemId) => throw FormatException(
        'systemId "$systemId" must conform to the ABNF grammar: '
        'system-id = lcalpha 0*13( lcalpha / DIGIT / "_" / "-"/ "*" / "/" )',
      );

  @override
  String get key => '$tenantId@$systemId';

  final String tenantId;
  final String systemId;
}
