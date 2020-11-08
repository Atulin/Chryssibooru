import 'package:chryssibooru/Elements/DetailsSheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'package:provider/provider.dart' as p;
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../Helpers.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer({Key key, this.title, @required this.index}) : super(key: key);

  final String title;
  final int index;

  @override
  ImageViewerState createState() => ImageViewerState(initialIndex: index);
}

class ImageViewerState extends State<ImageViewer> {
  PageController _pageController;

  final int initialIndex;
  int _currentPage;

  ImageViewerState({this.initialIndex});

  VideoPlayerController _videoController;
  double _volume = 0.0;
  bool _autoplay = false;

  List<Derpi> derpis = new List<Derpi>();
  int _id = 0;

  int descMaxLines = 3;

  DerpisRepo repo;

  double _videoProgressPercent = 0.0;

  // For disabling the PageView when image is zoomed in
  bool _isPageViewDisabled = false;

  // Preferred image quality
  Quality _quality;


  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  didChangeDependencies() {
    repo = p.Provider.of<DerpisRepo>(context);

    _videoController?.dispose();
    _videoController = VideoPlayerController.network(repo.derpis[_id].representations.medium)
    ..addListener(() {
      setState(() {
        if (_videoController.value.duration != null)
          _videoProgressPercent = (_videoController.value.position.inMilliseconds / _videoController.value.duration.inMilliseconds).clamp(0.0, 1.0);
      });
    })
    ..initialize().then((_) {
      _videoController.setVolume(_volume);
      _videoController.setLooping(true);
      if (_autoplay) _videoController.play();
      setState(() {});
    });

    super.didChangeDependencies();
  }

  @override
  void initState() {
    _id = initialIndex;
    _currentPage = initialIndex;

    _pageController = PageController(initialPage: initialIndex);
    _pageController.addListener(_loadDerpisListener);

    _getQualityPrefs();

    super.initState();
  }

  void _loadDerpisListener() {
    // Swap the video
    if (_pageController.page.round() != _currentPage) {
      if (repo.derpis[_pageController.page.round()].mimeType == MimeType.VIDEO_WEBM) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.network(repo.derpis[_pageController.page.round()].representations.medium)
        ..addListener(() {
          setState(() {
            _videoProgressPercent = (_videoController.value.position.inMilliseconds / _videoController.value.duration.inMilliseconds).clamp(0.0, 1.0);
          });
        })
        ..initialize().then((_) {
          _videoController.setVolume(_volume);
          _videoController.setLooping(true);
          if (_autoplay) _videoController.play();
          setState(() {});
        });
      }
      _currentPage = _pageController.page.round();
    }

    // Load new elements
    if (repo.derpis.length - _pageController.page <= 3.0 &&
        !_pageController.position.outOfRange &&
        repo.loaded) {
      repo.page++;
      setState(() {
        repo.loadDerpis();
      });
    }
  }

  void _getQualityPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _quality = Quality.values[prefs.getInt('quality') ?? Quality.Medium.index];
    });
  }

  @override
  Widget build(BuildContext mainContext) {
    return Scaffold(
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: repo.derpis.length,
          physics: _isPageViewDisabled ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return Center(child: () {
              if (repo.derpis[index].mimeType != MimeType.VIDEO_WEBM) {
                return ZoomableWidget (
                  minScale: 1.0,
                  maxScale: 5.0,
                  autoCenter: true,
                  onZoomChanged: (double zoom) {
                    setState(() {
                      _isPageViewDisabled = zoom > 1.0 ? true : false;
                    });
                  },
                  child: Container(
                    child: TransitionToImage(
                      image: AdvancedNetworkImage(
                          getImageOfQuality(_quality, repo, index),
                          useDiskCache: true,
                          cacheRule: CacheRule(maxAge: const Duration(days: 7))
                      ),
                      placeholder: Image(image: AssetImage('assets/logo-medium.png')),
                      loadingWidgetBuilder: (BuildContext ctx, double progress, _) => CircularProgressIndicator(
                        value: progress,
                        semanticsValue: progress.toString(),
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              } else {
                return Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        child: _videoController.value.initialized
                            ? AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: VideoPlayer(_videoController),
                              )
                            : CircularProgressIndicator(),
                        onTap: () {
                          setState(() {
                            _videoController.value.isPlaying
                                ? _videoController.pause()
                                : _videoController.play();
                            _autoplay = _autoplay ? false : true;
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: IconButton(
                          icon: Icon(_videoController.value.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () => setState(() {
                            _videoController.value.isPlaying
                                ? _videoController.pause()
                                : _videoController.play();
                            _autoplay = _autoplay ? false : true;
                          })
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                          icon: Icon(_videoController.value.volume > 0 ? Icons.volume_up : Icons.volume_off),
                          onPressed: () => setState(() {
                            _videoController.value.volume > 0
                                ? _volume = 0.0
                                : _volume = 50.0;
                            _videoController.setVolume(_volume);
                          })
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 3,
                        child: new LinearPercentIndicator(
                          padding: EdgeInsets.all(0.0),
                          linearStrokeCap: LinearStrokeCap.butt,
                          lineHeight: 3.0,
                          progressColor: Colors.teal,
                          percent: _videoProgressPercent,
                        )
                      ),
                    )
                  ],
                );
              }
            }());
          },
          onPageChanged: (pageId) {
            setState(() {
              _id = pageId.round();
              _videoProgressPercent = 0.0;
              _videoController.pause();
            });
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
          child: Container(
            height: 30,
            child: Stack(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text((_id + 1).toString() + '/' + repo.derpis.length.toString())),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    child: Icon(Icons.keyboard_arrow_up),
                    onTap: () {
                      showModalBottomSheet(
                          context: mainContext,
                          builder: (context) {
                            Derpi derpi = repo.derpis[_id];
                            return DetailsSheet(derpi: derpi);
                          }
                      );
                    },
                  ),
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                        repo.derpis[_id].score.toString(),
                        style: TextStyle(
                            color: repo.derpis[_id].score >= 0
                                ? Color.fromARGB(255, 0, 255, 0)
                                : Color.fromARGB(255, 255, 0, 0)
                        )
                    )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
