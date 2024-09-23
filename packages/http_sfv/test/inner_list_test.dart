import 'dart:typed_data';

import 'package:http_sfv/http_sfv.dart';
import 'package:test/test.dart';

void main() {
  group('InnerList', () {
    test('valid list', () {
      const encoded = '("foo";a;b=1936 bar;y=:AQMBAg==:);d=18.71';
      final value = StructuredFieldInnerList(
        [
          StructuredFieldItem(
            StructuredFieldItemValue('foo'),
            parameters: StructuredFieldParameters({
              Key('a'): StructuredFieldItemValue(true),
              Key('b'): StructuredFieldItemValue(1936),
            }),
          ),
          StructuredFieldItem(
            StructuredFieldItemValue.token('bar'),
            parameters: StructuredFieldParameters({
              Key('y'):
                  StructuredFieldItemValue(Uint8List.fromList([1, 3, 1, 2])),
            }),
          ),
        ],
        parameters: StructuredFieldParameters({
          Key('d'): StructuredFieldItemValue(18.71),
        }),
      );
      expect(StructuredFieldInnerList.decode(encoded), value);
      expect(value.encode(), encoded);
    });
  });
}
