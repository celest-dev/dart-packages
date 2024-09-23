import 'dart:math';

import 'package:cloud_http/cloud_http.dart';
import 'package:convert/convert.dart';
import 'package:shelf/shelf.dart' as shelf;

/// A trace context [shelf.Middleware] which conforms to the W3C Trace Context
/// specification.
///
/// See: https://w3c.github.io/trace-context/
shelf.Middleware tracingMiddleware({
  Random? random,
}) {
  random ??= Random.secure();
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) {
      var traceContext = TraceContext.fromHeaders(request.headers);
      var traceparent = traceContext.traceparent;

      if (traceparent == null) {
        // A vendor receiving a request without a traceparent header SHOULD
        // generate traceparent headers for outbound requests, effectively
        // starting a new trace.
        traceparent = Traceparent.create(
          traceId: hex.encode(
            List<int>.generate(16, (_) => random!.nextInt(256)),
          ),
          parentId: hex.encode(
            List<int>.generate(8, (_) => random!.nextInt(256)),
          ),
          sampled: true,
          random: true,
        );
      } else {
        // https://www.w3.org/TR/trace-context-2/#a-traceparent-is-received
        //
        // The vendor MUST modify the traceparent header:
        // - Update parent-id: The value of property parent-id MUST be set to a
        //   value representing the ID of the current operation.
        // - Update sampled: The value of sampled reflects the caller's
        //   recording behavior. The value of the sampled flag of trace-flags
        //   MAY be set to 1 if the trace data is likely to be recorded or to 0
        //   otherwise. Setting the flag is no guarantee that the trace will be
        //   recorded but increases the likeliness of end-to-end recorded traces.
        traceparent = traceparent.copyWith(
          parentId: hex.encode(
            List<int>.generate(8, (_) => random!.nextInt(256)),
          ),
          sampled: true,
        );
      }

      traceContext = TraceContext(
        traceparent: traceparent,
        tracestate: traceContext.tracestate,
      );

      return innerHandler(
        request.change(headers: {
          ...request.headers,
          ...traceContext.toHeaders(),
        }),
      );
    };
  };
}
