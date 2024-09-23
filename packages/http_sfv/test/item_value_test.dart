import 'dart:convert';

import 'package:http_sfv/http_sfv.dart';
import 'package:test/test.dart';

typedef _ValidBareItemTest = (
  String encoded,
  StructuredFieldItemValue value,
);

final List<_ValidBareItemTest> _validValues = [
  ('?1', StructuredFieldItemValue(true)),
  ('?0', StructuredFieldItemValue(false)),
  ('22', StructuredFieldItemValue(22)),
  ('-2.2', StructuredFieldItemValue(-2.2)),
  ('"foo"', StructuredFieldItemValue('foo')),
  ('abc', StructuredFieldItemValue.token('abc')),
  ('*abc', StructuredFieldItemValue.token('*abc')),
  (':YWJj:', StructuredFieldItemValue(utf8.encode('abc'))),
];

const List<String> _invalid = [
  '',
  '~',
];

void main() {
  group('ItemValue', () {
    for (final (encoded, value) in _validValues) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItemValue.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructuredFieldItemValue.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
