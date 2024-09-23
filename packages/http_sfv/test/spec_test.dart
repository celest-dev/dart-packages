import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:http_sfv/http_sfv.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final testDir = Directory.current.uri.resolve(
    'structured-field-tests/',
  );
  final testFiles = Directory.fromUri(testDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  // Only in draft spec:
  // https://www.ietf.org/archive/id/draft-ietf-httpbis-sfbis-04.html#name-display-strings
  const skipTests = [
    'date',
    'display-string',
  ];

  group('HTTP WG', () {
    for (final testFile in testFiles) {
      final testName = p.basenameWithoutExtension(testFile.path);
      if (skipTests.contains(testName)) {
        continue;
      }
      final contents = testFile.readAsStringSync();
      final json = jsonDecode(contents) as List;
      final testCases =
          json.cast<Map>().map((el) => _TestCase.fromJson(el.cast()));
      group(testName, () {
        for (final testCase in testCases) {
          test(testCase.name, () {
            try {
              final encoded = testCase.raw.join(',');
              final value = StructuredFieldValue.decode(
                encoded,
                type: testCase.headerType,
              );
              expect(value.toJson(), equals(testCase.expected));
            } on Object {
              if (testCase.mustFail || testCase.canFail) {
                return;
              }
              rethrow;
            }
          });
        }
      });
    }
  });
}

final class _TestCase {
  const _TestCase({
    required this.name,
    required this.raw,
    required this.headerType,
    this.expected,
    required this.mustFail,
    required this.canFail,
    this.canonical,
  });

  factory _TestCase.fromJson(Map<String, Object?> json) {
    switch (json) {
      case {
          'name': final String name,
          'raw': final List raw,
          'header_type': final String headerType,
        }:
        final mustFail = (json['must_fail'] as bool?) ?? false;
        return _TestCase(
          name: name,
          raw: raw.cast(),
          headerType: StructuredFieldValueType.values.byName(headerType),
          expected: mustFail ? null : json['expected']!,
          mustFail: mustFail,
          canFail: (json['can_fail'] as bool?) ?? false,
          canonical: (json['canonical'] as List?)?.cast(),
        );
      default:
        throw FormatException('Invalid test case: $json');
    }
  }

  final String name;
  final List<String> raw;
  final StructuredFieldValueType headerType;
  final Object? expected;
  final bool mustFail;
  final bool canFail;
  final List<String>? canonical;
}

extension on StructuredFieldValue {
  Object toJson() => switch (this) {
        final StructuredFieldList list => [
            for (final member in list) member.toJson(),
          ],
        final StructuredFieldDictionary dictionary => [
            for (final entry in dictionary.entries)
              [entry.key, entry.value.toJson()],
          ],
        final StructuredFieldInnerList innerList => [
            innerList.items.map((item) => item.toJson()).toList(),
            innerList.parameters.toJson(),
          ],
        final StructuredFieldItem item => [
            item.value.toJson(),
            item.parameters.toJson(),
          ],
        final StructuredFieldParameters parameters => [
            for (final entry in parameters.entries)
              [entry.key, entry.value.toJson()],
          ],
      };
}

extension on StructuredFieldItemValue {
  Object toJson() => switch (value) {
        final bool value => value,
        final String value => value,
        final int value => value,
        final double value => value,
        final Uint8List value => {
            '__type': 'binary',
            'value': base32.encode(value),
          },
        final Token token => {
            '__type': 'token',
            'value': token.toString(),
          },
        _ => throw FormatException(
            'Invalid bare item: $this ($runtimeType)',
          ),
      };
}
