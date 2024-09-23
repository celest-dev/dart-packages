import 'dart:convert';

import 'package:http_sfv/src/item_value.dart';
import 'package:test/test.dart';

typedef _ValidBinaryTest = (
  String encoded,
  StructuredFieldItemValueBinary value,
);

final List<_ValidBinaryTest> _valid = [
  (':YWJj:', StructuredFieldItemValueBinary(utf8.encode('abc'))),
  (
    ':YW55IGNhcm5hbCBwbGVhc3VyZQ==:',
    StructuredFieldItemValueBinary(utf8.encode('any carnal pleasure')),
  ),
  (
    ':YW55IGNhcm5hbCBwbGVhc3Vy:',
    StructuredFieldItemValueBinary(utf8.encode('any carnal pleasur')),
  ),
];

const List<String> _invalid = [
  '',
  ':',
  ':YW55IGNhcm5hbCBwbGVhc3Vy',
  ':YW55IGNhcm5hbCBwbGVhc3Vy~',
  ':YW55IGNhcm5hbCBwbGVhc3VyZQ=:',
];

void main() {
  group('ByteSequence', () {
    for (final (encoded, value) in _valid) {
      test('isValid: "$encoded"', () {
        expect(StructuredFieldItemValueBinary.decode(encoded), value);
        expect(value.encode(), encoded);
      });
    }

    for (final encoded in _invalid) {
      test('isInvalid: "$encoded"', () {
        expect(
          () => StructuredFieldItemValueBinary.decode(encoded),
          throwsFormatException,
        );
      });
    }
  });
}
