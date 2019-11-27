import 'package:chryssibooru/DerpisRepo.dart';
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
    var imageId = await ImageDownloader.downloadImage('https://'+url);
    if (imageId == null) {
      debugPrint("Image is null");
    }
  } catch (error) {
    debugPrint(error);
  }
}

enum Quality {
  Low,
  Medium,
  High,
  Source
}

String getImageOfQuality(Quality quality, DerpisRepo repo, int index) {
  switch (quality) {
    case Quality.Low:
      return repo.derpis[index].representations.small;
    case Quality.Medium:
      return repo.derpis[index].representations.medium;
    case Quality.High:
      return repo.derpis[index].representations.large;
    case Quality.Source:
      return repo.derpis[index].representations.full;
    // Default has to be there or the linter starts bitching ¯\_(ツ)_/¯
    default:
      return repo.derpis[index].representations.medium;
  }
}