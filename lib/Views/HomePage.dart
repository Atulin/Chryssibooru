import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/BooruSource.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/AppDrawer.dart';
import 'package:chryssibooru/Elements/HomeBottomBar.dart';
import 'package:chryssibooru/Views/ImageViewer.dart';
import 'package:chryssibooru/Elements/FilterSheet.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:chryssibooru/Enums/ERepresentations.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title});

  final String? title;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  DerpisRepo? _repo;
  DerpisRepo get repo {
    _repo ??= context.read<DerpisRepo>();
    return _repo!;
  }

  bool _s = true;
  bool _q = false;
  bool _e = false;

  Quality _quality = Quality.Medium;
  ESortMethod _sortMethod = ESortMethod.ID_DESC;

  String? _query;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<BooruSource> _sources = [BooruSource.defaultSource()];
  String _activeSourceId = BooruSource.defaultSourceId;

  /// The repo query the search bar's text was last synced with, so the
  /// bar follows query changes (e.g. from tag actions) without clobbering
  /// text the user is typing when the query hasn't changed.
  String? _lastSyncedQuery;

  @override
  void initState() {
    super.initState();
    _getPrefs();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Loads the next page whenever the grid is scrolled near its end. The
  /// check also fires during overscroll: when the user is flung past the
  /// end they are effectively asking for more content. Concurrent or
  /// repeated requests are filtered by [DerpisRepo.loadNextPage] itself.
  bool _loadDerpisListener(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent - metrics.pixels < 400.0) {
      repo.loadNextPage().then((result) {
        if (result == LoadResult.failed && repo.derpis.isNotEmpty) {
          _showLoadError();
        }
      });
    }
    return false;
  }

  /// Throttled failure notice for pagination, so repeated scroll events
  /// during one failed fetch don't stack up snackbars.
  DateTime _lastLoadError = DateTime.fromMillisecondsSinceEpoch(0);
  void _showLoadError() {
    final now = DateTime.now();
    if (now.difference(_lastLoadError) < const Duration(seconds: 3)) return;
    _lastLoadError = now;
    _showSnack('Loading more images failed');
  }

  void _getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final sources = await SourcesStore.load(prefs);
    final activeId = await SourcesStore.loadActiveId(prefs);
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _activeSourceId = sources.any((s) => s.id == activeId)
          ? activeId
          : BooruSource.defaultSourceId;
      // The source must be applied first: the questionable and explicit
      // ratings' defaults depend on its API key (they require one).
      repo.host = _activeSource.host;
      repo.key = _activeSource.apiKey;
      repo.searchPath = _activeSource.searchPath;
      repo.resultKey = _activeSource.resultKey;
      _s = prefs.getBool('safe') ?? _s;
      _q = prefs.getBool('questionable') ?? repo.key.isNotEmpty;
      _e = prefs.getBool('explicit') ?? repo.key.isNotEmpty;
      _quality =
          Quality.values[prefs.getInt('quality') ?? Quality.Medium.index];
      _sortMethod = ESortMethod
          .values[prefs.getInt('sortMethod') ?? ESortMethod.ID_DESC.index];
    });
    repo.setRatings(_s, _q, _e);
  }

  void _saveQualityPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quality', _quality.index);
  }

  void _saveSortMethodPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortMethod', _sortMethod.index);
  }

  void _saveRatingChoice(String name, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(name, value);
  }

  void _saveSearch(String search) async {
    if (search.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];

    if (!history.contains(search)) {
      if (history.length >= 50) history.removeAt(0);
      history.add(search);
      await prefs.setStringList('history', history);
    }
  }

  BooruSource get _activeSource => _sources.firstWhere(
    (s) => s.id == _activeSourceId,
    orElse: () => _sources.first,
  );

  /// Applies the active source to the repo, keeping the rating defaults
  /// in sync with the presence of an API key (a key unlocks NSFW, so
  /// questionable and explicit are checked by default when one is
  /// added, and unchecked when it is removed).
  void _applyActiveSource({required bool refresh}) {
    final active = _activeSource;
    final hadKey = repo.key.isNotEmpty;
    repo.host = active.host;
    repo.key = active.apiKey;
    repo.searchPath = active.searchPath;
    repo.resultKey = active.resultKey;

    if (!hadKey && repo.key.isNotEmpty) {
      _q = true;
      _e = true;
    } else if (hadKey && repo.key.isEmpty) {
      _q = false;
      _e = false;
    }
    repo.setRatings(_s, _q, _e);

    if (refresh) {
      if (repo.query.isNotEmpty) {
        _reactToSearchResult(repo.newSearch());
      } else {
        setState(() {});
      }
    }
  }

  /// Called when the drawer's sources screen changed anything.
  void _onSourcesChanged(bool changed) {
    if (!changed) return;
    _reloadSources();
  }

  Future<void> _reloadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final sources = await SourcesStore.load(prefs);
    final activeId = await SourcesStore.loadActiveId(prefs);
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _activeSourceId = sources.any((s) => s.id == activeId)
          ? activeId
          : BooruSource.defaultSourceId;
    });
    _applyActiveSource(refresh: repo.query.isNotEmpty);
  }

  /// Called when a different source is picked in the filter sheet.
  void _onSourceSelected(BooruSource source) {
    _activeSourceId = source.id;
    SharedPreferences.getInstance().then((prefs) {
      SourcesStore.saveActiveId(prefs, source.id);
    });
    _applyActiveSource(refresh: repo.query.isNotEmpty);
  }

  /// Applies the pending query/ratings/sort as a fresh search, preserving
  /// the old behaviour of only re-searching when something changed. An
  /// empty query is never sent: the rating clause would be malformed
  /// server-side and there is nothing to look for.
  void _submitSearch(String text) {
    if (text.isEmpty) return;
    if (text != repo.query ||
        _s != repo.safe ||
        _q != repo.questionable ||
        _e != repo.explicit ||
        _sortMethod != repo.sortMethod) {
      repo.query = text;
      repo.sortMethod = _sortMethod;
      repo.setRatings(_s, _q, _e);
      _saveSearch(text);
      setState(() {
        _query = repo.getQuery();
      });
      _reactToSearchResult(repo.newSearch());
    }
  }

  /// Opens the filter sheet and applies pending changes on close.
  void _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return FilterSheet(
          hasKey: repo.key.isNotEmpty,
          sources: _sources,
          activeSourceId: _activeSourceId,
          onSourceChanged: _onSourceSelected,
          safe: _s,
          safeChanged: (bool value) {
            _s = value;
            _saveRatingChoice('safe', value);
          },
          questionable: _q,
          questionableChanged: (bool value) {
            _q = value;
            _saveRatingChoice('questionable', value);
          },
          explicit: _e,
          explicitChanged: (bool value) {
            _e = value;
            _saveRatingChoice('explicit', value);
          },
          quality: _quality,
          qualityChanged: (Quality q) {
            _quality = q;
            _saveQualityPrefs();
          },
          sortMethod: _sortMethod,
          sortMethodChanged: (ESortMethod s) {
            setState(() {
              _sortMethod = s;
              _saveSortMethodPrefs();
            });
          },
        );
      },
    );
    _onFilterSheetClosed();
  }

  /// Called when the filter sheet is closed. If the ratings or sorting
  /// changed while it was open, the grid is refreshed with a new search.
  /// With no query entered yet, toggling the checkboxes or the sorting
  /// must not send a request.
  void _onFilterSheetClosed() {
    if (repo.query.isEmpty) return;
    if (_s != repo.safe ||
        _q != repo.questionable ||
        _e != repo.explicit ||
        _sortMethod != repo.sortMethod) {
      repo.sortMethod = _sortMethod;
      repo.setRatings(_s, _q, _e);
      _reactToSearchResult(repo.newSearch());
    }
  }

  void _reactToSearchResult(Future<LoadResult> result) {
    result.then((value) {
      if (value == LoadResult.failed) {
        _showSnack('Search failed');
      } else if (value != LoadResult.added && repo.derpis.isEmpty) {
        _showSnack('No results found');
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void updateSearch(String value) =>
      setState(() => _searchController.text = value);

  @override
  Widget build(BuildContext context) {
    // Subscribe to repo updates so the grid refreshes when a new page of
    // results loads.
    _repo = context.watch<DerpisRepo>();
    // Mirror query changes (e.g. tag actions in the info sheet) into the
    // search bar. Only fires when the query itself changed, so partially
    // typed text is never overwritten by unrelated rebuilds.
    if (repo.query != _lastSyncedQuery) {
      _lastSyncedQuery = repo.query;
      if (_searchController.text != repo.query) {
        _searchController.text = repo.query;
      }
      // Query changes from anywhere (tag actions, history picks, ...)
      // belong in the history too, not just submitted searches.
      _saveSearch(repo.query);
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: _buildContent()),
            // The search row lives in the body (not in the Scaffold's
            // bottomNavigationBar slot) so resizeToAvoidBottomInset
            // keeps it above the keyboard natively while typing.
            HomeBottomBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchSubmitted: _submitSearch,
              onFilterPressed: _openFilterSheet,
            ),
          ],
        ),
      ),

      drawer: AppDrawer(
        onSearchSelected: updateSearch,
        onSourcesChanged: _onSourcesChanged,
        lastQuery: _query,
      ),
    );
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  /// The grid or the placeholder, depending on whether results exist.
  Widget _buildGridOrLogo() {
    if (repo.derpis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/logo-medium.png')),
            if (!repo.loaded) ...[
              SizedBox(height: 16.0),
              CircularProgressIndicator(),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _loadDerpisListener,
            child: GridView.builder(
              controller: _scrollController,
              itemCount: repo.derpis.length,
              scrollCacheExtent: ScrollCacheExtent.viewport(0.5),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200.0,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemBuilder: (BuildContext c, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewer(index: index),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: EdgeInsets.all(0.2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        child: _gridThumb(repo.derpis[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (!repo.loaded)
          LinearProgressIndicator(minHeight: 2.0, color: Colors.teal),
      ],
    );
  }

  /// The content area, absorbed while the search bar is focused so a tap
  /// anywhere only dismisses the keyboard instead of opening an image.
  Widget _buildContent() {
    final content = _buildGridOrLogo();
    if (_searchFocusNode.hasFocus) {
      return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: IgnorePointer(child: content),
      );
    }
    return content;
  }

  /// Grid thumbnail for an image entry, or the animated `.gif` preview for
  /// a video entry (a long-standing Derpibooru convention). Recent video
  /// uploads have no `.gif` preview; the logo placeholder is shown instead.
  Widget _gridThumb(Derpi derpi) {
    var url = derpi.representations.fromEnum(ERepresentations.Thumb);
    if (derpi.isVideo) {
      final parts = url.split('.');
      if (parts.isNotEmpty) {
        parts[parts.length - 1] = 'gif';
        url = parts.join('.');
      }
    }
    if (url.isEmpty) {
      return SvgPicture.asset('assets/logo.svg', fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => Padding(
        padding: const EdgeInsets.all(40.0),
        child: SvgPicture.asset('assets/logo.svg', fit: BoxFit.scaleDown),
      ),
      errorWidget: (context, url, error) =>
          SvgPicture.asset('assets/logo.svg', fit: BoxFit.scaleDown),
      fit: BoxFit.cover,
      fadeInDuration: Duration(milliseconds: 150),
    );
  }
}
