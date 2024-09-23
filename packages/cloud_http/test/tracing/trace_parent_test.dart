import 'package:cloud_http/src/tracing/trace_parent.dart';
import 'package:test/test.dart';

typedef TraceparentTest = (
  String name,
  bool valid,
  String header,
  Traceparent? expected,
);

final traceparentTests = <TraceparentTest>[
  (
    'sampled',
    true,
    '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
    Traceparent(
      traceId: '0af7651916cd43dd8448eb211c80319c',
      parentId: 'b7ad6b7169203331',
      traceFlags: 0x01,
      version: 0x00,
    ),
  ),
  (
    'unsampled',
    true,
    '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00',
    Traceparent(
      traceId: '0af7651916cd43dd8448eb211c80319c',
      parentId: 'b7ad6b7169203331',
      traceFlags: 0x00,
      version: 0x00,
    ),
  ),
  (
    'invalid version (0xff)',
    false,
    'ff-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00',
    null,
  ),
  (
    'invalid trace ID',
    false,
    '00-${'0' * 32}-b7ad6b7169203331-00',
    null,
  ),
  (
    'invalid parent ID',
    false,
    '00-0af7651916cd43dd8448eb211c80319c-${'0' * 16}-00',
    null,
  ),
  (
    'unknown version',
    true,
    '01-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00',
    Traceparent(
      traceId: '0af7651916cd43dd8448eb211c80319c',
      parentId: 'b7ad6b7169203331',
      traceFlags: 0x00,
      version: 0x01,
    ),
  ),
  (
    'unknown fields',
    false,
    '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00-unknown',
    null,
  ),
  (
    'unknown fields (unknown version)',
    true,
    '01-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00-unknown',
    Traceparent(
      traceId: '0af7651916cd43dd8448eb211c80319c',
      parentId: 'b7ad6b7169203331',
      traceFlags: 0x00,
      version: 0x01,
      unknownFields: 'unknown',
    ),
  )
];

void main() {
  group('Traceparent', () {
    group('parse', () {
      for (final testCase in traceparentTests) {
        final (name, valid, header, expected) = testCase;
        test(name, () {
          if (valid) {
            final traceparent = Traceparent.tryParse(header);
            expect(traceparent, expected);
            expect(
              traceparent.toString(),
              '00-${header.substring(3)}',
              reason: 'toString() always uses the default version',
            );
          } else {
            expect(Traceparent.tryParse(header), isNull);
          }
        });
      }
    });
  });
}
