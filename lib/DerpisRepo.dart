import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/ImageList.dart';
import 'package:flutter/material.dart';

class DerpisRepo extends ChangeNotifier {
  List<Derpi> derpis = new List<Derpi>();
  bool loaded = false;

  String key = "";

  bool safe = true;
  bool questionable = false;
  bool explicit = false;

  String query = "";

  int page = 1;

  void loadDerpis() async {
    loaded = false;
    final newImages = await searchImages(query, safe, questionable, explicit, key, page);
    if (newImages != null) {
      derpis.addAll(newImages);
      notifyListeners();
    }
    loaded = true;
  }
}