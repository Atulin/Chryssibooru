import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A Philomena-based booru the app can search.
///
/// Philomena instances come in two API generations: the classic
/// `Philomena V1` (`/api/v1/json/search/images`, payload key `images`) and
/// the newer `Philomena V3` (`/api/v3/search/posts`, payload key `posts`,
/// used by Twibooru). The style is chosen per source with a dropdown in
/// the sources screen.
enum PhilomenaApiStyle { v1, v3 }

class BooruSource {
  BooruSource({
    required this.id,
    required this.name,
    required this.host,
    this.apiKey = '',
    this.apiStyle = PhilomenaApiStyle.v1,
  });

  /// Stable identifier used for persisting the active selection.
  final String id;
  String name;
  String host;
  String apiKey;
  PhilomenaApiStyle apiStyle;

  /// The app's built-in source; it can be renamed/rekeyed but never
  /// removed.
  static const String defaultSourceId = 'derpibooru';

  factory BooruSource.defaultSource() => BooruSource(
    id: defaultSourceId,
    name: 'Derpibooru',
    host: 'derpibooru.org',
  );

  /// URL path of the search endpoint for this source's API generation.
  String get searchPath => apiStyle == PhilomenaApiStyle.v1
      ? '/api/v1/json/search/images'
      : '/api/v3/search/posts';

  /// Payload key of the search response for this source's API generation.
  String get resultKey => apiStyle == PhilomenaApiStyle.v1 ? 'images' : 'posts';

  BooruSource copyWith({
    String? name,
    String? host,
    String? apiKey,
    PhilomenaApiStyle? apiStyle,
  }) => BooruSource(
    id: id,
    name: name ?? this.name,
    host: host ?? this.host,
    apiKey: apiKey ?? this.apiKey,
    apiStyle: apiStyle ?? this.apiStyle,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'apiKey': apiKey,
    'apiStyle': apiStyle.name,
  };

  factory BooruSource.fromJson(Map<String, dynamic> json) => BooruSource(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    host: json['host'] as String? ?? 'derpibooru.org',
    apiKey: json['apiKey'] as String? ?? '',
    apiStyle: json['apiStyle'] == 'v3'
        ? PhilomenaApiStyle.v3
        : PhilomenaApiStyle.v1,
  );
}

/// Persistence for the configured sources and the active selection.
class SourcesStore {
  static const String _sourcesKey = 'sources';
  static const String _activeKey = 'activeSourceId';

  /// Loads the configured sources, creating the built-in default (and
  /// migrating the legacy single API key into it) when none are stored.
  static Future<List<BooruSource>> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_sourcesKey);
    if (raw == null) {
      final legacyKey = prefs.getString('key')?.trim() ?? '';
      final sources = [BooruSource.defaultSource()..apiKey = legacyKey];
      await save(prefs, sources);
      return sources;
    }
    try {
      final list = (jsonDecode(raw) as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BooruSource.fromJson)
          .toList();
      if (list.isEmpty ||
          !list.any((s) => s.id == BooruSource.defaultSourceId)) {
        list.insert(0, BooruSource.defaultSource());
        await save(prefs, list);
      }
      return list;
    } catch (_) {
      return [BooruSource.defaultSource()];
    }
  }

  static Future<void> save(
    SharedPreferences prefs,
    List<BooruSource> sources,
  ) async {
    await prefs.setString(
      _sourcesKey,
      jsonEncode(sources.map((s) => s.toJson()).toList()),
    );
    // Keep the legacy single-key preference in sync with the built-in
    // source for continuity.
    final builtIn = sources
        .where((s) => s.id == BooruSource.defaultSourceId)
        .map((s) => s.apiKey)
        .firstOrNull;
    if (builtIn != null) {
      await prefs.setString('key', builtIn);
    }
  }

  static Future<String> loadActiveId(SharedPreferences prefs) async {
    return prefs.getString(_activeKey) ?? BooruSource.defaultSourceId;
  }

  static Future<void> saveActiveId(SharedPreferences prefs, String id) async {
    await prefs.setString(_activeKey, id);
  }
}
