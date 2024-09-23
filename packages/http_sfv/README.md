# http_sfv (Structured Field Values)

A Dart implementation of the [Structured Field Values for HTTP (RFC 8941)](https://www.rfc-editor.org/rfc/rfc8941.html) specification.

## Usage

Use `StructuredFieldValue.decode` to parse a header string into a structured field value.

```dart
import 'package:http_sfv/http_sfv.dart';

void main() {
  const header = '"foo";bar;baz=tok, (foo bar);bat';
  final decoded = StructuredFieldValue.decode(
    header,
    type: StructuredFieldValueType.list,
  );
  print(decoded);
  // Prints: List(Item(foo, bar: true, baz: tok), InnerList([Item(foo), Item(bar)], bat: true))
}
```

Use `StructuredFieldValue.encode` to convert a structured field value to a header string.

```dart
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
  print(dictionary.encode()); 
  // Prints: "a=?0, b, c;foo=bar"
}
```
