import 'package:meta/meta.dart';

/// {@template http_sfv.token}
/// Tokens are short, textual words which are identical to their serialized
/// value.
///
/// The distinction between a token and a string is similar to that of a
/// [Symbol] and [String] in Dart.
/// {@endtemplate}
@immutable
final class Token {
  /// {@macro http_sfv.token}
  const Token(this._value);

  final String _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Token && _value == other._value;

  @override
  int get hashCode => Object.hash(Token, _value);

  @override
  String toString() => _value;
}
