import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidBoolTest = (
  String encoded,
  StructureFieldItemValueBool value,
);

const List<_ValidBoolTest> _valid = [
  ('?1', StructureFieldItemValueBool(true)),
  ('?0', StructureFieldItemValueBool(false)),
];

const List<String> _invalid = [
  '?2',
  '',
  '?',
];

void main() {
  group('Boolean', () {
    for (final (encoded, value) in _valid) {
      test('isValid: "$encoded"', () {
        expect(StructureFieldItemValueBool.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructureFieldItemValueBool.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
