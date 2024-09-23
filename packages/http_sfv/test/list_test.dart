import 'package:http_sfv/http_sfv.dart';
import 'package:test/test.dart';

typedef _ValidListTest = (
  String encoded,
  StructuredFieldList value,
);

final StructuredFieldList _fooBar = StructuredFieldList([
  StructuredFieldItem(StructuredFieldItemValue.token('foo')),
  StructuredFieldItem(StructuredFieldItemValue.token('bar')),
]);

final List<_ValidListTest> _valid = [
  ('', StructuredFieldList([])),
  ("foo,bar", _fooBar),
  ("foo, bar", _fooBar),
  ("foo,\t bar", _fooBar),
  (
    '"foo";bar;baz=tok',
    StructuredFieldList([
      StructuredFieldItem(
        StructuredFieldItemValue('foo'),
        parameters: StructuredFieldParameters({
          Key('bar'): StructuredFieldItemValue(true),
          Key('baz'): StructuredFieldItemValue.token('tok'),
        }),
      ),
    ]),
  ),
  (
    '(foo bar);bat',
    StructuredFieldList([
      StructuredFieldInnerList(
        [
          StructuredFieldItem(StructuredFieldItemValue.token('foo')),
          StructuredFieldItem(StructuredFieldItemValue.token('bar')),
        ],
        parameters: StructuredFieldParameters({
          Key('bat'): StructuredFieldItemValue(true),
        }),
      ),
    ]),
  ),
  ('()', StructuredFieldList([StructuredFieldInnerList([])])),
  (
    '   "foo";bar;baz=tok,  (foo bar);bat ',
    StructuredFieldList([
      StructuredFieldItem(
        StructuredFieldItemValue('foo'),
        parameters: StructuredFieldParameters({
          Key('bar'): StructuredFieldItemValue(true),
          Key('baz'): StructuredFieldItemValue.token('tok')
        }),
      ),
      StructuredFieldInnerList(
        [
          StructuredFieldItem(StructuredFieldItemValue.token('foo')),
          StructuredFieldItem(StructuredFieldItemValue.token('bar')),
        ],
        parameters: StructuredFieldParameters({
          Key('bat'): StructuredFieldItemValue(true),
        }),
      ),
    ]),
  ),
];

const List<String> _invalid = [
  'é',
  'foo,bar,',
  'foo,baré',
  'foo,"bar',
  '(foo ',
  '(foo);é',
  '("é")',
  '(""',
  '(',
];

void main() {
  group('List', () {
    for (final (encoded, value) in _valid) {
      test('isValid: $encoded', () {
        expect(StructuredFieldList.decode(encoded), value);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: $encoded', () {
        expect(
          () => StructuredFieldList.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
