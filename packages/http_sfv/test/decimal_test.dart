import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidDecimalTest = (
  String encoded,
  StructuredFieldItemValueDecimal value,
);

final List<_ValidDecimalTest> _validValues = [
  ('10.0', StructuredFieldItemValueDecimal(10.0)),
  ('-10.123', StructuredFieldItemValueDecimal(-10.123)),
  ('10.124', StructuredFieldItemValueDecimal(10.124)),
  ('-10.0', StructuredFieldItemValueDecimal(-10.0)),
  ('0.0', StructuredFieldItemValueDecimal(0.0)),
  ('-999999999999.0', StructuredFieldItemValueDecimal(-999999999999.0)),
  ('999999999999.0', StructuredFieldItemValueDecimal(999999999999.0)),
  ('1.9', StructuredFieldItemValueDecimal(1.9)),
];

const List<double> _invalidValues = [
  9999999999999,
  -9999999999999.0,
  9999999999999.0,
];

const List<String> _invalid = [
  '10.12345',
  '-10.12345',
];

void main() {
  group('Decimal', () {
    for (final (encoded, value) in _validValues) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItemValueDecimal.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final value in _invalidValues) {
      test('isInvalidValue: "$value"', () {
        expect(
          () => StructuredFieldItemValueDecimal(value).encode(),
          throwsRangeError,
        );
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructuredFieldItemValueDecimal.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
