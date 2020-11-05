import 'dart:convert';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:http/http.dart' as http;

Future<List<Derpi>> fetchDerpi(String url) async {
  final response = await http.get(url);

  if (response.statusCode == 200) {
    Iterable i = json.decode(response.body)['images'];
    if (i.length > 0) {
      List<Derpi> derpis = i.map((dynamic) => Derpi.fromJson(dynamic)).toList();
      return derpis;
    } else {
      return null;
    }
  } else {
    throw Exception('Failed to load posts');
  }
}

Future<Derpi> fetchSingleDerpi(String url) async {
  final response = await http.get(url);
  var idObject = jsonDecode(response.body);
  String imageUrl = "https://derpibooru.org/"+idObject['id']+".json";
  final imageJson = await http.get(imageUrl);
  var imageObject = jsonDecode(imageJson.body);


  return Derpi.fromJson(imageObject);
}