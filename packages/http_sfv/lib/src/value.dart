import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http_sfv/http_sfv.dart';
import 'package:http_sfv/src/character.dart';
import 'package:http_sfv/src/parser.dart';
import 'package:meta/meta.dart';

enum StructuredFieldValueType { item, list, dictionary }

@immutable
sealed class StructuredFieldValue {
  factory StructuredFieldValue.decode(
    String value, {
    required StructuredFieldValueType type,
  }) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseValue(type);
  }

  String encode([StringBuffer? builder]);
}

/// A marker interface for members of dictionaries and lists, e.g. values
/// of type [StructuredFieldItem] or [StructuredFieldInnerList].
sealed class StructuredFieldMember implements StructuredFieldValue {
  factory StructuredFieldMember(Object value) {
    return switch (value) {
      StructuredFieldMember() => value,
      List<Object>() => StructuredFieldInnerList(value),
      List() => StructuredFieldInnerList(value.cast()),
      _ => StructuredFieldItem(value),
    };
  }
}

/// {@template http_sfv.structured_field_list}
/// A list of zero or more [StructuredFieldMember], each of which can be a
/// [StructuredFieldItem] or [StructuredFieldInnerList].
///
/// https://www.rfc-editor.org/rfc/rfc8941.html#name-lists
/// {@endtemplate}
final class StructuredFieldList extends DelegatingList<StructuredFieldMember>
    implements StructuredFieldMember {
  /// {@macro http_sfv.structured_field_list}
  factory StructuredFieldList(List<Object> items) {
    if (items is StructuredFieldList) {
      return items;
    }
    return StructuredFieldList._(
      items.map(StructuredFieldMember.new).toList(),
    );
  }

  StructuredFieldList._(super.base);

  factory StructuredFieldList.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseValue(StructuredFieldValueType.list)
        as StructuredFieldList;
  }

  @override
  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    for (var i = 0; i < length; i++) {
      final member = this[i];
      member.encode(builder);
      if (i != length - 1) {
        builder.write(', ');
      }
    }
    return builder.toString().substring(start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StructuredFieldList) {
      return false;
    }
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(this);

  @override
  String toString() => 'List(${join(', ')})';
}

/// {@template http_sfv.structured_field_dictionary}
/// An ordered map of zero or more key-value pairs, where the keys are short
/// textual strings and the values are [StructuredFieldItem]s or arrays of
/// [StructuredFieldItem]s, e.g. [StructuredFieldInnerList].
///
/// https://www.rfc-editor.org/rfc/rfc8941.html#name-dictionaries
/// {@endtemplate}
final class StructuredFieldDictionary
    with MapBase<String, StructuredFieldMember>
    implements StructuredFieldMember {
  /// {@macro http_sfv.structured_field_dictionary}
  factory StructuredFieldDictionary([
    Map<String, Object>? dictionary,
  ]) {
    if (dictionary is StructuredFieldDictionary) {
      return dictionary;
    }
    final map = dictionary?.map(
      (key, value) => MapEntry(
        Key(key),
        StructuredFieldMember(value),
      ),
    );
    return StructuredFieldDictionary._(map ?? {});
  }

  /// Decodes [value] as a dictionary.
  factory StructuredFieldDictionary.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseValue(StructuredFieldValueType.dictionary)
        as StructuredFieldDictionary;
  }

  StructuredFieldDictionary._(this._map);

  final Map<Key, StructuredFieldMember> _map;

  @override
  StructuredFieldMember? operator [](Object? key) {
    if (key is! String) {
      throw ArgumentError.value(key, 'key', 'must be a String');
    }
    return _map[key as Key];
  }

  @override
  void operator []=(String key, StructuredFieldMember value) {
    _map[Key(key)] = value;
  }

  @override
  void clear() => _map.clear();

  @override
  Iterable<Key> get keys => _map.keys;

  @override
  StructuredFieldMember? remove(Object? key) => _map.remove(key);

  @override
  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();

    var i = 0;
    for (final key in keys) {
      key.encode(builder);

      final value = this[key]!;
      if (value case StructuredFieldItem(value: true)) {
        value.parameters.encode(builder);
      } else {
        builder.writeCharCode(Character.equals);
        value.encode(builder);
      }

      if (i != length - 1) {
        builder.write(', ');
      }
      i++;
    }

    return builder.toString().substring(start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StructuredFieldDictionary) {
      return false;
    }
    if (_map.length != other._map.length) {
      return false;
    }
    for (final key in _map.keys) {
      if (_map[key] != other._map[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      const MapEquality<Key, StructuredFieldMember>().hash(_map);

  @override
  String toString() {
    final buf = StringBuffer('Dictionary(');
    buf.writeAll(entries.map((e) => '${e.key}: ${e.value}'), ', ');
    buf.write(')');
    return buf.toString();
  }
}

/// {@template http_sfv.structured_field_inner_list}
/// An array of zero or more [StructuredFieldItem]s.
///
/// Both the inner list and its [items] can be parameterized.
/// {@endtemplate}
final class StructuredFieldInnerList implements StructuredFieldMember {
  /// {@macro http_sfv.structured_field_inner_list}
  factory StructuredFieldInnerList(
    List<Object> items, {
    Map<String, Object>? parameters,
  }) {
    return StructuredFieldInnerList._(
      items.map(StructuredFieldItem.new).toList(),
      parameters: StructuredFieldParameters(parameters),
    );
  }

  StructuredFieldInnerList._(
    this.items, {
    required this.parameters,
  });

  /// Decodes [value] as an inner list.
  factory StructuredFieldInnerList.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseInnerList();
  }

  /// The items of the inner list.
  final List<StructuredFieldItem> items;

  /// The parameters of the inner list.
  final StructuredFieldParameters parameters;

  @override
  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    builder.writeCharCode(Character.openParen);
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      item.encode(builder);
      if (i != items.length - 1) {
        builder.writeCharCode(Character.space);
      }
    }
    builder.writeCharCode(Character.closeParen);
    parameters.encode(builder);
    return builder.toString().substring(start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StructuredFieldInnerList) {
      return false;
    }
    if (items.length != other.items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) {
        return false;
      }
    }
    return parameters == other.parameters;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (var i = 0; i < items.length; i++) {
      hash = Object.hash(hash, items[i]);
    }
    return Object.hash(hash, parameters);
  }

  @override
  String toString() {
    final buf = StringBuffer('InnerList(');
    buf
      ..write('[')
      ..write(items.join(', '))
      ..write(']');
    if (parameters.isNotEmpty) {
      buf
        ..write(', ')
        ..writeAll(parameters.entries.map((e) => '${e.key}: ${e.value}'), ', ');
    }
    buf.write(')');
    return buf.toString();
  }
}

/// {@template http_sfv.structured_field_item}
/// A parameterized [StructuredFieldItemValue].
///
/// Item values can be of type:
/// - [Token]
/// - [int]
/// - [double]
/// - [String]
/// - [Uint8List]
/// - [bool]
/// {@endtemplate}
final class StructuredFieldItem implements StructuredFieldMember {
  /// {@macro http_sfv.structured_field_item}
  factory StructuredFieldItem(
    Object value, {
    Map<String, Object>? parameters,
  }) {
    if (value is StructuredFieldItem) {
      return value;
    }
    return StructuredFieldItem._(
      StructuredFieldItemValue(value),
      parameters: StructuredFieldParameters(parameters),
    );
  }

  /// Decodes [value] as an item.
  factory StructuredFieldItem.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseValue(StructuredFieldValueType.item)
        as StructuredFieldItem;
  }

  StructuredFieldItem._(
    this.value, {
    required this.parameters,
  });

  /// The value of the item.
  final StructuredFieldItemValue value;

  /// The parameters of the item.
  final StructuredFieldParameters parameters;

  @override
  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    value.encode(builder);
    parameters.encode(builder);
    return builder.toString().substring(start);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredFieldItem &&
          value.equals(other.value) &&
          parameters == other.parameters;

  @override
  int get hashCode => Object.hash(value, parameters);

  @override
  String toString() {
    final buf = StringBuffer('Item(');
    buf.write(value);
    if (parameters.isNotEmpty) {
      buf
        ..write(', ')
        ..writeAll(parameters.entries.map((e) => '${e.key}: ${e.value}'), ', ');
    }
    buf.write(')');
    return buf.toString();
  }
}

/// {@template http_sfv.structured_field_parameters}
/// An ordered map of zero or more key-value pairs associated with a
/// [StructuredFieldItem].
/// {@endtemplate}
final class StructuredFieldParameters
    with MapBase<String, StructuredFieldItemValue>
    implements StructuredFieldValue {
  /// {@macro http_sfv.structured_field_parameters}
  factory StructuredFieldParameters([Map<String, Object>? parameters]) {
    if (parameters is StructuredFieldParameters) {
      return parameters;
    }
    final map = parameters?.map(
      (key, value) => MapEntry(
        Key(key),
        StructuredFieldItemValue(value),
      ),
    );
    return StructuredFieldParameters._(map ?? {});
  }

  /// Decodes [value] as parameters.
  factory StructuredFieldParameters.decode(String value) {
    final parser = StructuredFieldValueParser(value);
    return parser.parseParameters();
  }

  StructuredFieldParameters._(this._map);

  final Map<Key, StructuredFieldItemValue> _map;

  @override
  StructuredFieldItemValue? operator [](Object? key) {
    if (key is! String) {
      throw ArgumentError.value(key, 'key', 'must be a String');
    }
    return _map[key as Key];
  }

  @override
  void operator []=(String key, StructuredFieldItemValue value) {
    _map[Key(key)] = value;
  }

  @override
  void clear() => _map.clear();

  @override
  Iterable<Key> get keys => _map.keys;

  @override
  StructuredFieldItemValue? remove(Object? key) => _map.remove(key);

  @override
  String encode([StringBuffer? builder]) {
    final start = builder == null ? 0 : builder.length;
    builder ??= StringBuffer();
    for (final key in keys) {
      final item = this[key]!;
      builder.writeCharCode(Character.semiColon);
      key.encode(builder);
      if (item.value == true) {
        continue;
      }
      builder.writeCharCode(Character.equals);
      item.encode(builder);
    }
    return builder.toString().substring(start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StructuredFieldParameters) {
      return false;
    }
    if (_map.length != other._map.length) {
      return false;
    }
    for (final key in _map.keys) {
      if (!_map[key]!.equals(other._map[key]!)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      const MapEquality<Key, StructuredFieldItemValue>().hash(_map);

  @override
  String toString() {
    final buf = StringBuffer('Parameters(');
    buf.writeAll(entries.map((e) => '${e.key}: ${e.value}'), ', ');
    buf.write(')');
    return buf.toString();
  }
}
