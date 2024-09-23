import 'package:http_sfv/http_sfv.dart';
import 'package:test/test.dart';

typedef _ValidKeyTest = (
  String encoded,
  Key value,
);

final List<_ValidKeyTest> _validValues = [
  ('f1oo', Key('f1oo')),
  ('*foo0', Key('*foo0')),
  ('t', Key('t')),
  ('tok', Key('tok')),
  ('*k-.*', Key('*k-.*')),
];

const List<String> _invalidValues = ['fOo'];

const List<String> _invalid = [
  '',
  '1foo',
  'é',
];

void main() {
  group('Key', () {
    for (final (encoded, value) in _validValues) {
      test('isValid: "$encoded"', () {
        expect(Key.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    test('drops trailing non-key chars', () {
      expect(Key.decode('k='), 'k');
    });

    for (final value in _invalidValues) {
      test('isInvalidValue: "$value"', () {
        expect(() => Key(value).encode(), throwsFormatException);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(() => Key.decode(encoded), throwsFormatException);
      });
    }
  });
}
