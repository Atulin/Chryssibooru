import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/Enums/EQuality.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter/material.dart';

/// Repository that handles all of the fetched [Derpi]s.
class DerpisRepo extends ChangeNotifier {

  /// List of all stored [Derpi]s
  List<Derpi> derpis = new List<Derpi>();
  bool loaded = false;

  /// User's API key
  String key = "";

  /// Image ratings to include
  bool safe = true;
  bool questionable = false;
  bool explicit = false;

  /// Query to search for
  String query = "";

  /// Sorting method based on [ESortMethod]
  ESortMethod sortMethod = ESortMethod.ID_DESC;

  /// Number of the page to be fetched
  int page = 1;

  /// Load [Derpi]s according to query and filter parameters
  Future loadDerpis() async {
    loaded = false;
    final newImages = await searchImages(query, safe, questionable, explicit, key, page: page, sortMethod: sortMethod);
    if (newImages != null) {
      derpis.addAll(newImages);
      notifyListeners();
    }
    loaded = true;
  }

  /// Get the built query as string
  String getQuery() => buildQuery(query, safe, questionable, explicit, key, page: page, sortMethod: sortMethod);

  /// Set which ratings should be included
  void setRatings(bool safe, bool questionable, bool explicit) {
    this.safe = safe;
    this.questionable = questionable;
    this.explicit = explicit;
  }

  /// Search [Tag]s to search for
  void addTag(String tag) {
    List<String> tagArr = this.query.split(', ');
    tagArr.add(tag);
    this.query = tagArr.join(', ');
  }

  /// Removes a given [Tag] from query
  void removeTag(String tag) {
    List<String> tagArr = this.query.split(', ');
    tagArr.remove(tag);
    tagArr.add('-'+tag);
    this.query = tagArr.join(', ');
  }

  /// Gets one of [Representations] of the [Derpi] inside of the [DerpisRepo],
  /// based on the given [index] and [Quality]
  String getImageOfQuality(Quality quality, int index) {
    switch (quality) {
      case Quality.Low:
        return this.derpis[index].representations.small;
      case Quality.Medium:
        return this.derpis[index].representations.medium;
      case Quality.High:
        return this.derpis[index].representations.large;
      case Quality.Source:
        return this.derpis[index].representations.full;
    // Default has to be there or the linter starts bitching ¯\_(ツ)_/¯
      default:
        return this.derpis[index].representations.medium;
    }
  }
}