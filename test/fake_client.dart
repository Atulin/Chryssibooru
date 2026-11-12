import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Decodes a JSON string for use with the model factories.
Map<String, dynamic> parseJson(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

/// A single queued response for [FakeClient].
class QueuedResponse {
  QueuedResponse(this.body, {this.status = 200, this.manual = false})
    : completer = Completer<void>();

  final String body;
  final int status;

  /// When true, the response is only released by an explicit
  /// [FakeClient.completeNext] call; otherwise it completes immediately.
  final bool manual;

  /// Completing this releases the queued response to the waiting request.
  final Completer<void> completer;
}

/// A scripted [http.Client] for tests: each queued entry is a response
/// whose completion can be controlled manually via its [Completer].
class FakeClient extends http.BaseClient {
  FakeClient([List<QueuedResponse>? queue]) : _queue = queue ?? [];

  final List<QueuedResponse> _queue;
  final List<Completer<void>> _pending = [];
  final List<Uri> requestedUrls = [];

  void enqueue(String body, {int status = 200, bool manual = false}) {
    _queue.add(QueuedResponse(body, status: status, manual: manual));
  }

  /// Completes the oldest pending (not yet completed) response.
  void completeNext() {
    final pending = _pending.firstWhere(
      (c) => !c.isCompleted,
      orElse: () => throw StateError('No pending response'),
    );
    pending.complete();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url);
    if (_queue.isEmpty) {
      throw StateError('FakeClient has no queued response for ${request.url}');
    }
    final queued = _queue.removeAt(0);
    if (queued.manual) {
      _pending.add(queued.completer);
    } else {
      queued.completer.complete();
    }
    await queued.completer.future;
    final bytes = utf8.encode(queued.body);
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      queued.status,
      contentLength: bytes.length,
    );
  }
}

/// Builds a minimal but realistic Derpibooru search response.
String searchResponseBody(List<Map<String, Object?>> images, {int total = 0}) =>
    jsonEncode({'total': total, 'images': images, 'interactions': []});

Map<String, Object?> fixtureImage({
  int id = 1,
  String mimeType = 'image/png',
  String format = 'png',
  int score = 10,
  List<String> tags = const ['chrysalis', 'artist:test'],
  Object? sourceUrl,
  Object? description = 'A description',
}) {
  final base = 'https://derpicdn.net/img/2020/1/1/$id';
  return {
    'id': id,
    'mime_type': mimeType,
    'format': format,
    'score': score,
    'upvotes': score,
    'downvotes': 0,
    'faves': 1,
    'comment_count': 0,
    'tag_count': tags.length,
    'tags': tags,
    'tag_ids': tags.map((t) => t.hashCode.abs()).toList(),
    'description': description,
    'source_url': sourceUrl,
    'spoilered': false,
    'hidden_from_users': false,
    'processed': true,
    'thumbnails_generated': true,
    'wilson_score': 0.9,
    'aspect_ratio': 1.0,
    'width': 100,
    'height': 100,
    'view_url': '$base/view.png',
    'representations': {
      'full': '$base/full.png',
      'large': '$base/large.png',
      'medium': '$base/medium.png',
      'small': '$base/small.png',
      'tall': '$base/full.png',
      'thumb': '$base/thumb.png',
      'thumb_small': '$base/thumb_small.png',
      'thumb_tiny': '$base/thumb_tiny.png',
    },
    'intensities': {'ne': 1.0, 'nw': 1.0, 'se': 1.0, 'sw': 1.0},
  };
}
