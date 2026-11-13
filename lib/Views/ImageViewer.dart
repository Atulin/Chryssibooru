import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:chryssibooru/Elements/DetailsSheet.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:material_ui/material_ui.dart';
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

  // For disabling the PageView when image is zoomed in.
  bool _isPageViewDisabled = false;
  final TransformationController _transformationController =
      TransformationController();

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
    _transformationController.addListener(_onTransformationChanged);
    _getQualityPrefs();
    _setupVideoFor(initialIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
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

  void _onTransformationChanged() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.001;
    if (zoomed != _isPageViewDisabled) {
      setState(() {
        _isPageViewDisabled = zoomed;
      });
    }
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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _pageController?.previousPage(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _pageController?.nextPage(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to repo updates so the page count grows as more results
    // load while browsing.
    _repo = context.watch<DerpisRepo>();
    repo; // Ensure the repo reference is resolved.
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Scaffold(
          extendBodyBehindAppBar: orientation == Orientation.landscape,
          extendBody: orientation == Orientation.landscape,
          body: Focus(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: _onKeyEvent,
            child: Center(
              child: PageView.builder(
                controller: _pageController,
                itemCount: repo.derpis.length,
                physics: _isPageViewDisabled
                    ? NeverScrollableScrollPhysics()
                    : BouncingScrollPhysics(),
                pageSnapping: true,
                onPageChanged: _onPageChanged,
                itemBuilder: (BuildContext context, int index) {
                  return Center(child: _buildEntry(index));
                },
              ),
            ),
          ),
          bottomNavigationBar: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return BottomAppBar(
                color: orientation == Orientation.landscape
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.surface,
                elevation: orientation == Orientation.landscape ? 0.0 : 8.0,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    height: 30,
                    child: Stack(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${(_currentPage + 1)}/${repo.derpis.length}",
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            child: Icon(Icons.keyboard_arrow_up),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  Derpi derpi = repo.derpis[_currentPage];
                                  return DetailsSheet(derpi: derpi);
                                },
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Builder(
                            builder: (context) {
                              final score = repo.derpis[_currentPage].score;
                              return Text(
                                score.toString(),
                                style: TextStyle(
                                  color: score >= 0
                                      ? Color.fromARGB(255, 0, 255, 0)
                                      : Color.fromARGB(255, 255, 0, 0),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
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
    return _buildZoomableImage(index, derpi);
  }

  Widget _buildZoomableImage(int index, Derpi derpi) {
    final url = repo.getImageOfQuality(_quality, index);
    if (url.isEmpty) {
      return Image(image: AssetImage('assets/logo-medium.png'));
    }
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      // Panning is only enabled while zoomed in, so a single-finger drag
      // passes through to the PageView when at rest.
      panEnabled: _isPageViewDisabled,
      child: CachedNetworkImage(
        imageUrl: url,
        // No fade transitions: when swiping, media should appear
        // instantly once it is available.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            Image(image: AssetImage('assets/logo-medium.png')),
        errorWidget: (context, url, error) =>
            Image(image: AssetImage('assets/logo-medium.png')),
        fit: BoxFit.contain,
      ),
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
