import 'package:http_sfv/src/character.dart';
import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidStringTest = (
  String encoded,
  StructuredFieldItemValue expected,
);

final List<_ValidStringTest> _valid = [
  (r'"foo"', StructuredFieldItemValue.string('foo')),
  (r'"b\"a\\r"', StructuredFieldItemValue.string(r'b"a\r')),
  (r'"f\"oo"', StructuredFieldItemValue.string(r'f"oo')),
  (r'"f\\oo"', StructuredFieldItemValue.string(r'f\oo')),
  (r'"f\\\"oo"', StructuredFieldItemValue.string(r'f\"oo')),
  (r'""', StructuredFieldItemValue.string('')),
  (r'"H3lLo"', StructuredFieldItemValue.string("H3lLo")),
];

const List<String> _invalidValues = [
  "hel\tlo",
  "hel\x1flo",
  "hel\x7flo",
  "Kévin",
  '\t',
];

final List<String> _invalid = [
  '',
  'a',
  r'"\',
  r'"\o',
  '"\x00"',
  '"${String.fromCharCode(Character.maxAscii)}"',
  '"foo',
];

void main() {
  group('String', () {
    for (final (encoded, value) in _valid) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItemValueString.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructuredFieldItemValueString.decode(encoded),
          throwsFormatException,
        );
      });
    }

    for (final value in _invalidValues) {
      test('isInvalidValue: "$value"', () {
        expect(
          () => StructuredFieldItemValue.string(value),
          throwsFormatException,
        );
      });
    }
  });
}
