import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer(
      {Key key, @required this.derpis, @required this.initialIndex, this.title})
      : super(key: key);

  final String title;
  final List<Derpi> derpis;
  final int initialIndex;

  @override
  _ImageViewerState createState() => _ImageViewerState(derpis, initialIndex);
}

class _ImageViewerState extends State<ImageViewer> {
  List<Derpi> derpis = new List<Derpi>();
  int initialIndex = 0;
  int _id = 0;

  _ImageViewerState(this.derpis, this.initialIndex) : super();

  PageController _controller = PageController(initialPage: 0, keepPage: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PageView.builder(
          controller: _controller,
          itemCount: derpis.length,
          itemBuilder: (BuildContext context, int id) {
            return Center(
                child: CachedNetworkImage(
                  imageUrl: "https:" + derpis[id].representations.large,
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
            Text((_id+1).toString() + '/' + derpis.length.toString())
          ],
        ),
      ),
    );
  }
}
