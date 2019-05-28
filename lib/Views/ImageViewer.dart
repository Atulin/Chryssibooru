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
          itemBuilder: (BuildContext context, int id) {
            return Center(
                child: CachedNetworkImage(
                  imageUrl: "https:" + repo.derpis[id].representations.large,
                  placeholder: (context, url) => new Image(image: AssetImage('assets/logo-medium.png')),
                  errorWidget: (context, url, error) => new Icon(Icons.error),
                  fit: BoxFit.contain,
                )
            );
          },
          onPageChanged: (pageId) {
            setState(() {
              _id = pageId.round();
            });
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            Text((_id+1).toString() + '/' + repo.derpis.length.toString())
          ],
        ),
      ),
    );
  }
}
