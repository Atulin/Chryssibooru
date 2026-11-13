import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/DetailsSheet.dart';
import 'package:chryssibooru/Elements/ViewerBottomBar.dart';
import 'package:chryssibooru/Elements/ZoomableImage.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, this.title, required this.index});

  final String? title;
  final int index;

  @override
  ImageViewerState createState() => ImageViewerState();
}

class ImageViewerState extends State<ImageViewer> with WidgetsBindingObserver {
  PageController? _pageController;

  late final int initialIndex;
  int _currentPage = 0;

  ImageViewerState();

  VideoPlayerController? _videoController;
  String? _videoUrl;
  double _volume = 0.0;
  bool _autoplay = false;

  double _videoProgressPercent = 0.0;

  // While an image is zoomed in, page swiping is disabled so panning the
  // image takes precedence.
  bool _imageZoomed = false;

  // Preferred image quality.
  Quality _quality = Quality.Medium;

  DerpisRepo? _repo;
  DerpisRepo get repo {
    _repo ??= context.read<DerpisRepo>();
    return _repo!;
  }

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    initialIndex = widget.index;
    _currentPage = widget.index;
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: initialIndex);
    _getQualityPrefs();
    _setupVideoFor(initialIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeVideo();
    _pageController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop playback when the app goes to the background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _videoController?.pause();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _getQualityPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _quality =
          Quality.values[prefs.getInt('quality') ?? Quality.Medium.index];
    });
  }

  void _onVideoTick() {
    if (!mounted) return;
    final controller = _videoController;
    if (controller == null) return;
    final durationMs = controller.value.duration.inMilliseconds;
    setState(() {
      _videoProgressPercent = durationMs > 0
          ? (controller.value.position.inMilliseconds / durationMs).clamp(
              0.0,
              1.0,
            )
          : 0.0;
    });
  }

  /// Makes sure the video controller matches the entry at [index]. A new
  /// controller is created when the page is a different video; the old one
  /// is disposed when leaving a video page. Initialisation failures are
  /// ignored so a broken video cannot crash the viewer.
  Future<void> _setupVideoFor(int index) async {
    final derpis = repo.derpis;
    if (index < 0 || index >= derpis.length) return;
    final derpi = derpis[index];
    final url = derpi.representations.medium ?? '';

    if (!derpi.isVideo || url.isEmpty) {
      await _disposeVideo();
      return;
    }
    if (_videoController != null && _videoUrl == url) return;

    await _disposeVideo();
    _videoUrl = url;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    controller.addListener(_onVideoTick);

    try {
      await controller.initialize();
    } catch (_) {
      if (mounted && _videoController == controller) {
        setState(() {}); // Surface the error placeholder.
      }
      return;
    }
    if (!mounted || _videoController != controller) {
      // The page changed while we were initializing; clean up.
      await controller.dispose();
      return;
    }
    controller.setVolume(_volume);
    controller.setLooping(true);
    if (_autoplay) controller.play();
    setState(() {});
  }

  Future<void> _disposeVideo() async {
    final controller = _videoController;
    _videoController = null;
    _videoUrl = null;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      await controller.dispose();
    }
  }

  void _onPageChanged(int pageId) {
    final page = pageId.round();
    if (page == _currentPage) return;
    if (_imageZoomed) setState(() => _imageZoomed = false);
    setState(() {
      _currentPage = page;
      _videoProgressPercent = 0.0;
    });
    _setupVideoFor(page);

    // Load new elements when nearing the end of the list.
    if (repo.derpis.length - page <= 3) {
      repo.loadNextPage();
    }
  }

  void _onImageZoomChanged(bool zoomed) {
    if (!mounted || _imageZoomed == zoomed) return;
    setState(() => _imageZoomed = zoomed);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _pageController?.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _pageController?.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// The entry for the current page, clamped to the loaded list. During a
  /// fresh search (e.g. started by a tag action) the stored page position
  /// can point past the new results.
  Derpi? get _currentDerpi {
    final list = repo.derpis;
    if (list.isEmpty) return null;
    return list[_currentPage.clamp(0, list.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to repo updates so the page count grows as more results
    // load while browsing.
    _repo = context.watch<DerpisRepo>();
    repo; // Ensure the repo reference is resolved.

    // A fresh search empties the list; return the pager to page 0 so the
    // stored position can't point past the new results.
    if (repo.derpis.isEmpty) {
      final pc = _pageController;
      if (pc != null && pc.hasClients && pc.position.pixels != 0.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && repo.derpis.isEmpty) pc.jumpToPage(0);
        });
      }
      if (_currentPage != 0) _currentPage = 0;
    } else if (_currentPage >= repo.derpis.length) {
      // Defensive clamp while the new list is still shorter than the
      // stored position.
      _currentPage = repo.derpis.length - 1;
    }

    final current = _currentDerpi;

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Scaffold(
          body: Focus(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: _onKeyEvent,
            child: Column(
              children: [
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      // While an image is zoomed in, swiping is disabled so
                      // panning takes precedence; otherwise the page swipes
                      // natively and partial swipes snap back.
                      physics: _imageZoomed
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: _onPageChanged,
                      itemCount: repo.derpis.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _buildEntry(index);
                      },
                    ),
                  ),
                ),
                // The bar lives in the body (not in the Scaffold's
                // bottomNavigationBar slot) so nothing can push its
                // content below the screen edge.
                ViewerBottomBar(
                  currentIndex: repo.derpis.isEmpty
                      ? 0
                      : _currentPage.clamp(0, repo.derpis.length - 1),
                  totalCount: repo.derpis.length,
                  score: current?.score ?? 0,
                  onDetailsRequested: _showDetails,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetails() {
    final derpi = _currentDerpi;
    if (derpi == null) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DetailsSheet(derpi: derpi);
      },
    );
  }

  Widget _buildEntry(int index) {
    final derpi = repo.derpis[index];
    if (derpi.isVideo) {
      if (index == _currentPage) {
        return _buildVideoPlayer(derpi);
      }
      // Adjacent video pages get a static placeholder until the user
      // swipes to them, which avoids transient loading flashes.
      return _videoPlaceholder();
    }
    return ZoomableImage(
      url: repo.getImageOfQuality(_quality, index),
      isActive: index == _currentPage,
      onZoomChanged: _onImageZoomChanged,
    );
  }

  Widget _videoPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image(image: AssetImage('assets/logo-medium.png')),
        Icon(Icons.play_arrow, size: 48, color: Colors.white38),
      ],
    );
  }

  Widget _buildVideoPlayer(Derpi derpi) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      if (controller != null && controller.value.hasError) {
        return _videoError();
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          Image(image: AssetImage('assets/logo-medium.png')),
          CircularProgressIndicator(),
        ],
      );
    }
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () => setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              _autoplay = _autoplay ? false : true;
            }),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: IconButton(
            icon: Icon(
              controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
            ),
            onPressed: () => setState(() {
              _volume = controller.value.volume > 0 ? 0.0 : 50.0;
              controller.setVolume(_volume);
            }),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 3,
            child: LinearPercentIndicator(
              padding: EdgeInsets.all(0.0),
              barRadius: Radius.circular(0),
              lineHeight: 3.0,
              progressColor: Colors.teal,
              percent: _videoProgressPercent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoError() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image(image: AssetImage('assets/logo-medium.png')),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Could not load video', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
