import 'package:cloud_http/src/tracing/trace_state.dart';
// ignore: implementation_imports
import 'package:http_sfv/src/character.dart';
import 'package:test/test.dart';

typedef TracestateTest = (
  String name,
  bool valid,
  String header,
  Tracestate? expected,
  String? expectedString,
);

final tracestateTests = <TracestateTest>[
  (
    'single key',
    true,
    'key=value',
    Tracestate.from({'key': 'value'}),
    null,
  ),
  (
    'multi key',
    true,
    'key1=value1,key2=value2',
    Tracestate.from({'key1': 'value1', 'key2': 'value2'}),
    null,
  ),
  (
    'multi tenant key',
    true,
    'tenant1@system1=value1,tenant2@system2=value2',
    Tracestate.from({
      'tenant1@system1': 'value1',
      'tenant2@system2': 'value2',
    }),
    null,
  ),
  (
    // 3.3.2.2.2: All leading spaces MUST be preserved as part of the value.
    'leading value whitespace is preserved',
    true,
    'key=  value',
    Tracestate.from({'key': '  value'}),
    null,
  ),
  (
    'trailing value whitespace is ignored',
    true,
    'key=value ',
    Tracestate.from({'key': 'value'}),
    'key=value',
  ),
  (
    'optional whitespace is ignored',
    true,
    'key=value  ,  key2=value2,  key3=value3  ',
    Tracestate.from({
      'key': 'value',
      'key2': 'value2',
      'key3': 'value3',
    }),
    'key=value,key2=value2,key3=value3',
  ),
  (
    'invalid key/value pair',
    false,
    'key',
    null,
    null,
  ),
  (
    'empty value',
    false,
    'key=',
    null,
    null,
  ),
  (
    'empty value: only whitespace',
    false,
    'key=  ',
    null,
    null,
  ),
  (
    'valid whitespace within value',
    true,
    'key=va  lue',
    Tracestate.from({'key': 'va  lue'}),
    null,
  ),
  for (var i = 0; i < Character.maxAscii; i++)
    if (Character(i).isValidTracestateValueChar)
      (
        'valid value char: 0x${i.toRadixString(16).padLeft(2, '0')}',
        true,
        'key=${String.fromCharCode(i)}',
        Tracestate.from({'key': String.fromCharCode(i)}),
        null,
      )
    else
      (
        'invalid value char: 0x${i.toRadixString(16).padLeft(2, '0')}',
        false,
        'key=${String.fromCharCode(i)}',
        null,
        null,
      ),
  (
    'value at length',
    false,
    'key=${'a' * 256}',
    null,
    null,
  ),
  (
    'value too long',
    false,
    'key=${'a' * 257}',
    null,
    null,
  ),
  (
    'too many values',
    false,
    [
      for (var i = 0; i < 33; i++) 'key$i=value$i',
    ].join(','),
    null,
    null,
  ),
  (
    'takes second value for dup keys',
    true,
    'key=value1,key=value2',
    Tracestate.from({'key': 'value2'}),
    'key=value2',
  ),
  (
    'invalid multi tenant key',
    false,
    'tenant1@system1',
    null,
    null,
  ),
  (
    'invalid multi tenant value',
    false,
    'tenant1@system1=',
    null,
    null,
  ),
];

void main() {
  group('Tracestate', () {
    group('parse', () {
      for (final testCase in tracestateTests) {
        final (name, valid, header, expected, expectedToString) = testCase;

        test(name, () {
          try {
            final tracestate = Tracestate.parse(header);
            if (!valid) {
              fail('Expected exception');
            }
            expect(tracestate, expected);
            expect(tracestate.toString(), expectedToString ?? header);
          } on Object catch (e, st) {
            if (valid) {
              fail('Unexpected exception: $e\n$st');
            }
          }
        });
      }
    });
  });
}
