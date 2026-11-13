// Construction of Philomena search queries and high-level search calls.
//
// The query shape follows the classic Philomena V1 API; the endpoint path
// and payload key come from the configured [BooruSource] so instances
// running the V3 API (e.g. Twibooru) work with the same code.

import 'dart:math';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/BooruSource.dart';
import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter/foundation.dart';

/// Default number of images requested per page when no API key is present.
const int defaultLimit = 30;

/// Builds the search URL for the given source and parameters.
///
/// Unless [s], [q], and [e] are all true (or all false) a rating clause
/// restricts the search, matching the behaviour of the original client.
/// The clause uses the shortest equivalent form: a single selected rating
/// becomes a plain tag (`safe`), and two selected ratings become a
/// negation of the missing one (`-safe` is equivalent to
/// `questionable OR explicit`). The explicit rating can only be selected
/// when an API [source] with an API key is present: the key unlocks the
/// user's account filter, which is what allows NSFW results to be served
/// at all. Without a key the result set is capped to [limit]; with a key
/// the server's per-page default applies.
String buildQuery(
  BooruSource source,
  String query, {
  bool s = true,
  bool q = false,
  bool e = false,
  int page = 1,
  int limit = defaultLimit,
  ESortMethod sortMethod = ESortMethod.ID_DESC,
}) {
  final sortData = sortMethod.sortData();
  final params = <String, String>{'q': query, 'page': page.toString()};

  final selected = [if (s) 'safe', if (q) 'questionable', if (e) 'explicit'];

  if (!(s && q && e) && !(!s && !q && !e)) {
    // One rating selected: request it directly. Two selected: exclude
    // the missing one, which is the shorter equivalent of an OR clause.
    final String clause;
    if (selected.length == 1) {
      clause = selected.single;
    } else {
      final missing = [
        'safe',
        'questionable',
        'explicit',
      ].where((r) => !selected.contains(r)).single;
      clause = '-$missing';
    }
    params['q'] = '$query, $clause';
  }

  final key = source.apiKey;
  if (key.isNotEmpty) {
    params['key'] = key;
  } else {
    params['per_page'] = limit.toString();
  }

  if (sortData.length > 1 && sortData[0].isNotEmpty) {
    params['sf'] = sortData[0];
    params['sd'] = sortData[1];
  }

  return Uri.https(source.host, source.searchPath, params).toString();
}

/// Fetches one page of search results. Returns `null` when the search
/// failed (network error, non-200 response) and an empty list when it
/// returned no images.
Future<List<Derpi>?> searchImages(
  BooruSource source,
  String query, {
  bool s = true,
  bool q = false,
  bool e = false,
  int page = 1,
  int limit = defaultLimit,
  ESortMethod sortMethod = ESortMethod.ID_DESC,
}) {
  final queryStr = buildQuery(
    source,
    query,
    s: s,
    q: q,
    e: e,
    page: page,
    limit: limit,
    sortMethod: sortMethod,
  );
  debugPrint('Searching: $queryStr');
  return fetchDerpi(queryStr, host: source.host);
}

/// Fetches a random image matching [query] from Derpibooru, used for the
/// drawer header. Returns `null` when the fetch fails; callers must fall
/// back to the static logo instead of crashing.
Future<Derpi?> getRandomImage(String query) async {
  final rnd = Random().nextInt(10000).toString();
  final url = Uri.https('derpibooru.org', '/api/v1/json/search/images', {
    'q': '$query, score.gt:10',
    'sf': 'random:$rnd',
    'sd': 'desc',
  }).toString();
  return fetchSingleDerpi(url, host: 'derpibooru.org');
}
