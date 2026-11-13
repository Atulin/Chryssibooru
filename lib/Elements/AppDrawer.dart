import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/Views/SourcesScreen.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/build_info.dart';
import 'package:chryssibooru/Elements/HistoryModal.dart';
import 'package:chryssibooru/Elements/FavouritesModal.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../Helpers.dart';

/// The navigation drawer: branded header with a random Chryssi, API key
/// access, cache management, search history and favourites, and the about
/// section. Extracted from [HomePage] so the home screen's build method
/// stays shallow.
class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.onSearchSelected,
    required this.onSourcesChanged,
    this.lastQuery,
  });

  /// Called when a history or favourites entry should become the active
  /// search; updates the search bar's text.
  final ValueChanged<String> onSearchSelected;

  /// Called when the sources screen changed anything (add, edit or
  /// remove), so the caller can re-apply the active source.
  final ValueChanged<bool> onSourcesChanged;

  /// The most recent query, shown under "Debug info" in the about section.
  final String? lastQuery;

  @override
  AppDrawerState createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  String? _headerImage;
  int _cacheSize = 0;
  String? _currentVersion;

  DerpisRepo get repo => context.read<DerpisRepo>();

  @override
  void initState() {
    super.initState();
    _getCurrentVersion();
    _getCacheSize();
  }

  void _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  void _getCacheSize() async {
    var cs = await _computeCacheSize();
    if (!mounted) return;
    setState(() {
      _cacheSize = cs;
    });
  }

  /// Size of the image disk cache, in bytes.
  Future<int> _computeCacheSize() async {
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isHeaderLoading = false;
  void _setHeaderImage() async {
    if (_isHeaderLoading) return;
    setState(() {
      _isHeaderLoading = true;
    });
    final derp = await getRandomImage(
      'chrysalis,solo,transparent background,-webm',
    );
    if (!mounted) return;
    final url = derp?.representations.medium ?? '';
    if (url.isEmpty) {
      setState(() {
        _isHeaderLoading = false;
      });
      _showSnack('Could not load a random header image');
      return;
    }
    // The old image stays visible (gapless playback) until the new one
    // has loaded, then they crossfade.
    setState(() {
      _headerImage = url;
      _isHeaderLoading = false;
    });
  }

  void _openHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HistoryModal(repo: repo, callback: widget.onSearchSelected);
      },
    );
  }

  void _openFavourites() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FavouritesModal(repo: repo, callback: widget.onSearchSelected);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          _buildHeader(),
          _buildSourcesTile(),
          _buildCacheTile(),
          _buildHistoryTile(),
          _buildFavouritesTile(),
          const Divider(),
          _buildKofiTile(),
          _buildAboutTile(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: const Color.fromARGB(1, 100, 150, 150)),
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
                fit: BoxFit.cover,
                // Keep the previously shown image while the new random
                // one loads, then crossfade quickly from it (or from the
                // logo on the first load).
                useOldImageOnUrlChange: true,
                fadeInDuration: Duration(milliseconds: 300),
                fadeOutDuration: Duration(milliseconds: 300),
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
                style: TextStyle(color: Color.fromARGB(50, 255, 255, 255)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourcesTile() {
    return ListTile(
      title: Text("Sources"),
      subtitle: Text(
        "Manage booru sources and their API keys",
        style: TextStyle(fontSize: 12.0),
      ),
      leading: Icon(Icons.dns),
      onTap: _openSources,
    );
  }

  void _openSources() {
    Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (context) =>
            SourcesScreen(onSourcesChanged: widget.onSourcesChanged),
      ),
    );
  }

  Widget _buildCacheTile() {
    return ListTile(
      title: Text("Cache size: ${parseFileSize(_cacheSize)}"),
      subtitle: Text(
        "Tap to recalculate, hold to clean",
        style: TextStyle(fontSize: 12.0),
      ),
      leading: Icon(Icons.folder_open),
      onTap: _getCacheSize,
      onLongPress: cleanCache,
    );
  }

  Widget _buildHistoryTile() {
    return ListTile(
      title: Text("History"),
      subtitle: Text(
        "See your previous searches",
        style: TextStyle(fontSize: 12.0),
      ),
      leading: Icon(Icons.history),
      onTap: _openHistory,
    );
  }

  Widget _buildFavouritesTile() {
    return ListTile(
      title: Text("Favourites"),
      subtitle: Text(
        "See your favourite searches",
        style: TextStyle(fontSize: 12.0),
      ),
      leading: Icon(Icons.favorite),
      onTap: _openFavourites,
    );
  }

  Widget _buildKofiTile() {
    return ListTile(
      title: Text("Buy me a coffee"),
      subtitle: Text("Or two, I don't judge", style: TextStyle(fontSize: 12.0)),
      leading: Icon(Icons.free_breakfast),
      onTap: () async {
        final ok = await openInBrowser("https://ko-fi.com/angius");
        if (!ok) _showSnack('Could not open the link');
      },
    );
  }

  Widget _buildAboutTile() {
    return AboutListTile(
      applicationIcon: SvgPicture.asset(
        'assets/logo.svg',
        height: 20,
        width: 20,
      ),
      icon: Icon(Icons.info_outline),
      applicationVersion: _currentVersion,
      aboutBoxChildren: <Widget>[
        if (buildDate.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Built: $buildDate',
              style: const TextStyle(fontSize: 12.0),
            ),
          ),
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
            context: context,
            builder: (BuildContext context) {
              return Text(widget.lastQuery ?? "No recent queries");
            },
          ),
        ),
      ],
    );
  }
}
