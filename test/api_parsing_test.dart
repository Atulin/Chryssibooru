import 'package:chryssibooru/API/v2/API.dart';
import 'package:chryssibooru/Enums/ERepresentations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_client.dart';

void main() {
  test('parses a complete image entry', () {
    final body = searchResponseBody([fixtureImage(id: 42, score: 15)]);
    final images = Derpibooru.fromJson(parseJson(body)).images;

    expect(images, hasLength(1));
    final derpi = images.single;
    expect(derpi.id, 42);
    expect(derpi.score, 15);
    expect(derpi.mimeType, MimeType.IMAGE_PNG);
    expect(derpi.format, Format.PNG);
    expect(derpi.isVideo, isFalse);
    expect(derpi.viewUrl, 'https://derpicdn.net/img/2020/1/1/42/view.png');
    expect(
      derpi.representations.medium,
      'https://derpicdn.net/img/2020/1/1/42/medium.png',
    );
    expect(derpi.description, 'A description');
    expect(derpi.tags.map((t) => t.label), contains('chrysalis'));
    expect(derpi.upvotes, 15);
    expect(derpi.downvotes, 0);
    expect(derpi.faves, 1);
  });

  test('parses a video entry', () {
    final body = searchResponseBody([
      fixtureImage(id: 7, mimeType: 'video/webm', format: 'webm'),
    ]);
    final derpi = Derpibooru.fromJson(parseJson(body)).images.single;

    expect(derpi.isVideo, isTrue);
    expect(derpi.mimeType, MimeType.VIDEO_WEBM);
  });

  test('recognizes tag types', () {
    final body = searchResponseBody([
      fixtureImage(tags: ['artist:foo', 'spoiler:bar', 'oc:baz', 'plain tag']),
    ]);
    final tags = Derpibooru.fromJson(parseJson(body)).images.single.tags;

    expect(tags[0].type, TagType.ARTIST);
    expect(tags[1].type, TagType.SPOILER);
    expect(tags[2].type, TagType.OC);
    expect(tags[3].type, isNull);
  });

  test('tolerates missing and malformed fields', () {
    final body = '''
    {
      "total": 1,
      "images": [
        {
          "id": 5,
          "mime_type": "image/png",
          "score": null,
          "upvotes": null,
          "downvotes": null,
          "faves": null,
          "comment_count": null,
          "spoilered": null,
          "tags": null,
          "tag_ids": null,
          "representations": {},
          "intensities": null,
          "created_at": "garbage-date",
          "first_seen_at": null,
          "updated_at": 1700000000,
          "uploader": null,
          "source_url": null,
          "description": null,
          "aspect_ratio": null
        }
      ],
      "interactions": null
    }''';
    final derpi = Derpibooru.fromJson(parseJson(body)).images.single;

    expect(derpi.id, 5);
    expect(derpi.score, 0);
    expect(derpi.upvotes, 0);
    expect(derpi.spoilered, isFalse);
    expect(derpi.tags, isEmpty);
    expect(derpi.tagIds, isEmpty);
    expect(derpi.description, isNull);
    expect(derpi.createdAt, isNull);
    expect(derpi.updatedAt, isNotNull);
    expect(derpi.representations.fromEnum(ERepresentations.Thumb), '');
  });

  test('tolerates empty and malformed payloads', () {
    expect(
      Derpibooru.fromJson(parseJson('{"images": null, "total": null}')).images,
      isEmpty,
    );
    expect(Derpibooru.fromJson(parseJson('{}')).images, isEmpty);

    // Non-map image entries are skipped, not thrown on.
    final body = '{"total": 2, "images": [42, {"id": 1}], "interactions": []}';
    expect(Derpibooru.fromJson(parseJson(body)).images.map((d) => d.id), [1]);
  });

  test('unknown format and mime values fall back to null', () {
    final body = searchResponseBody([
      {
        'id': 9,
        'mime_type': 'image/avif',
        'format': 'avif',
        'representations': {'full': 'https://derpicdn.net/x/full.avif'},
      },
    ]);
    final derpi = Derpibooru.fromJson(parseJson(body)).images.single;
    expect(derpi.mimeType, isNull);
    expect(derpi.format, isNull);
    expect(derpi.representations.full, 'https://derpicdn.net/x/full.avif');
  });
}
