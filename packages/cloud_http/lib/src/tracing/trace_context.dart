import 'package:cloud_http/src/tracing/trace_parent.dart';
import 'package:cloud_http/src/tracing/trace_state.dart';

/// The trace context for a request, as defined in the W3C Trace Context
/// [specification](https://www.w3.org/TR/trace-context-2).
final class TraceContext {
  const TraceContext({
    required Traceparent this.traceparent,
    this.tracestate,
  });

  const TraceContext._({
    this.traceparent,
    this.tracestate,
  });

  /// Parses the `traceparent` and `tracestate` headers from a request's
  /// [headers].
  ///
  /// If the `traceparent` header is missing or invalid, the returned context
  /// will have a
  ///
  /// If the `tracestate` header is missing or invalid, the returned context
  /// will have a `null` [tracestate].
  ///
  /// Assumes that [headers] is a case-insensitive [Map].
  factory TraceContext.fromHeaders(Map<String, Object>? headers) {
    final traceparentHeader = switch (headers?['traceparent']) {
      null => null,
      final String traceparent => traceparent,
      final List<String> traceparent => traceparent.singleOrNull,
      final invalid => throw FormatException(
          'Invalid traceparent header: $invalid. '
          'Expected String or List<String>, got ${invalid.runtimeType}.',
        ),
    };
    final traceparent = traceparentHeader != null
        ? Traceparent.tryParse(traceparentHeader)
        : null;
    // If the vendor failed to parse traceparent, it MUST NOT attempt to parse
    // tracestate. Note that the opposite is not true: failure to parse
    // tracestate MUST NOT affect the parsing of traceparent.
    Tracestate? tracestate;
    if (traceparent != null) {
      final tracestateHeader = switch (headers?['tracestate']) {
        null => null,
        final String tracestate => tracestate,
        // Multiple tracestate header fields MUST be handled as specified by
        // RFC9110 Section 5.3 Field Order.
        final List<String> tracestate => tracestate.join(', '),
        final invalid => throw FormatException(
            'Invalid tracestate header: $invalid. '
            'Expected String or List<String>, got ${invalid.runtimeType}.',
          ),
      };
      tracestate = tracestateHeader != null
          ? Tracestate.tryParse(tracestateHeader)
          : null;
    }
    return TraceContext._(
      traceparent: traceparent,
      tracestate: tracestate,
    );
  }

  final Traceparent? traceparent;
  final Tracestate? tracestate;

  Map<String, String> toHeaders() => {
        // In order to increase interoperability across multiple protocols and
        // encourage successful integration, tracing systems SHOULD encode the
        // header name as ASCII lowercase.
        if (traceparent != null) 'traceparent': traceparent.toString(),
        if (tracestate != null) 'tracestate': tracestate.toString(),
      };
}
