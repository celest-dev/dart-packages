import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidIntegerTest = (
  String encoded,
  StructuredFieldItemValueInteger value,
);

final List<_ValidIntegerTest> _validValues = [
  ('10', StructuredFieldItemValueInteger(10)),
  ('-10', StructuredFieldItemValueInteger(-10)),
  ('0', StructuredFieldItemValueInteger(0)),
  ('-999999999999999', StructuredFieldItemValueInteger(-999999999999999)),
  ('999999999999999', StructuredFieldItemValueInteger(999999999999999)),
];

const List<int> _invalidValues = [
  9999999999999999,
  -9999999999999999,
];

void main() {
  group('Integer', () {
    for (final (encoded, value) in _validValues) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItemValueInteger.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final value in _invalidValues) {
      test('isInvalidValue: "$value"', () {
        expect(() => StructuredFieldItemValueInteger(value), throwsRangeError);
      });
    }
  });
}
