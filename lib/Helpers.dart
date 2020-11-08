import 'dart:math';

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

enum ESortMethod {
  SCORE_ASC,
  SCORE_DESC,
  ID_ASC,
  ID_DESC,
  FAVES_ASC,
  FAVES_DESC,
  UPVOTES_ASC,
  UPVOTES_DESC,
  RANDOM
}

List<String> sortDataFromEnum(ESortMethod method) {
  switch (method) {
    case ESortMethod.SCORE_ASC:
      return ["score", "asc"];
      break;
    case ESortMethod.SCORE_DESC:
      return ["score", "desc"];
      break;
    case ESortMethod.ID_ASC:
      return ["id", "asc"];
      break;
    case ESortMethod.ID_DESC:
      return ["id", "desc"];
      break;
    case ESortMethod.FAVES_ASC:
      return ["faves", "asc"];
      break;
    case ESortMethod.FAVES_DESC:
      return ["faves", "desc"];
      break;
    case ESortMethod.UPVOTES_ASC:
      return ["upvotes", "asc"];
      break;
    case ESortMethod.UPVOTES_DESC:
      return ["upvotes", "desc"];
      break;
    case ESortMethod.RANDOM:
      var rnd = (new Random()).nextInt(10000).toString();
      return ["random:"+rnd, "desc"];
      break;
    default:
      return [];
      break;
  }
}

enum ERepresentations {
  Full,
  Large,
  Medium,
  Small,
  Thumb,
  ThumbSmall,
  ThumbTiny
}

ERepresentations representationFromWidth(int width) {
  if (width <= 50)   return ERepresentations.ThumbTiny;
  if (width <= 150)  return ERepresentations.ThumbSmall;
  if (width <= 250)  return ERepresentations.Thumb;
  if (width <= 320)  return ERepresentations.Small;
  if (width <= 800)  return ERepresentations.Medium;
  if (width <= 1280) return ERepresentations.Large;
  return ERepresentations.Full;
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