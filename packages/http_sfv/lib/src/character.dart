import 'package:http_sfv/http_sfv.dart';

/// An ASCII character.
extension type const Character(int char) implements int {
  static const Character space = Character(0x20); // ' '
  static const Character tab = Character(0x09); // '\t'
  static const Character doubleQuote = Character(0x22); // '"'
  static const Character questionMark = Character(0x3F); // '?'
  static const Character star = Character(0x2A); // '*'
  static const Character colon = Character(0x3A); // ':'
  static const Character zero = Character(0x30); // '0'
  static const Character one = Character(0x31); // '1'
  static const Character nine = Character(0x39); // '9'
  static const Character upperA = Character(0x41); // 'A'
  static const Character upperZ = Character(0x5A); // 'Z'
  static const Character lowerA = Character(0x61); // 'a'
  static const Character lowerZ = Character(0x7A); // 'z'
  static const Character exclamationMark = Character(0x21); // '!'
  static const Character numberSign = Character(0x23); // '#'
  static const Character dollarSign = Character(0x24); // '$'
  static const Character percent = Character(0x25); // '%'
  static const Character and = Character(0x26); // '&'
  static const Character singleQuote = Character(0x27); // '\''
  static const Character plus = Character(0x2B); // '+'
  static const Character minus = Character(0x2D); // '-'
  static const Character dash = minus; // '-'
  static const Character decimal = Character(0x2E); // '.'
  static const Character caret = Character(0x5E); // '^'
  static const Character underscore = Character(0x5F); // '_'
  static const Character backtick = Character(0x60); // '`'
  static const Character pipe = Character(0x7C); // '|'
  static const Character tilde = Character(0x7E); // '~'
  static const Character slash = Character(0x2F); // '/'
  static const Character backslash = Character(0x5C); // '\'
  static const Character semiColon = Character(0x3B); // ';'
  static const Character equals = Character(0x3D); // '='
  static const Character comma = Character(0x2C); // ','
  static const Character openParen = Character(0x28); // '('
  static const Character closeParen = Character(0x29); // ')'
  static const Character at = Character(0x40); // '@'
  static const Character maxAscii = Character(0x7F); // '\x7F'

  static const Character lowerAlphaA = Character(0x61); // 'a'
  static const Character lowerAlphaB = Character(0x62); // 'b'
  static const Character lowerAlphaC = Character(0x63); // 'c'
  static const Character lowerAlphaD = Character(0x64); // 'd'
  static const Character lowerAlphaE = Character(0x65); // 'e'
  static const Character lowerAlphaF = Character(0x66); // 'f'
  static const Character upperAlphaA = Character(0x41); // 'A'
  static const Character upperAlphaB = Character(0x42); // 'B'
  static const Character upperAlphaC = Character(0x43); // 'C'
  static const Character upperAlphaD = Character(0x44); // 'D'
  static const Character upperAlphaE = Character(0x45); // 'E'
  static const Character upperAlphaF = Character(0x46); // 'F'

  /// An alpha character, e.g. A-Z or a-z.
  bool get isAlpha =>
      this >= upperA && this <= upperZ || this >= lowerA && this <= lowerZ;

  /// A lowercase alpha character, e.g. a-z.
  bool get isLowerAlpha => this >= lowerA && this <= lowerZ;

  /// A digit character, e.g. 0-9.
  bool get isDigit => this >= zero && this <= nine;

  /// A valid hex character, e.g. 0-9, A-F, or a-f.
  bool get isValidHex =>
      isDigit ||
      this >= upperAlphaA && this <= upperAlphaF ||
      this >= lowerAlphaA && this <= lowerAlphaF;

  /// An optional whitespace character, e.g. ' ' or '\t'.
  bool get isOptionalWhitespace => this == space || this == tab;

  /// Whether this is a valid [Token] character.
  bool get isExtendedTokenCharacter {
    if (isAlpha || isDigit) {
      return true;
    }
    return this == exclamationMark ||
        this == numberSign ||
        this == dollarSign ||
        this == percent ||
        this == and ||
        this == singleQuote ||
        this == star ||
        this == plus ||
        this == minus ||
        this == decimal ||
        this == caret ||
        this == underscore ||
        this == backtick ||
        this == pipe ||
        this == tilde ||
        this == colon ||
        this == slash;
  }

  /// Whether this is a valid [Key] character.
  bool get isKeyCharacter {
    if (isLowerAlpha || isDigit) {
      return true;
    }
    return this == underscore ||
        this == minus ||
        this == decimal ||
        this == star;
  }

  /// A visible ASCII character (VCHAR), e.g. 0x21 (!) to 0x7E (~).
  ///
  /// See: https://www.rfc-editor.org/rfc/rfc5234#appendix-B.1
  bool get isVisibleAscii => this >= exclamationMark && this < maxAscii;

  /// An ASCII character which is not a VCHAR or SP.
  bool get isInvalidAscii => !isVisibleAscii && this != space;

  /// Whether this is a valid base64 character.
  bool get isValidBase64 =>
      isAlpha || isDigit || this == plus || this == slash || this == equals;
}
