import 'package:http_sfv/http_sfv.dart';

void main() {
  final dictionary = StructuredFieldDictionary({
    'a': false,
    'b': true,
    'c': StructuredFieldItem(
      true,
      parameters: {
        'foo': 'bar',
      },
    ),
  });
  print('dictionary: ${dictionary.encode()}');
  // Prints: "a=?0, b, c;foo=bar"

  const header = '"foo";bar;baz=tok, (foo bar);bat';
  final decoded = StructuredFieldValue.decode(
    header,
    type: StructuredFieldValueType.list,
  );
  print('list: $decoded');
  // Prints: List(Item(foo, bar: true, baz: tok), InnerList([Item(foo), Item(bar)], bat: true))

  final list = StructuredFieldList([
    StructuredFieldItem(
      'foo',
      parameters: {
        'bar': true,
        'baz': Token('tok'),
      },
    ),
    StructuredFieldInnerList(
      [Token('foo'), Token('bar')],
      parameters: {
        'bat': true,
      },
    ),
  ]);
  print(decoded == list);
  // Prints: true
}
