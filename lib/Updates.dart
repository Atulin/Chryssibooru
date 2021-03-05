import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';

Future<ReleaseData> checkForUpdates() async {
  var newest = await getNewestReleaseData();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  var current = packageInfo.version;

  if (newest.version.toString() != current) {
    return newest;
  } else {
    return null;
  }
}

Future<ReleaseData> getNewestReleaseData() async {
  var json = await http.get(Uri(path: 'https://api.github.com/repos/Atulin/Chryssibooru/releases/latest'));
  var data = jsonDecode(json.body);
  return new ReleaseData(
      data['name'],
      data['id'],
      data['tag_name'],
      DateTime.parse(data['published_at']),
      data['assets'][0]['browser_download_url']
  );
}

class ReleaseData {
  String name;
  int id;
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