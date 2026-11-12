// Low-level transport for the Derpibooru API.

import 'dart:convert';

import 'package:chryssibooru/API/v2/API.dart';
import 'package:http/http.dart' as http;

/// The HTTP client used for all API calls. Exposed so tests can install a
/// fake client; production code always uses the default.
http.Client apiHttpClient = http.Client();

Future<Map<String, dynamic>?> _fetchJson(String url) async {
  try {
    final response = await apiHttpClient.get(Uri.parse(url));
    if (response.statusCode != 200) {
      // Don't log the full URL here: it can contain the user's API key.
      return null;
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Fetches a page of search results. Returns `null` when the request
/// failed (network error, non-200 response), and an empty list when the
/// response contained no images.
Future<List<Derpi>?> fetchDerpi(String url) async {
  final data = await _fetchJson(url);
  if (data == null) return null;

  return Derpibooru.fromJson(data).images;
}

/// Fetches a single image entry. Returns `null` when the request failed.
Future<Derpi?> fetchSingleDerpi(String url) async {
  final data = await _fetchJson(url);
  if (data == null) return null;

  final images = data['images'];
  if (images is List &&
      images.isNotEmpty &&
      images.first is Map<String, dynamic>) {
    return Derpi.fromJson(images.first as Map<String, dynamic>);
  }
  return null;
}
