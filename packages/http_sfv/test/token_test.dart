import 'package:http_sfv/http_sfv.dart';
import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidTokenTest = (
  String token,
  Token expected,
);

const List<String> _validValues = [
  r"abc'!#$%*+-.^_|~:/`",
  r"H3lLo",
  r"a*foo",
  r"a!1",
  r"a#1",
  r"a$1",
  r"a%1",
  r"a&1",
  r"a'1",
  r"a*1",
  r"a+1",
  r"a-1",
  r"a.1",
  r"a^1",
  r"a_1",
  r"a`1",
  r"a|1",
  r"a~1",
  r"a:1",
  r"a/1",
];

const List<String> _invalidValues = [
  r"0foo",
  r"!foo",
  "1abc",
  "",
  "hel\tlo",
  "hel\x1flo",
  "hel\x7flo",
  "Kévin",
];

final List<_ValidTokenTest> _valid = [
  ('t', Token('t')),
  ('tok', Token('tok')),
  ('*t!o&k', Token('*t!o&k')),
  ('t=', Token('t')),
];

const List<String> _invalid = ['', 'é'];

void main() {
  group('Token', () {
    for (final token in _validValues) {
      test('isValidValue: $token', () {
        expect(
          () => StructuredFieldItemValue.token(token),
          returnsNormally,
        );
      });
    }

    for (final token in _invalidValues) {
      test('isInvalidValue: $token', () {
        expect(
          () => StructuredFieldItemValue.token(token),
          throwsFormatException,
        );
      });
    }

    for (final (encoded, expected) in _valid) {
      test('isValid: "$encoded"', () {
        expect(
          StructuredFieldItemValueToken.decode(encoded),
          equals(expected),
        );
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructuredFieldItemValueToken.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
