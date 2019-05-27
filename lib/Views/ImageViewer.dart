import 'package:cached_network_image/cached_network_image.dart';
import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/DerpisRepo.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
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
