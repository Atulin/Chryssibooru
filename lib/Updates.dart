import 'dart:convert';

import 'package:http/http.dart' as http;

Future<ReleaseData> getNewestReleaseData() async {
  var json = await http.get('https://api.github.com/repos/Atulin/Chryssibooru/releases/latest');
  var data = jsonDecode(json.body);
  return new ReleaseData(
    data['name'],
    data['id'],
    data['tag_name'],
    data['released_at'],
    data['assets'][0]['browser_download_url']
  );
}

class ReleaseData {
  String name;
  String id;
  String version;
  DateTime publishedAt;
  String downloadUrl;

  ReleaseData(
      this.name,
      this.id,
      this.version,
      this.publishedAt,
      this.downloadUrl
  );
}