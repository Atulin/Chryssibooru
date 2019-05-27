import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget{
  ImageViewer({Key key, this.title}) : super (key: key);

  final String title;

  @override
  _ImageViewerState createState() => _ImageViewerState();

}

class _ImageViewerState extends State<ImageViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text ("Hello"),
    );
  }
}