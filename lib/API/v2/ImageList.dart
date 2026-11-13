// Construction of Derpibooru search queries and high-level search calls.

import 'dart:math';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter/foundation.dart';

const String _apiUrl = 'derpibooru.org';
const String _apiPath = '/api/v1/json/search/images';

/// Default number of images requested per page when no API key is present.
const int defaultLimit = 30;

/// Builds the search URL for the given parameters.
///
/// Unless [s], [q], and [e] are all true (or all false) a rating clause
/// restricts the search, matching the behaviour of the original client.
/// The clause uses the shortest equivalent form: a single selected rating
/// becomes a plain tag (`safe`), and two selected ratings become a
/// negation of the missing one (`-safe` is equivalent to
/// `questionable OR explicit`). The explicit rating can only be selected
/// when an API [key] is present: the key unlocks the user's account
/// filter, which is what allows NSFW results to be served at all.
/// Without a key the result set is capped to [limit]; with a key the
/// server's per-page default applies.
String buildQuery(
  String query,
  bool s,
  bool q,
  bool e,
  String key, {
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

  if (key.isNotEmpty) {
    params['key'] = key;
  } else {
    params['per_page'] = limit.toString();
  }

  if (sortData.length > 1 && sortData[0].isNotEmpty) {
    params['sf'] = sortData[0];
    params['sd'] = sortData[1];
  }

  return Uri.https(_apiUrl, _apiPath, params).toString();
}

/// Fetches one page of search results. Returns `null` when the search
/// failed (network error, non-200 response) and an empty list when it
/// returned no images.
Future<List<Derpi>?> searchImages(
  String query,
  bool s,
  bool q,
  bool e,
  String key, {
  int page = 1,
  int limit = defaultLimit,
  ESortMethod sortMethod = ESortMethod.ID_DESC,
}) {
  final queryStr = buildQuery(
    query,
    s,
    q,
    e,
    key,
    page: page,
    limit: limit,
    sortMethod: sortMethod,
  );
  debugPrint('Searching: $queryStr');
  return fetchDerpi(queryStr);
}

/// Fetches a random image matching [query], used for the drawer header.
/// Returns `null` when the fetch fails; callers must fall back to the
/// static logo instead of crashing.
Future<Derpi?> getRandomImage(String query) async {
  final rnd = Random().nextInt(10000).toString();
  final url = Uri.https(_apiUrl, _apiPath, {
    'q': '$query, score.gt:10',
    'sf': 'random:$rnd',
    'sd': 'desc',
  }).toString();
  return fetchSingleDerpi(url);
}
