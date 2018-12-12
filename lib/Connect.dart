import 'dart:convert';

import 'package:chryssibooru/API.dart';
import 'package:http/http.dart' as http;

Future<List<Derpi>> fetchDerpi(url) async {
  final response = await http.get(url);

  if (response.statusCode == 200) {
    Iterable i = json.decode(response.body)['search'];
    List<Derpi> derpis = i.map((dynamic) => Derpi.fromJson(dynamic)).toList();
    return derpis;// Derpi.fromJson(json.decode(response.body)['search']);
  } else {
    throw Exception('Failed to load posts');
  }
}