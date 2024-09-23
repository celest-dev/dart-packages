import 'package:http_sfv/http_sfv.dart';
import 'package:test/test.dart';

const List<String> _invalid = [
  'é',
  'foo="é"',
  'foo;é',
  'f="foo" é',
  'f="foo",',
  '0foo="bar"',
  'mAj="bar"',
  '_foo="bar"',
];

void main() {
  group('Dictionary', () {
    test('empty is valid', () {
      const encoded = '';
      final value = StructuredFieldDictionary({});
      expect(StructuredFieldDictionary.decode(encoded), value);
    });

    test('isValid', () {
      final expected = StructuredFieldDictionary({
        'a': StructuredFieldItem(StructuredFieldItemValue(false)),
        'b': StructuredFieldItem(StructuredFieldItemValue(true)),
        'c': StructuredFieldItem(
          StructuredFieldItemValue(true),
          parameters: StructuredFieldParameters({
            'foo': StructuredFieldItemValue.token('bar'),
          }),
        ),
      });

      const encoded = 'a=?0, b, c; foo=bar';
      final value = StructuredFieldDictionary.decode(encoded);
      expect(value, expected);
      expect(value.encode(), 'a=?0, b, c;foo=bar');
    });

    test('map operations', () {
      final dictionary = StructuredFieldDictionary({
        'f_o1o3-': StructuredFieldItem(StructuredFieldItemValue(10.0)),
        'deleteme': StructuredFieldItem(StructuredFieldItemValue('')),
        '*f0.o*': StructuredFieldItem(StructuredFieldItemValue('')),
        't': StructuredFieldItem(StructuredFieldItemValue(true)),
        'f': StructuredFieldItem(StructuredFieldItemValue(false)),
        'b': StructuredFieldItem(StructuredFieldItemValue([0, 1])),
      });

      dictionary['f_o1o3-'] =
          StructuredFieldItem(StructuredFieldItemValue(123.0));
      expect(dictionary['f_o1o3-'],
          StructuredFieldItem(StructuredFieldItemValue(123.0)));

      expect(dictionary.remove('deleteme'),
          StructuredFieldItem(StructuredFieldItemValue('')));
      expect(dictionary.remove('deleteme'), isNull);

      expect(
        dictionary['*f0.o*'],
        isA<StructuredFieldItem>().having((i) => i.value, 'value', ''),
      );

      expect(dictionary['doesnotexist'], isNull);

      expect(dictionary, hasLength(5));

      final value = dictionary['f_o1o3-'] as StructuredFieldItem;
      value.parameters['foo'] = StructuredFieldItemValue(9.5);

      expect(
        dictionary.encode(),
        r'f_o1o3-=123.0;foo=9.5, *f0.o*="", t, f=?0, b=:AAE=:',
      );
    });

    for (final encoded in _invalid) {
      test('isInvalid: $encoded', () {
        expect(
          () => StructuredFieldDictionary.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
