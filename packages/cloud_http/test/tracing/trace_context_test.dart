import 'package:cloud_http/src/tracing/trace_context.dart';
import 'package:cloud_http/src/tracing/trace_state.dart';
import 'package:test/test.dart';

void main() {
  group('TraceContext', () {
    group('fromHeaders', () {
      test('missing traceparent, missing tracestate', () {
        final context = TraceContext.fromHeaders({});
        expect(context.traceparent, isNull);
        expect(context.tracestate, isNull);
      });

      test('missing traceparent, invalid tracestate', () {
        final context = TraceContext.fromHeaders({
          'tracestate': 'invalid',
        });
        expect(context.traceparent, isNull);
        expect(context.tracestate, isNull);
      });

      test('invalid traceparent, missing tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent': 'invalid',
        });
        expect(context.traceparent, isNull);
        expect(context.tracestate, isNull);
      });

      test('invalid traceparent, invalid tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent': 'invalid',
          'tracestate': 'invalid',
        });
        expect(context.traceparent, isNull);
        expect(context.tracestate, isNull);
      });

      test('valid traceparent, missing tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
        });
        expect(context.traceparent, isNotNull);
        expect(context.tracestate, isNull);
      });

      test('valid traceparent, invalid tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': 'invalid',
        });
        expect(context.traceparent, isNotNull);
        expect(context.tracestate, isNull);
      });

      test('valid traceparent, valid tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': 'key=value',
        });
        expect(context.traceparent, isNotNull);
        expect(context.tracestate, isNotNull);
      });

      test('valid traceparent, valid tracestate (multiple values)', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': ['key=value', 'key2=value2'],
        });
        expect(context.traceparent, isNotNull);
        expect(
          context.tracestate,
          Tracestate.from({
            'key': 'value',
            'key2': 'value2',
          }),
        );
      });

      test('valid traceparent, valid tracestate (list)', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': ['key=value'],
        });
        expect(context.traceparent, isNotNull);
        expect(
          context.tracestate,
          Tracestate.from({
            'key': 'value',
          }),
        );
      });

      test('valid traceparent, valid tracestate (invalid key)', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': 'key',
        });
        expect(context.traceparent, isNotNull);
        expect(context.tracestate, isNull);
      });

      test('valid traceparent, valid tracestate (invalid value)', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': 'key= ',
        });
        expect(context.traceparent, isNotNull);
        expect(context.tracestate, isNull);
      });

      test('invalid traceparent, valid tracestate', () {
        final context = TraceContext.fromHeaders({
          'traceparent':
              'ff-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
          'tracestate': 'key=value',
        });
        expect(context.traceparent, isNull);
        expect(context.tracestate, isNull);
      });
    });
  });
}
