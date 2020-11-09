import 'dart:convert';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

Future<List<Derpi>> fetchDerpi(String url) async {
  final response = await http.get(url);
  var logger = Logger();

  if (response.statusCode == 200) {
    Iterable i = json.decode(response.body)['images'];
    if (i.length > 0) {
      List<Derpi> derpis = i.map((dynamic) => Derpi.fromJson(dynamic)).toList();
      return derpis;
    } else {
      logger.i("No images found");
      return null;
    }
  } else {
    logger.e({
      'code': response.statusCode,
      'body': response.body
    });
    return null;
  }
}

Future<Derpi> fetchSingleDerpi(String url) async {
  final response = await http.get(url);
  var idObject = jsonDecode(response.body);
  return Derpi.fromJson(idObject['images'][0]);
}