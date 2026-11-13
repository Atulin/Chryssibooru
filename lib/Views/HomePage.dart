import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/FavouritesModal.dart';
import 'package:chryssibooru/Elements/FilterSheet.dart';
import 'package:chryssibooru/Elements/HistoryModal.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:chryssibooru/Enums/ERepresentations.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:chryssibooru/Views/ImageViewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helpers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title});

  final String? title;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

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

  String? _headerImage;

  String? currentVersion;

  String? _query;
  TextEditingController searchControl = TextEditingController();

  int cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _getCacheSize();
    _getCurrentVersion();
    _getRatingPrefs();
    _getQualityPrefs();
    _getSortMethodPrefs();
    _getKey();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchControl.dispose();
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

  void _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      currentVersion = packageInfo.version;
    });
  }

  void _getCacheSize() async {
    var cs = await _cacheSize();
    if (!mounted) return;
    setState(() {
      cacheSize = cs;
    });
  }

  /// Size of the image disk cache, in bytes.
  Future<int> _cacheSize() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory(
      '${dir.path}${Platform.pathSeparator}libCachedImageData',
    );
    if (!cacheDir.existsSync()) return 0;
    var size = 0;
    await for (final entity in cacheDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) size += entity.lengthSync();
    }
    return size;
  }

  void cleanCache() async {
    await DefaultCacheManager().emptyCache();
    _getCacheSize();
  }

  void _getQualityPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _quality =
          Quality.values[prefs.getInt('quality') ?? Quality.Medium.index];
    });
  }

  void _saveQualityPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quality', _quality.index);
  }

  void _getSortMethodPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sortMethod = ESortMethod
          .values[prefs.getInt('sortMethod') ?? ESortMethod.ID_DESC.index];
    });
  }

  void _saveSortMethodPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortMethod', _sortMethod.index);
  }

  void _getRatingPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _s = prefs.getBool('safe') ?? _s;
      _q = prefs.getBool('questionable') ?? _q;
      _e = prefs.getBool('explicit') ?? _e;
    });
  }

  void _saveRatingPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safe', _s);
    await prefs.setBool('questionable', _q);
    await prefs.setBool('explicit', _e);
  }

  void _saveKey(String key) async {
    setState(() {
      repo.key = key;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('key', key);
  }

  void _getKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      repo.key = prefs.getString('key') ?? '';
    });
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

  /// Applies the pending query/ratings/sort as a fresh search, preserving
  /// the old behaviour of only re-searching when something changed.
  void _submitSearch(String text) {
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
      repo.newSearch().then((loaded) {
        if (!loaded && repo.derpis.isEmpty) _showSnack('No results found');
      });
    }
  }

  /// Called when the filter sheet is closed. If the ratings or sorting
  /// changed while it was open, the grid is refreshed with a new search.
  void _onFilterSheetClosed() {
    if (_s != repo.safe ||
        _q != repo.questionable ||
        _e != repo.explicit ||
        _sortMethod != repo.sortMethod) {
      repo.sortMethod = _sortMethod;
      repo.setRatings(_s, _q, _e);
      repo.newSearch().then((loaded) {
        if (!loaded && repo.derpis.isEmpty) _showSnack('No results found');
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void updateSearch(String value) => setState(() => searchControl.text = value);

  bool _isHeaderLoading = false;
  void _setHeaderImage() async {
    setState(() {
      _isHeaderLoading = true;
    });
    final derp = await getRandomImage(
      'chrysalis,solo,transparent background,-webm',
    );
    if (!mounted) return;
    if (derp == null || (derp.representations.medium ?? '').isEmpty) {
      setState(() {
        _isHeaderLoading = false;
      });
      _showSnack('Could not load a random header image');
      return;
    }
    setState(() {
      _headerImage = derp.representations.medium;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to repo updates so the grid refreshes when a new page of
    // results loads.
    _repo = context.watch<DerpisRepo>();
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: () {
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
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _loadDerpisListener,
                          child: GridView.builder(
                            controller: _scrollController,
                            itemCount: repo.derpis.length,
                            scrollCacheExtent: ScrollCacheExtent.viewport(0.5),
                            physics: BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
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
                                      builder: (context) =>
                                          ImageViewer(index: index),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                  elevation: 5,
                                  child: Padding(
                                    padding: EdgeInsets.all(0.2),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10.0),
                                      ),
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
                        LinearProgressIndicator(
                          minHeight: 2.0,
                          color: Colors.teal,
                        ),
                    ],
                  );
                }
              }(),
            ),
          ],
        ),
      ),
      // The keyboard covers the bottom bar on current Android versions
      // (edge-to-edge), so it is lifted above the keyboard manually.
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              Expanded(
                child: TextField(
                  controller: searchControl,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Please enter a search term',
                  ),
                  onSubmitted: _submitSearch,
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return FilterSheet(
                        safe: _s,
                        safeChanged: (bool value) {
                          _s = value;
                          _saveRatingPrefs();
                        },
                        questionable: _q,
                        questionableChanged: (bool value) {
                          _q = value;
                          _saveRatingPrefs();
                        },
                        explicit: _e,
                        explicitChanged: (bool value) {
                          _e = value;
                          _saveRatingPrefs();
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
                },
              ),
            ],
          ),
        ),
      ),

      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(1, 100, 150, 150),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  () {
                    if (_headerImage != null) {
                      return CachedNetworkImage(
                        imageUrl: _headerImage!,
                        placeholder: (context, url) =>
                            SvgPicture.asset('assets/logo.svg'),
                        errorWidget: (context, url, error) =>
                            SvgPicture.asset('assets/logo.svg'),
                        imageBuilder: (context, imageProvider) {
                          if (_isHeaderLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _isHeaderLoading = false);
                              }
                            });
                          }
                          return Image(image: imageProvider, fit: BoxFit.cover);
                        },
                        fit: BoxFit.cover,
                        fadeInDuration: Duration(milliseconds: 300),
                      );
                    } else {
                      return SvgPicture.asset('assets/logo.svg');
                    }
                  }(),
                  Positioned(
                    right: 0.0,
                    bottom: 0.0,
                    child: GestureDetector(
                      child: Icon(
                        Icons.shuffle,
                        color: Color.fromARGB(50, 255, 255, 255),
                        size: 20,
                      ),
                      onTap: () => _setHeaderImage(),
                      onLongPress: () {
                        setState(() {
                          _headerImage = null;
                          _isHeaderLoading = false;
                        });
                      },
                    ),
                  ),
                  if (_isHeaderLoading)
                    Positioned(
                      left: 0.0,
                      bottom: 0.0,
                      child: Text(
                        "Loading...",
                        style: TextStyle(
                          color: Color.fromARGB(50, 255, 255, 255),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              title: Text("Enter API key"),
              subtitle: Text(
                repo.key == ""
                    ? "Get it on Derpibooru in account settings"
                    : "All set!",
                style: TextStyle(fontSize: 12.0),
              ),
              leading: Icon(Icons.vpn_key),
              onTap: showKeySheet,
            ),
            ListTile(
              title: Text("Cache size: ${parseFileSize(cacheSize)}"),
              subtitle: Text(
                "Tap to recalculate, hold to clean",
                style: TextStyle(fontSize: 12.0),
              ),
              leading: Icon(Icons.folder_open),
              onTap: _getCacheSize,
              onLongPress: cleanCache,
            ),
            ListTile(
              title: Text("History"),
              subtitle: Text(
                "See your previous searches",
                style: TextStyle(fontSize: 12.0),
              ),
              leading: Icon(Icons.history),
              onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return HistoryModal(repo: repo, callback: updateSearch);
                },
              ),
            ),
            ListTile(
              title: Text("Favourites"),
              subtitle: Text(
                "See your favourite searches",
                style: TextStyle(fontSize: 12.0),
              ),
              leading: Icon(Icons.favorite),
              onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FavouritesModal(repo: repo, callback: updateSearch);
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text("Buy me a coffee"),
              subtitle: Text(
                "Or two, I don't judge",
                style: TextStyle(fontSize: 12.0),
              ),
              leading: Icon(Icons.free_breakfast),
              onTap: () async {
                final ok = await openInBrowser("https://ko-fi.com/angius");
                if (!ok) _showSnack('Could not open the link');
              },
            ),
            AboutListTile(
              applicationIcon: SvgPicture.asset(
                'assets/logo.svg',
                height: 20,
                width: 20,
              ),
              icon: Icon(Icons.info_outline),
              applicationVersion: currentVersion,
              aboutBoxChildren: <Widget>[
                ElevatedButton(
                  child: Text("Github repo"),
                  onPressed: () async {
                    final ok = await openInBrowser(
                      "https://github.com/Atulin/Chryssibooru",
                    );
                    if (!ok) _showSnack('Could not open the link');
                  },
                ),
                ElevatedButton(
                  child: Text("Debug info"),
                  onPressed: () => showModalBottomSheet(
                    context: _scaffoldKey.currentContext ?? context,
                    builder: (BuildContext context) {
                      return Text(_query ?? "No recent queries");
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void showKeySheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10.0,
            1.0,
            10.0,
            MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: prefs.getString('key')?.isNotEmpty == true
                  ? 'API key saved'
                  : 'Your API key here',
            ),
            onSubmitted: (text) {
              _saveKey(text);
              Navigator.of(context).pop();
            },
            autofocus: true,
          ),
        );
      },
    );
  }
}
