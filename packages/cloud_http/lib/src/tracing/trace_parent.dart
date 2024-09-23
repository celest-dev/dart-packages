// ignore: implementation_imports
import 'package:http_sfv/src/character.dart';

/// {@template cloud_http.traceparent}
/// The parsed value of the `traceparent` header as defined in the W3C Trace Context specification.
///
/// See: https://www.w3.org/TR/trace-context/#traceparent-header
/// {@endtemplate}
final class Traceparent {
  /// {@macro cloud_http.traceparent}
  const Traceparent({
    required this.traceId,
    required this.parentId,
    required this.traceFlags,
    required this.version,
    this.unknownFields,
  });

  /// Creates a [Traceparent] for the given request-scoped [traceId] and
  /// [parentId].
  factory Traceparent.create({
    required String traceId,
    required String parentId,
    bool sampled = true,
    bool random = false,
  }) {
    return Traceparent(
      traceId: traceId,
      parentId: parentId,
      traceFlags:
          (sampled ? _traceFlagSampled : 0) | (random ? _traceFlagRandom : 0),
      version: defaultVersion,
    );
  }

  /// Parses the [traceparent] header.
  ///
  /// Throws a [FormatException] for invalid header formats. Use [tryParse] to
  /// discard parsing errors.
  ///
  /// {@template cloud_http.traceparent.format}
  /// ## Format
  ///
  ///     version-traceId-parentId-traceFlags
  ///
  /// where:
  /// - `version` is a single byte (8-bit unsigned integer) that represents the
  ///    version of the traceparent.
  /// - `traceId` is a 16-byte array that represents the ID of the whole trace
  ///    forest.
  /// - `parentId` is an 8-byte array that represents the ID of this request as
  ///    known by the caller.
  /// - `traceFlags` is an 8-bit field that controls tracing flags such as
  ///    sampling, trace level, etc.
  /// {@endtemplate}
  factory Traceparent.parse(String traceparent) {
    // If the size of the header is shorter than 55 characters, the vendor
    // should not parse the header and should restart the trace.
    if (traceparent.length < 55) {
      throw FormatException(
        'Invalid traceparent header. Unexpected length: '
        '${traceparent.length} < 55',
        traceparent,
      );
    }

    final codeUnits = traceparent.codeUnits as List<Character>;

    final versionPart = traceparent.substring(0, 2);
    final version = int.tryParse(versionPart, radix: 16);
    if (version == null) {
      throw FormatException(
        'Invalid traceparent version: $version',
        traceparent,
        0,
      );
    }
    const invalidVersion = 0xff;
    if (version == invalidVersion) {
      throw FormatException(
        'Invalid traceparent version: $version',
        traceparent,
        0,
      );
    }
    if (version != defaultVersion) {
      // OK. If a higher version is detected, the implementation SHOULD try to
      // parse it.
    }

    var offset = 2;
    if (codeUnits[offset++] != Character.dash) {
      throw FormatException(
        'Invalid traceparent header. Expected dash at offset 2',
        traceparent,
        2,
      );
    }

    const traceIdLength = 32;
    final traceId = traceparent.substring(offset, offset + traceIdLength);
    final traceIdCodeUnits = traceId.codeUnits as List<Character>;
    if (traceIdCodeUnits.every((char) => char == Character.zero)) {
      throw FormatException(
        'Invalid traceparent traceId: $traceId',
        traceparent,
        offset,
      );
    }
    for (final traceIdChar in traceIdCodeUnits) {
      if (!traceIdChar.isValidHex) {
        throw FormatException(
          'Invalid traceparent traceId: $traceId',
          traceparent,
          offset,
        );
      }
    }

    offset += traceIdLength;
    if (codeUnits[offset++] != Character.dash) {
      throw FormatException(
        'Invalid traceparent header. Expected dash at offset 34',
        traceparent,
        34,
      );
    }

    const parentIdLength = 16;
    final parentId = traceparent.substring(offset, offset + parentIdLength);
    final parentIdCodeUnits = parentId.codeUnits as List<Character>;
    if (parentIdCodeUnits.every((char) => char == Character.zero)) {
      throw FormatException(
        'Invalid traceparent parentId: $parentId',
        traceparent,
        offset,
      );
    }
    for (final parentIdChar in parentIdCodeUnits) {
      if (!parentIdChar.isValidHex) {
        throw FormatException(
          'Invalid traceparent parentId: $parentId',
          traceparent,
          offset,
        );
      }
    }

    offset += parentIdLength;
    if (codeUnits[offset++] != Character.dash) {
      throw FormatException(
        'Invalid traceparent header. Expected dash at offset 50',
        traceparent,
        50,
      );
    }

    final traceFlagsPart = traceparent.substring(offset, offset + 2);
    final traceFlags = int.tryParse(traceFlagsPart, radix: 16);
    if (traceFlags == null) {
      throw FormatException(
        'Invalid traceparent traceFlags: $traceFlags',
        traceparent,
        offset,
      );
    }

    offset += 2;

    String? unknownFields;
    // Vendors MUST check that the 2 characters are either the end of the string
    // or a dash.
    if (offset == traceparent.length) {
      // OK
    } else if (version == defaultVersion) {
      // Invalid for current spec
      throw FormatException(
        'Invalid traceparent header. Unexpected length: '
        '${traceparent.length} > 55',
        traceparent,
        offset,
      );
    } else {
      if (codeUnits[offset++] != Character.dash) {
        throw FormatException(
          'Invalid traceparent header. Expected dash at offset 52',
          traceparent,
          52,
        );
      }
      unknownFields = traceparent.substring(offset);
    }

    return Traceparent(
      version: version,
      traceId: traceId,
      parentId: parentId,
      traceFlags: traceFlags,
      unknownFields: unknownFields,
    );
  }

  /// Tries to parse the [traceparent] header.
  ///
  /// {@macro cloud_http.traceparent.format}
  static Traceparent? tryParse(String traceparent) {
    try {
      return Traceparent.parse(traceparent);
    } on FormatException {
      return null;
    }
  }

  static const int defaultVersion = 0x00; // 0 is the only defined version

  /// Version (version) is 1 byte representing an 8-bit unsigned integer.
  ///
  /// Version `ff` is invalid. The current specification assumes the version
  /// is set to `00`.
  final int version;

  /// This is the ID of the whole trace forest and is used to uniquely identify
  /// a distributed trace through a system.
  ///
  /// It is represented as a 16-byte array, for example,
  /// `4bf92f3577b34da6a3ce929d0e0e4736`.
  final String traceId;

  /// This is the ID of this request as known by the caller.
  ///
  /// In some tracing systems, this is known as the `span-id`, where a `span`
  /// is the execution of a client request.
  ///
  /// It is represented as an 8-byte array, for example, `00f067aa0ba902b7`.
  final String parentId;

  /// An 8-bit field that controls tracing flags such as sampling, trace level,
  /// etc.
  final int traceFlags;

  static const int _traceFlagSampled = 1 << 0;
  static const int _traceFlagRandom = 1 << 1;

  /// When set, the least significant bit (right-most), denotes that the caller
  /// may have recorded trace data.
  ///
  /// When unset, the caller did not record trace data out-of-band.
  int get traceFlagSampled => traceFlags & _traceFlagSampled;

  /// Level 2
  ///
  /// When set, the second least significant bit (right-most), denotes that the
  /// right-most 7 bytes of the [traceId] are randomly (or pseudo-randomly)
  /// generated.
  ///
  /// See: https://www.w3.org/TR/trace-context-2/#random-trace-id-flag
  int get traceFlagRandom => traceFlags & _traceFlagRandom;

  /// Unparsed fields which trail the header.
  final String? unknownFields;

  Traceparent copyWith({
    String? traceId,
    String? parentId,
    bool? sampled,
    bool? random,
  }) {
    return Traceparent(
      version: version,
      traceId: traceId ?? this.traceId,
      parentId: parentId ?? this.parentId,
      traceFlags: traceFlags |
          (sampled == true ? _traceFlagSampled : 0) |
          (random == true ? _traceFlagRandom : 0),
      unknownFields: unknownFields,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Traceparent &&
        other.version == version &&
        other.traceId == traceId &&
        other.parentId == parentId &&
        other.traceFlags == traceFlags &&
        other.unknownFields == unknownFields;
  }

  @override
  int get hashCode => Object.hash(
        version,
        traceId,
        parentId,
        traceFlags,
        unknownFields,
      );

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('00');
    buffer.writeCharCode(Character.dash);
    buffer.write(traceId);
    buffer.writeCharCode(Character.dash);
    buffer.write(parentId);
    buffer.writeCharCode(Character.dash);
    buffer.write(traceFlags.toRadixString(16).padLeft(2, '0'));
    if (unknownFields != null) {
      /// Vendors MUST NOT parse or assume anything about unknown fields for
      /// this version. Vendors MUST use these fields to construct the new
      /// traceparent field according to the highest version of the
      /// specification known to the implementation (in this specification it
      /// is `00`).
      buffer.writeCharCode(Character.dash);
      buffer.write(unknownFields);
    }
    return buffer.toString();
  }
}
