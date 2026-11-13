import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Parse the given [size] to human-readable format
String parseFileSize(int size) {
  if (size > 1024 * 1024 * 1024) {
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } else if (size > 1024 * 1024) {
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else if (size > 1024) {
    return '${(size / 1024).toStringAsFixed(2)} KB';
  } else {
    return '${size.toStringAsFixed(2)} B';
  }
}

/// Open the given [url] in default browser. Returns true on success.
Future<bool> openInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Download the image from given [url] and save it to the device gallery.
///
/// Returns a user-facing result message. Saving is supported on Android
/// and iOS; on other platforms a notice is returned instead.
Future<String> downloadImage(String url) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return 'Saving images is not supported on this platform';
  }
  try {
    final uri = url.startsWith('http')
        ? Uri.parse(url)
        : Uri.parse('https://$url');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return 'Download failed (HTTP ${response.statusCode})';
    }
    await Gal.putImageBytes(
      response.bodyBytes,
      name: 'chryssibooru-${DateTime.now().millisecondsSinceEpoch}',
    );
    return 'Image saved to gallery';
  } on GalException catch (e) {
    debugPrint('Gallery save failed: ${e.type.name}');
    return e.type == GalExceptionType.permissionDenied
        ? 'Permission denied – grant gallery access and try again'
        : 'Saving image failed';
  } catch (e) {
    debugPrint('Image download failed: $e');
    return 'Image download failed';
  }
}
