import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http_sfv/http_sfv.dart';
import 'package:http_sfv/src/character.dart';
import 'package:http_sfv/src/parser.dart';

extension type const StructuredFieldItemValue._(Object value)
    implements Object {
  factory StructuredFieldItemValue(Object value) {
    return switch (value) {
      bool() => StructuredFieldItemValue.bool(value),
      String() => StructuredFieldItemValue.string(value),
      int() => StructuredFieldItemValue.integer(value),
      double() => StructuredFieldItemValue.decimal(value),
      Uint8List() => StructuredFieldItemValue.binary(value),
      List<int>() => StructuredFieldItemValue.binary(Uint8List.fromList(value)),
      Token() => StructuredFieldItemValueToken._(value),
      _ => throw FormatException(
          'Invalid bare item: "$value" (${value.runtimeType}). ',
          'Must be one of: bool, String, int, num, Uint8List, Token.',
        ),
    };
  }

  factory StructuredFieldItemValue.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseItemValue();
  }

  factory StructuredFieldItemValue.bool(bool value) =
      StructureFieldItemValueBool;
  factory StructuredFieldItemValue.string(String value) =
      StructuredFieldItemValueString;
  factory StructuredFieldItemValue.integer(int value) =
      StructuredFieldItemValueInteger;
  factory StructuredFieldItemValue.decimal(double value) =
      StructuredFieldItemValueDecimal;
  factory StructuredFieldItemValue.binary(Uint8List value) =
      StructuredFieldItemValueBinary;
  factory StructuredFieldItemValue.token(String value) =
      StructuredFieldItemValueToken;

  String encode([StringBuffer? builder]) {
    return switch (value) {
      final StructureFieldItemValueBool value => value.encode(builder),
      final StructuredFieldItemValueString value => value.encode(builder),
      final StructuredFieldItemValueInteger value => value.encode(builder),
      final StructuredFieldItemValueDecimal value => value.encode(builder),
      final StructuredFieldItemValueBinary value => value.encode(builder),
      final StructuredFieldItemValueToken value => value.encode(builder),
      _ => throw FormatException(
          'Invalid bare item: $this ($runtimeType)',
        ),
    };
  }

  bool equals(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (this case final Uint8List bytes) {
      if (other is! Uint8List) {
        return false;
      }
      return bytes.equals(other);
    }
    return this == other;
  }
}

extension type const StructureFieldItemValueBool(bool value)
    implements bool, StructuredFieldItemValue {
  static const String $true = '?1';
  static const String $false = '?0';

  factory StructureFieldItemValueBool.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseBool();
  }

  String encode([StringBuffer? builder]) {
    final value = this ? $true : $false;
    builder?.write(value);
    return value;
  }
}

extension type const StructuredFieldItemValueString._(String value)
    implements String, StructuredFieldItemValue {
  factory StructuredFieldItemValueString(String value) {
    final codeUnits = value.codeUnits as List<Character>;
    for (final char in codeUnits) {
      if (char.isInvalidAscii) {
        throw FormatException('Invalid ASCII character: $char');
      }
    }
    return StructuredFieldItemValueString._(value);
  }

  factory StructuredFieldItemValueString.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseString();
  }

  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    builder.writeCharCode(Character.doubleQuote);
    final codeUnits = this.codeUnits as List<Character>;
    for (final char in codeUnits) {
      if (char == Character.doubleQuote || char == Character.backslash) {
        builder.writeCharCode(Character.backslash);
      }
      builder.writeCharCode(char);
    }
    builder.writeCharCode(Character.doubleQuote);
    return builder.toString().substring(start);
  }
}

extension type const StructuredFieldItemValueNumber(num value)
    implements num, StructuredFieldItemValue {}

extension type const StructuredFieldItemValueInteger._(int value)
    implements int, StructuredFieldItemValueNumber {
  factory StructuredFieldItemValueInteger(int value) {
    if (value < $min || value > $max) {
      throw RangeError.value(value, 'int', 'Out of range');
    }
    return StructuredFieldItemValueInteger._(value);
  }

  factory StructuredFieldItemValueInteger.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseInteger();
  }

  static const int $min = -999999999999999;
  static const int $max = 999999999999999;

  String encode([StringBuffer? builder]) {
    final value = toString();
    builder?.write(value);
    return value;
  }
}

extension type const StructuredFieldItemValueDecimal._(double value)
    implements double, StructuredFieldItemValueNumber {
  factory StructuredFieldItemValueDecimal(double value) {
    if (value.isNaN || value.isInfinite) {
      throw FormatException('Invalid decimal value: $value');
    }
    return StructuredFieldItemValueDecimal._(value);
  }

  factory StructuredFieldItemValueDecimal.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseDecimal();
  }

  static const double $min = -999999999999;
  static const double $max = 999999999999;

  String encode([StringBuffer? builder]) {
    final encoded = _encoded;
    builder?.write(encoded);
    return encoded;
  }

  String get _encoded {
    const th = 0.001;
    final rounded = (this / th).round() * th;
    final (integer, fraction) = _mod(rounded);

    if (integer < $min || integer > $max) {
      throw RangeError.value(integer, 'int', 'Out of range');
    }

    var str = rounded.toStringAsFixed(3);
    final decimal = str.indexOf('.');
    if (decimal == -1) {
      return '$str.0';
    }
    if (fraction == 0) {
      return '${str.substring(0, decimal + 1)}0';
    }
    final codeUnits = str.codeUnits;
    for (var i = str.length - 1; i > decimal; i--) {
      if (codeUnits[i] != Character.zero) {
        return str.substring(0, i + 1);
      }
    }
    return str;
  }

  (double integer, double fraction) _mod(double f) {
    if (f < 0) {
      final (integer, fraction) = _mod(-f);
      return (-integer, -fraction);
    }
    if (f == 0) {
      return (f, f); // Return (-0, -0) when f == -0
    }
    if (f < 1) {
      return (0, f);
    }

    const shift = 64 - 11 - 1;
    const mask = 0x7FF;
    const bias = 1023;

    var x = f.bits;
    final e = (x >>> shift & mask) - bias;
    if (e < 64 - 12) {
      // Keep the top 12+e bits, the integer part; clear the rest.
      final clearFraction = (1 << (64 - 12 - e)) - 1;
      x &= ~clearFraction;
    }
    final integer = _Float64.fromBits(x);
    return (integer, f - integer);
  }
}

extension _Float64 on double {
  static double fromBits(int bits) {
    final typed = Uint64List(1)..[0] = bits;
    return Float64List.view(typed.buffer)[0];
  }

  int get bits {
    final typed = Float64List(1)..[0] = this;
    return Uint64List.view(typed.buffer)[0];
  }
}

extension type const StructuredFieldItemValueBinary(Uint8List value)
    implements Uint8List, StructuredFieldItemValue {
  factory StructuredFieldItemValueBinary.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return StructuredFieldItemValueBinary(parser.parseBytes());
  }

  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    builder
      ..writeCharCode(Character.colon)
      ..write(base64.encode(this))
      ..writeCharCode(Character.colon);
    return builder.toString().substring(start);
  }
}

extension type const StructuredFieldItemValueToken._(Token value)
    implements Token, StructuredFieldItemValue {
  factory StructuredFieldItemValueToken(String value) {
    if (value.isEmpty) {
      throw FormatException('Token cannot be empty');
    }
    final codeUnits = value.codeUnits as List<Character>;
    if (!codeUnits[0].isAlpha && codeUnits[0] != Character.star) {
      throw FormatException('Token must start with an alpha character or "*"');
    }
    for (var index = 1; index < codeUnits.length; index++) {
      final char = codeUnits[index];
      if (!char.isExtendedTokenCharacter) {
        throw FormatException('Invalid character in token: $char');
      }
    }
    return StructuredFieldItemValueToken._(Token(value));
  }

  factory StructuredFieldItemValueToken.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseToken();
  }

  String encode([StringBuffer? builder]) {
    builder?.write(value);
    return value.toString();
  }
}
