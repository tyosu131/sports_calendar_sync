/// Failure for one drifted production field.
///
/// Callers must not replace the field with an empty string, the current time,
/// or a guessed team, league, or status.
class FirestoreDecodeException implements Exception {
  const FirestoreDecodeException({
    required this.collection,
    required this.documentId,
    required this.field,
    required this.expected,
    required this.actual,
  });

  final String collection;
  final String documentId;
  final String field;
  final String expected;
  final Object? actual;

  @override
  String toString() {
    return 'Firestore decode failed: $collection/$documentId '
        'field "$field" expected $expected, got ${_actualLabel(actual)}';
  }
}

/// Marker so a missing key is not reported as the string "missing".
class MissingFirestoreValue {
  const MissingFirestoreValue();

  @override
  String toString() => 'missing';
}

const missingFirestoreValue = MissingFirestoreValue();

String _actualLabel(Object? actual) {
  if (actual is MissingFirestoreValue) return 'missing';
  if (actual == null) return 'null';
  // Runtime type only. The stored value can be an email, URL, or token.
  return actual.runtimeType.toString();
}

/// Reads one document. Invalid values throw [FirestoreDecodeException].
class FirestoreDecoder {
  const FirestoreDecoder({required this.collection, required this.documentId});

  final String collection;
  final String documentId;

  Never fail(String field, String expected, Object? actual) {
    throw FirestoreDecodeException(
      collection: collection,
      documentId: documentId,
      field: field,
      expected: expected,
      actual: actual,
    );
  }

  T require<T>(
    Map<String, dynamic> data,
    String field, {
    required String expected,
  }) {
    if (!data.containsKey(field)) {
      fail(field, expected, missingFirestoreValue);
    }
    final value = data[field];
    if (value is! T) fail(field, expected, value);
    return value;
  }

  /// Absent or null is allowed. A present value of the wrong type is not.
  T? optional<T>(
    Map<String, dynamic> data,
    String field, {
    required String expected,
  }) {
    if (!data.containsKey(field) || data[field] == null) return null;
    final value = data[field];
    if (value is! T) fail(field, expected, value);
    return value;
  }

  /// Missing or null becomes an empty list. A wrong type or element does not.
  List<String> stringList(Map<String, dynamic> data, String field) {
    if (!data.containsKey(field) || data[field] == null) return const [];
    final value = data[field];
    if (value is! List) fail(field, 'List<String>', value);
    final result = <String>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! String) fail('$field[$index]', 'String', item);
      result.add(item);
    }
    return List<String>.unmodifiable(result);
  }
}

/// `competitionKey` wins. Legacy `sportKey` is used only when the new field
/// is absent or null. A present value of the wrong type fails closed.
String? readLegacyCompetitionKey(
  FirestoreDecoder decoder,
  Map<String, dynamic> data,
) {
  if (data.containsKey('competitionKey') && data['competitionKey'] != null) {
    return decoder.require<String>(data, 'competitionKey', expected: 'String');
  }
  if (data.containsKey('sportKey') && data['sportKey'] != null) {
    return decoder.require<String>(data, 'sportKey', expected: 'String');
  }
  return null;
}
