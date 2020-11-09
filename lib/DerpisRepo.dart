import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/API/v2/ImageList.dart';
import 'package:chryssibooru/Helpers.dart';
import 'package:flutter/material.dart';

class DerpisRepo extends ChangeNotifier {
  List<Derpi> derpis = new List<Derpi>();
  bool loaded = false;

  String key = "";

  bool safe = true;
  bool questionable = false;
  bool explicit = false;

  String query = "";

  ESortMethod sortMethod = ESortMethod.ID_DESC;

  int page = 1;

  Future loadDerpis() async {
    loaded = false;
    final newImages = await searchImages(query, safe, questionable, explicit, key, page: page, sortMethod: sortMethod);
    if (newImages != null) {
      derpis.addAll(newImages);
      notifyListeners();
    }
    loaded = true;
  }

  String getQuery() => buildQuery(query, safe, questionable, explicit, key, page: page, sortMethod: sortMethod);


  void setRatings(bool safe, bool questionable, bool explicit) {
    this.safe = safe;
    this.questionable = questionable;
    this.explicit = explicit;
  }

  void addTag(String tag) {
    List<String> tagArr = this.query.split(', ');
    tagArr.add(tag);
    this.query = tagArr.join(', ');
  }

  void removeTag(String tag) {
    List<String> tagArr = this.query.split(', ');
    tagArr.remove(tag);
    tagArr.add('-'+tag);
    this.query = tagArr.join(', ');
  }
}