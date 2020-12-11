import 'dart:math';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/Connect.dart';
import 'package:chryssibooru/Enums/ESortMethod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String buildQuery(String query, bool s, bool q, bool e, String key, {int page = 1, int limit = 30, ESortMethod sortMethod = ESortMethod.ID_DESC}) {
  const api_url = "https://derpibooru.org/api/v1/json/search/images?";

  var sortData = sortMethod.sortData();

  var ratingsArr = [];
  if (s) ratingsArr.add("safe");
  if (q) ratingsArr.add("questionable");
  if (e) ratingsArr.add("explicit");
  var ratings = ratingsArr.join(" OR ");

  var queryString = api_url + "q=" + query;

  if ( !( (s&&q&&e) || (!s&&!q&&!e) ) ) queryString += "%2C (" + ratings + ")";
  queryString += "&page="    + page.toString();
  if (key != "" || key != null) queryString += "&key="     + key;
  if (key == "" || key == null) queryString += "&per_page=" + limit.toString();
  if (sortData.length > 0 && sortData[0].isNotEmpty)
    queryString += "&sf=" + sortData[0];
  if (sortData.length > 1 && sortData[1].isNotEmpty)
    queryString += "&sd=" + sortData[1];

  var escapedQuery = queryString
      .replaceAll(", ", ",")
      .replaceAll(" ", "+");

  return escapedQuery;
}

Future<List<Derpi>> searchImages(String query, bool s, bool q, bool e, String key, {int page = 1, int limit = 30, ESortMethod sortMethod = ESortMethod.ID_DESC}) {
  var queryStr = buildQuery(query, s, q, e, key, page: page, limit: limit, sortMethod: sortMethod);
  var derpis = fetchDerpi(queryStr);
  debugPrint(derpis != null ? queryStr : 'End of results');
  return derpis;
}

Future<Derpi> getRandomImage(String query) {
  var rnd = (new Random()).nextInt(10000).toString();
  String apiUrl = "https://derpibooru.org/api/v1/json/search/images?q=";
  apiUrl += query.replaceAll(' ', '+');
  apiUrl += ',score.gt:10&sf=random:'+rnd;
  return fetchSingleDerpi(apiUrl);
}