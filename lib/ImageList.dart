import 'package:chryssibooru/API.dart';
import 'package:chryssibooru/Connect.dart';
import 'package:flutter/foundation.dart';


Future<List<Derpi>> searchImages(String query, bool s, bool q, bool e, [int page = 1]) {
  const api_url = "https://derpibooru.org/search.json?";

  var ratingsArr = [];
  if (s) ratingsArr.add("safe");
  if (q) ratingsArr.add("questionable");
  if (e) ratingsArr.add("explicit");
  var ratings = ratingsArr.join(" OR ");

  var escapedQuery = query.replaceAll(" ", "+");

  var queryString = api_url + "q=" + escapedQuery + ", " + ratings + "&page=" + page.toString();

  debugPrint(queryString);

  return fetchDerpi(queryString);
}
