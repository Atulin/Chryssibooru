import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer({Key key, this.title}) : super(key: key);

  final String title;

  @override
  ImageViewerState createState() => ImageViewerState();
}

class ImageViewerState extends State<ImageViewer> {
  List<Derpi> derpis = new List<Derpi>();
  int initialIndex = 0;
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
    _pageController = PageController();
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
                    return new CachedNetworkImage(
                      imageUrl:"https:" + repo.derpis[index].representations.medium,
                      placeholder: (context, url) => new Image(image: AssetImage('assets/logo-medium.png')),
                      errorWidget: (context, url, error) => new Icon(Icons.error),
                      fit: BoxFit.contain,
                    );
                  } else {
                    return new Center(
                      child: Text('WEBM'),
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
            padding: EdgeInsets.symmetric(horizontal: 5.0),
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
          showModalBottomSheet(context: context, builder: (BuildContext context){
            Derpi derpi = repo.derpis[_id];
            List<Tag> tags = derpi.tags;
            return Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Uploader: ' + derpi.uploader),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SingleChildScrollView(
                      child: GestureDetector(
                        onTap: (){},
                        child: Text(
                          derpi.description,
                          maxLines: descMaxLines,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 5.0,
                        runSpacing: 5.0,
                        children: List.generate(derpi.tags.length, (i){
                            return new Chip(
                              padding: EdgeInsets.all(0.0),
                              label: Text(tags[i].label),
                              backgroundColor: (){
                                switch (tags[i].type){
                                  case TagType.ARTIST:
                                    return Color.fromARGB(255, 0, 0, 255);
                                    break;
                                  case TagType.OC:
                                    return Color.fromARGB(255, 0, 255, 0);
                                    break;
                                  case TagType.SPOILER:
                                    return Color.fromARGB(255, 255, 0, 0);
                                    break;
                                  default:
                                    return Color.fromARGB(255, 150, 150, 150);
                                    break;
                                }
                              }(),
                            );
                          }),
                      ),
                    ),
                  )
                ],
              ),
            );
          });
        },
      ),
    );
  }
}
