import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_downloader/image_downloader.dart';

/// Parse the given [size] to human-readable format
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

/// Open the given [url] in default browser
Future openInBrowser(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

/// Download the image from given [url]
Future downloadImage(String url) async {
  try {
    // Saved with this method.
    var imageId = await ImageDownloader.downloadImage('https://'+url);
    if (imageId == null) {
      debugPrint("Image is null");
    }
  } catch (error) {
    debugPrint(error);
  }
}
