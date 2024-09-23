import 'dart:typed_data';

import 'package:http_sfv/http_sfv.dart';
import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidItemTest = (
  String encoded,
  StructuredFieldItem value,
);

final List<_ValidItemTest> _validValues = [
  ('0', StructuredFieldItem(StructuredFieldItemValue(0))),
  ('-42', StructuredFieldItem(StructuredFieldItemValue(-42))),
  ('42', StructuredFieldItem(StructuredFieldItemValue(42))),
  ('1.1', StructuredFieldItem(StructuredFieldItemValue(1.1))),
  ('foo', StructuredFieldItem(StructuredFieldItemValue.token('foo'))),
  (
    ':AAE=:',
    StructuredFieldItem(StructuredFieldItemValue(Uint8List.fromList([0, 1])))
  ),
  ('?0', StructuredFieldItem(StructuredFieldItemValue(false))),
];

const List<String> _invalid = [
  '?2',
  '',
  '?',
];

void main() {
  group('Item', () {
    for (final (encoded, value) in _validValues) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItem.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    test('valid parameters', () {
      final item = StructuredFieldItem(StructuredFieldItemValue.token('bar'));
      item.parameters['foo'] = StructuredFieldItemValue(0.0);
      item.parameters['baz'] = StructuredFieldItemValue(true);
      expect(item.encode(), 'bar;foo=0.0;baz');
    });

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
