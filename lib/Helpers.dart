import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_downloader/image_downloader.dart';

String parseFileSize(int size) {
  if (size > 1024*1024*1024) {
    return (size/(1024*1024*1024)).toStringAsFixed(2) + " GB";
  } else if (size > 1024*1024) {
    return (size/(1024*1024)).toStringAsFixed(2) + " MB";
  } else if (size > 1024) {
    return (size/(1024)).toStringAsFixed(2) + " KB";
  } else {
    return size.toStringAsFixed(2) + " B";
  }
}


Future openInBrowser(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}


Future downloadImage(String url) async {
  try {
    // Saved with this method.
    var imageId = await ImageDownloader.downloadImage(url);
    if (imageId == null) {
      debugPrint("Image is null");
    }
  } catch (error) {
    debugPrint(error);
  }
}