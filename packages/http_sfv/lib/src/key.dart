import 'character.dart';
import 'parser.dart';

extension type const Key._(String key) implements String {
  factory Key(String key) {
    if (key.isEmpty) {
      throw FormatException('Key cannot be empty');
    }
    final codeUnits = key.codeUnits as List<Character>;
    final first = codeUnits.first;
    if (!first.isLowerAlpha && first != Character.star) {
      throw FormatException('Key must start with an alpha character or "*"');
    }
    for (var index = 1; index < codeUnits.length; index++) {
      final char = codeUnits[index];
      if (!char.isKeyCharacter) {
        throw FormatException(
          'Invalid character in key: ${String.fromCharCode(char)}',
        );
      }
    }
    return Key._(key);
  }

  factory Key.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseKey();
  }

  String encode([StringBuffer? builder]) {
    builder?.write(key);
    return key;
  }
}
