/// Languages the apps know about. The rules and the backend accept the same codes.
const List<String> kSupportedLanguages = [
  'en',
  'hi',
  'bn',
  'ta',
  'te',
  'mr',
  'gu',
  'kn',
  'ml',
  'pa'
];

/// Languages offered in the MVP UI.
const Map<String, String> kLanguageLabels = {'en': 'English', 'hi': 'हिन्दी'};

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    // Firestore Timestamp exposes toDate(); avoids importing Firestore in pure models.
    return (v as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

int asInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

class LocalizedText {
  const LocalizedText(this.values);

  final Map<String, String> values;

  factory LocalizedText.fromMap(dynamic raw) {
    final out = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is String && v.isNotEmpty) out[k] = v;
      });
    }
    return LocalizedText(out);
  }

  /// Requested language, else English, else any available value, else empty text.
  String resolve(String language) {
    return values[language] ??
        values['en'] ??
        (values.isNotEmpty ? values.values.first : '');
  }

  bool has(String language) => values.containsKey(language);

  Map<String, String> toMap() => Map<String, String>.of(values);
}
