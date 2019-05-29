import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer({Key key, this.title, @required this.index}) : super(key: key);

  final String title;
  final int index;

  @override
  ImageViewerState createState() => ImageViewerState(initialIndex: index);
}

class ImageViewerState extends State<ImageViewer> {
  final int initialIndex;

  ImageViewerState({this.initialIndex});

  List<Derpi> derpis = new List<Derpi>();
  int _id = 0;

  int descMaxLines = 3;

  DerpisRepo repo;

  @override
  didChangeDependencies() {
    repo = Provider.of<DerpisRepo>(context);

    super.didChangeDependencies();
  }

  PageController _pageController;

  @override
  void initState() {
    _id = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
    _pageController.addListener(_loadDerpisListener);
    super.initState();
  }

  void _loadDerpisListener() {
    if (repo.derpis.length - _pageController.page <= 3.0
        && !_pageController.position.outOfRange
        && repo.loaded) {
      repo.page++;
      setState(() {
        repo.loadDerpis();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: repo.derpis.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return Center(
                child: (){
                  if(repo.derpis[index].mimeType != MimeType.VIDEO_WEBM){
                    return new TransitionToImage(
                        image: AdvancedNetworkImage(
                          "https:" + repo.derpis[index].representations.medium,
                          useDiskCache: true,
                          cacheRule: CacheRule(maxAge: const Duration(days: 7))
                        ),
                      placeholder: Image(image: AssetImage('assets/logo-medium.png')),
                      loadingWidgetBuilder: (double progress) => CircularProgressIndicator(
                        value: progress,
                        semanticsValue: progress.toString(),
                      ),
                      fit: BoxFit.contain,
                    );
                  } else {
                    return new Center(
                      child: Text("Webm isn't supported yet 😢"),
                    );
                  }
                }()
            );
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text((_id+1).toString() + '/' + repo.derpis.length.toString()),
                Icon(Icons.keyboard_arrow_up),
                Text(repo.derpis[_id].score.toString())
              ],
            ),
          ),
        ),
        onVerticalDragUpdate: (details) {
          showModalBottomSheet(context: context, builder: (context){
            Derpi derpi = repo.derpis[_id];
            List<Tag> tags = derpi.tags;
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
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
                              borderRadius: BorderRadius.all(Radius.circular(50.0)),
                              child: Icon(Icons.share),
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container(
                                        height: 100.0,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            FlatButton(
                                              onPressed: () => Share.share("https://derpibooru.org/"+derpi.id.toString()),
                                              child: Text("Derpibooru post"),
                                            ),
                                            FlatButton(
                                              onPressed: () => Share.share("https:"+derpi.representations.full),
                                              child: Text("Direct image"),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                );
                              },
                              onLongPress: (){
                                showModalBottomSheet(context: context, builder: (BuildContext context){
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
                              borderRadius: BorderRadius.all(Radius.circular(50.0)),
                              child: Icon(Icons.link),
                              onTap: (){
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      height: 100.0,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          FlatButton(
                                            onPressed: () => openInBrowser("https://derpibooru.org/"+derpi.id.toString()),
                                            child: Text("Derpibooru post"),
                                          ),
                                          FlatButton(
                                            onPressed: () => openInBrowser("https:"+derpi.representations.full),
                                            child: Text("Direct image"),
                                          )
                                        ],
                                      ),
                                    );
                                  }
                                );
                              },
                              onLongPress: (){
                                showModalBottomSheet(context: context, builder: (BuildContext context){
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
                              borderRadius: BorderRadius.all(Radius.circular(50.0)),
                              child: Icon(Icons.content_copy),
                              onTap: () {
                                showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container(
                                        height: 100.0,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            FlatButton(
                                              onPressed: () => Clipboard.setData(new ClipboardData(text: "https://derpibooru.org/"+derpi.id.toString())),
                                              child: Text("Derpibooru post"),
                                            ),
                                            FlatButton(
                                              onPressed: () => Clipboard.setData(new ClipboardData(text: "https:"+derpi.representations.full)),
                                              child: Text("Direct image"),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                );
                              },
                              onLongPress: (){
                                showModalBottomSheet(context: context, builder: (BuildContext context){
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
                              borderRadius: BorderRadius.all(Radius.circular(50.0)),
                              child: Icon(Icons.file_download),
                              onTap: () {},
                              onLongPress: (){
                                showModalBottomSheet(context: context, builder: (BuildContext context){
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
                constraints: new BoxConstraints(
                  maxHeight: 100.0
                ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Text(
                        derpi.description
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 5,
                        runSpacing: -5,
                        children: [
                          for (final tag in tags)
                            Chip(
                              padding: EdgeInsets.all(0),
                              label: Text(tag.label),
                              backgroundColor: {
                                TagType.ARTIST: Colors.blue,
                                TagType.OC: Colors.green,
                                TagType.SPOILER: Colors.red,
                              }[tag.type] ?? Colors.grey,
                            ),
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

  Future openInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}
