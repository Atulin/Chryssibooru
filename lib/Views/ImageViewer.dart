import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

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

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  didChangeDependencies() {
    repo = Provider.of<DerpisRepo>(context);

    _videoController?.dispose();
    _videoController = VideoPlayerController.network('https:'+repo.derpis[_id].representations.medium)
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

    super.initState();
  }

  void _loadDerpisListener() {
    debugPrint(_volume.toString());
    // Swap the video
    if (_pageController.page.round() != _currentPage) {
      if (repo.derpis[_pageController.page.round()].mimeType == MimeType.VIDEO_WEBM) {
        _videoController.dispose();
        _videoController = VideoPlayerController.network('https:'+repo.derpis[_pageController.page.round()].representations.medium)
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

  @override
  Widget build(BuildContext mainContext) {
    return Scaffold(
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: repo.derpis.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return Center(child: () {
              if (repo.derpis[index].mimeType != MimeType.VIDEO_WEBM) {
                return new TransitionToImage(
                  image: AdvancedNetworkImage(
                      "https:" + repo.derpis[index].representations.medium,
                      useDiskCache: true,
                      cacheRule: CacheRule(maxAge: const Duration(days: 7))),
                  placeholder: Image(image: AssetImage('assets/logo-medium.png')),
                  loadingWidgetBuilder: (double progress) => CircularProgressIndicator(
                        value: progress,
                        semanticsValue: progress.toString(),
                      ),
                  fit: BoxFit.contain,
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
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _autoplay = !_autoplay;
                            debugPrint(_autoplay.toString());
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
                    )
                  ],
                );
              }
            }());
          },
          onPageChanged: (pageId) {
            setState(() {
              _id = pageId.round();
            });
          },
        ),
      ),
      bottomNavigationBar: GestureDetector(
        child: BottomAppBar(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
            child: Container(
              height: 30,
              child: Stack(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text((_id + 1).toString() +
                          '/' +
                          repo.derpis.length.toString())),
                  Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.keyboard_arrow_up),
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Text(repo.derpis[_id].score.toString()))
                ],
              ),
            ),
          ),
        ),
        onVerticalDragUpdate: (details) {
          showModalBottomSheet(
              context: mainContext,
              builder: (context) {
                Derpi derpi = repo.derpis[_id];
                List<Tag> tags = derpi.tags;
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(derpi.id.toString()),
                          ButtonBar(
                            children: <Widget>[
                              Container(
                                height: 30,
                                width: 30,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  child: Icon(Icons.share),
                                  onTap: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: 100.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                FlatButton(
                                                  onPressed: () => Share.share("https://derpibooru.org/" +derpi.id.toString()),
                                                  child:Text("Derpibooru post"),
                                                ),
                                                FlatButton(
                                                  onPressed: () => Share.share("https:" + derpi.representations.full),
                                                  child: Text("Direct image"),
                                                )
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("Share"),
                                          );
                                        });
                                  },
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  child: Icon(Icons.link),
                                  onTap: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: 100.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                FlatButton(
                                                  onPressed: () => openInBrowser("https://derpibooru.org/" +derpi.id.toString()),
                                                  child:Text("Derpibooru post"),
                                                ),
                                                FlatButton(
                                                  onPressed: () => openInBrowser("https:" +derpi.representations.full),
                                                  child: Text("Direct image"),
                                                )
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("Open in browser"),
                                          );
                                        });
                                  },
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  child: Icon(Icons.content_copy),
                                  onTap: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: 100.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                FlatButton(
                                                  onPressed: () => Clipboard.setData(new ClipboardData(
                                                      text: "https://derpibooru.org/" +derpi.id.toString())
                                                  ),
                                                  child:
                                                      Text("Derpibooru post"),
                                                ),
                                                FlatButton(
                                                  onPressed: () => Clipboard.setData(new ClipboardData(
                                                    text: "https:" + derpi.representations.full)
                                                  ),
                                                  child: Text("Direct image"),
                                                )
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("Copy direct link"),
                                          );
                                        });
                                  },
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  child: Icon(Icons.file_download),
                                  onTap: () =>
                                      downloadImage(derpi.representations.full),
                                  onLongPress: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("Download"),
                                          );
                                        });
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: new BoxConstraints(maxHeight: 100.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Text(derpi.description),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 1.0),
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: -5,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final tag in tags)
                                GestureDetector(
                                  child: Chip(
                                    padding: EdgeInsets.all(0),
                                    label: Text(tag.label),
                                    backgroundColor: {
                                          TagType.ARTIST: Colors.blue,
                                          TagType.OC: Colors.green,
                                          TagType.SPOILER: Colors.red,
                                        }[tag.type] ??
                                        Colors.grey,
                                  ),
                                  onTap: () {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext c) {
                                          return Container(
                                            height: 150.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                FlatButton(
                                                  onPressed: () async {
                                                    repo.derpis = new List<Derpi>();
                                                    repo.addTag(tag.label);
                                                    await repo.loadDerpis();
                                                    setState(() {
                                                      _id = 0;
                                                      _pageController
                                                          .jumpToPage(0);
                                                    });
                                                  },
                                                  child: Text("Add to search"),
                                                ),
                                                FlatButton(
                                                  onPressed: () async {
                                                    repo.derpis = new List<Derpi>();
                                                    repo.removeTag(tag.label);
                                                    await repo.loadDerpis();
                                                    setState(() {
                                                      _id = 0;
                                                      _pageController
                                                          .jumpToPage(0);
                                                    });
                                                  },
                                                  child: Text("Remove from search"),
                                                ),
                                                FlatButton(
                                                  onPressed: () async {
                                                    repo.derpis = new List<Derpi>();
                                                    repo.query = tag.label;
                                                    await repo.loadDerpis();
                                                    setState(() {
                                                      _id = 0;
                                                      _pageController
                                                          .jumpToPage(0);
                                                    });
                                                  },
                                                  child: Text("New search"),
                                                )
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                );
              });
        },
      ),
    );
  }
}
