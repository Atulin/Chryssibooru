import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/BooruSource.dart';
import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:material_ui/material_ui.dart';

/// Outcome of a [DerpisRepo.loadNextPage] call.
enum LoadResult {
  /// New images were appended.
  added,

  /// Skipped because another fetch is already running or a previous
  /// failure needs a retry trigger; not an error.
  busy,

  /// The search has no more results.
  ended,

  /// The request failed (network/server error); it can be retried.
  failed,

  /// A newer search superseded this request; results were discarded.
  stale,
}

/// Repository that handles all of the fetched [Derpi]s.
///
/// It guards against duplicate concurrent pagination requests, deduplicates
/// results by image id, and discards stale responses after a new search
/// (or filter/sort change) supersedes them.
class DerpisRepo extends ChangeNotifier {
  /// List of all stored [Derpi]s.
  List<Derpi> derpis = [];

  /// Whether the repository is idle, i.e. not currently loading a page.
  bool loaded = true;

  /// True once a page returned no further results; the repository stops
  /// issuing requests until the next fresh search.
  bool endOfResults = false;

  /// User's API key for the active source.
  String key = '';

  /// API host of the active source.
  String host = 'derpibooru.org';

  /// Search endpoint path of the active source's API generation.
  String searchPath = '/api/v1/json/search/images';

  /// Payload key of the active source's search responses.
  String resultKey = 'images';

  /// Image ratings to include.
  bool safe = true;
  bool questionable = false;
  bool explicit = false;

  /// Query to search for.
  String query = '';

  /// Sorting method based on [ESortMethod].
  ESortMethod sortMethod = ESortMethod.ID_DESC;

  /// Number of the page to be fetched.
  int page = 1;

  /// Incremented on every state change that can produce results; a page
  /// fetch that finishes after this has been bumped again is stale.
  int _requestToken = 0;

  /// Whether a page fetch is currently in flight.
  bool _isFetching = false;

  /// Loads the next page of results according to the query and filter
  /// parameters.
  ///
  /// Concurrent calls while a fetch is already running are reported as
  /// [LoadResult.busy] and perform no request.
  Future<LoadResult> loadNextPage() async {
    if (_isFetching) return LoadResult.busy;
    if (endOfResults) return LoadResult.ended;

    _isFetching = true;
    loaded = false;
    notifyListeners(); // Surface the loading state immediately.
    final token = ++_requestToken;
    final pageToFetch = page;

    final newImages = await searchImages(
      _sourceForQuery(),
      query,
      s: safe,
      q: questionable,
      e: explicit,
      page: pageToFetch,
      sortMethod: sortMethod,
    );

    if (token != _requestToken) {
      // A newer search superseded this request; discard the results and
      // leave all state to the newer request.
      return LoadResult.stale;
    }

    _isFetching = false;
    loaded = true;

    if (newImages == null) {
      // Network error or server error: the page can be retried on the
      // next scroll event, so end-of-results is not assumed.
      notifyListeners();
      return LoadResult.failed;
    }

    if (newImages.isNotEmpty) {
      final existing = derpis.map((d) => d.id).toSet();
      derpis.addAll(newImages.where((d) => !existing.contains(d.id)));
      notifyListeners();
      page++;
      return LoadResult.added;
    }

    endOfResults = true;
    notifyListeners();
    return LoadResult.ended;
  }

  /// Starts a fresh search from page 1, clearing the current results and
  /// discarding any in-flight page request. Returns the result of the
  /// initial page load.
  Future<LoadResult> newSearch() async {
    _requestToken++; // Invalidate in-flight page fetches.
    _isFetching = false;
    endOfResults = false;
    page = 1;
    derpis = [];
    notifyListeners();
    return loadNextPage();
  }

  /// Clears the current results and reloads page 1 for the existing
  /// query, ratings, and sorting. Used when tags are added or removed
  /// from the query.
  Future<LoadResult> restartSearch() => newSearch();

  /// A throwaway [BooruSource] view of the active source's connection
  /// fields, used by the query builder.
  BooruSource _sourceForQuery() => BooruSource(
    id: '',
    name: '',
    host: host,
    apiKey: key,
    apiStyle: resultKey == 'posts'
        ? PhilomenaApiStyle.v3
        : PhilomenaApiStyle.v1,
  );

  /// Get the built query as string (for debugging).
  String getQuery() => buildQuery(
    _sourceForQuery(),
    query,
    s: safe,
    q: questionable,
    e: explicit,
    page: page,
    sortMethod: sortMethod,
  );

  /// Set which ratings should be included.
  void setRatings(bool safe, bool questionable, bool explicit) {
    this.safe = safe;
    this.questionable = questionable;
    this.explicit = explicit;
  }

  /// Adds a [Tag] to the current query.
  void addTag(String tag) {
    final tagArr = query.split(', ');
    tagArr.add(tag);
    query = tagArr.join(', ');
    notifyListeners();
  }

  /// Removes a given [Tag] from the query, excluding it with a `-` prefix.
  void removeTag(String tag) {
    final tagArr = query.split(', ');
    tagArr.remove(tag);
    tagArr.add('-$tag');
    query = tagArr.join(', ');
    notifyListeners();
  }

  /// Gets one of [Representations] of the [Derpi] inside of the
  /// [DerpisRepo], based on the given [index] and [Quality].
  String getImageOfQuality(Quality quality, int index) {
    final reps = derpis[index].representations;
    switch (quality) {
      case Quality.Low:
        return reps.small ?? '';
      case Quality.Medium:
        return reps.medium ?? '';
      case Quality.High:
        return reps.large ?? '';
      case Quality.Source:
        return reps.full ?? '';
    }
  }
}
