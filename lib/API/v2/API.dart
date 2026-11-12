// Typed models for the Derpibooru API (v1 JSON) responses.
//
// Parsing is deliberately tolerant: missing, null, or malformed fields
// degrade to safe defaults instead of throwing, so a single bad image in
// a search response cannot break the whole grid.

import 'dart:convert';

import 'package:chryssibooru/Enums/ERepresentations.dart';

Derpibooru derpibooruFromJson(String str) =>
    Derpibooru.fromJson(json.decode(str));

/// A single page of search results.
class Derpibooru {
  final List<Derpi> images;
  final int total;

  const Derpibooru({required this.images, required this.total});

  factory Derpibooru.fromJson(Map<String, dynamic> json) => Derpibooru(
    images: ((json['images'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Derpi.fromJson)
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

/// A single image (or video) entry.
class Derpi {
  final Format? format;
  final String? origSha512Hash;
  final DateTime? firstSeenAt;
  final double? wilsonScore;
  final int? uploaderId;
  final int upvotes;
  final int? duplicateOf;
  final String? description;
  final String viewUrl;
  final String? sourceUrl;
  final DateTime? updatedAt;
  final List<Tag> tags;
  final int downvotes;
  final int commentCount;
  final Representations representations;
  final int score;
  final int? width;
  final String? deletionReason;
  final int? height;
  final bool spoilered;
  final int faves;
  final bool processed;
  final Intensities? intensities;
  final String? uploader;
  final double? aspectRatio;
  final int? tagCount;
  final List<int> tagIds;
  final int id;
  final bool thumbnailsGenerated;
  final bool hiddenFromUsers;
  final MimeType? mimeType;
  final String? name;
  final DateTime? createdAt;
  final String? sha512Hash;

  const Derpi({
    this.format,
    this.origSha512Hash,
    this.firstSeenAt,
    this.wilsonScore,
    this.uploaderId,
    this.upvotes = 0,
    this.duplicateOf,
    this.description,
    this.viewUrl = '',
    this.sourceUrl,
    this.updatedAt,
    this.tags = const [],
    this.downvotes = 0,
    this.commentCount = 0,
    this.representations = const Representations(),
    this.score = 0,
    this.width,
    this.deletionReason,
    this.height,
    this.spoilered = false,
    this.faves = 0,
    this.processed = false,
    this.intensities,
    this.uploader,
    this.aspectRatio,
    this.tagCount,
    this.tagIds = const [],
    this.id = 0,
    this.thumbnailsGenerated = false,
    this.hiddenFromUsers = false,
    this.mimeType,
    this.name,
    this.createdAt,
    this.sha512Hash,
  });

  factory Derpi.fromJson(Map<String, dynamic> json) => Derpi(
    format: _enumFromJson(Format.values, _formatNames, json['format']),
    origSha512Hash: json['orig_sha512_hash'] as String?,
    firstSeenAt: _dateFromJson(json['first_seen_at']),
    wilsonScore: (json['wilson_score'] as num?)?.toDouble(),
    uploaderId: (json['uploader_id'] as num?)?.toInt(),
    upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
    duplicateOf: (json['duplicate_of'] as num?)?.toInt(),
    description: json['description'] as String?,
    viewUrl: json['view_url'] as String? ?? '',
    sourceUrl: json['source_url'] as String?,
    updatedAt: _dateFromJson(json['updated_at']),
    tags: Tag.parse(((json['tags'] as List?) ?? const []).whereType<String>()),
    downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
    commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    representations: json['representations'] is Map<String, dynamic>
        ? Representations.fromJson(json['representations'])
        : const Representations(),
    score: (json['score'] as num?)?.toInt() ?? 0,
    width: (json['width'] as num?)?.toInt(),
    deletionReason: json['deletion_reason'] as String?,
    height: (json['height'] as num?)?.toInt(),
    spoilered: json['spoilered'] as bool? ?? false,
    faves: (json['faves'] as num?)?.toInt() ?? 0,
    processed: json['processed'] as bool? ?? false,
    intensities: json['intensities'] is Map<String, dynamic>
        ? Intensities.fromJson(json['intensities'])
        : null,
    uploader: json['uploader'] as String?,
    aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
    tagCount: (json['tag_count'] as num?)?.toInt(),
    tagIds: ((json['tag_ids'] as List?) ?? const [])
        .whereType<num>()
        .map((x) => x.toInt())
        .toList(),
    id: (json['id'] as num?)?.toInt() ?? 0,
    thumbnailsGenerated: json['thumbnails_generated'] as bool? ?? false,
    hiddenFromUsers: json['hidden_from_users'] as bool? ?? false,
    mimeType: _enumFromJson(MimeType.values, _mimeTypeNames, json['mime_type']),
    name: json['name'] as String?,
    createdAt: _dateFromJson(json['created_at']),
    sha512Hash: json['sha512_hash'] as String?,
  );

  /// True when this entry is a video that needs a player.
  bool get isVideo =>
      mimeType == MimeType.VIDEO_WEBM || mimeType == MimeType.VIDEO_MP4;
}

DateTime? _dateFromJson(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  // Philomena may also send integer timestamps (seconds since epoch).
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * 1000,
      isUtc: true,
    );
  }
  return null;
}

T? _enumFromJson<T extends Enum>(
  List<T> values,
  Map<String, T> names,
  Object? raw,
) {
  if (raw is String) {
    final name = raw.toLowerCase().trim();
    if (names.containsKey(name)) return names[name];
  }
  return null;
}

const Map<String, Format> _formatNames = {
  'jpg': Format.JPG,
  'jpeg': Format.JPG,
  'png': Format.PNG,
  'gif': Format.GIF,
  'webm': Format.WEBM,
  'mp4': Format.MP4,
  'svg': Format.SVG,
};

const Map<String, MimeType> _mimeTypeNames = {
  'image/jpeg': MimeType.IMAGE_JPEG,
  'image/gif': MimeType.IMAGE_GIF,
  'image/png': MimeType.IMAGE_PNG,
  'image/svg+xml': MimeType.IMAGE_SVG,
  'video/webm': MimeType.VIDEO_WEBM,
  'video/mp4': MimeType.VIDEO_MP4,
};

enum Format { JPG, PNG, GIF, WEBM, MP4, SVG }

class Intensities {
  final double ne;
  final double nw;
  final double se;
  final double sw;

  const Intensities({this.ne = 0, this.nw = 0, this.se = 0, this.sw = 0});

  factory Intensities.fromJson(Map<String, dynamic> json) => Intensities(
    ne: (json['ne'] as num?)?.toDouble() ?? 0,
    nw: (json['nw'] as num?)?.toDouble() ?? 0,
    se: (json['se'] as num?)?.toDouble() ?? 0,
    sw: (json['sw'] as num?)?.toDouble() ?? 0,
  );
}

enum MimeType {
  IMAGE_PNG,
  IMAGE_JPEG,
  IMAGE_GIF,
  IMAGE_SVG,
  VIDEO_WEBM,
  VIDEO_MP4,
}

class Representations {
  final String? full;
  final String? large;
  final String? medium;
  final String? small;
  final String? tall;
  final String? thumb;
  final String? thumbSmall;
  final String? thumbTiny;

  const Representations({
    this.full,
    this.large,
    this.medium,
    this.small,
    this.tall,
    this.thumb,
    this.thumbSmall,
    this.thumbTiny,
  });

  String fromEnum(ERepresentations representation) {
    switch (representation) {
      case ERepresentations.Full:
        return full ?? '';
      case ERepresentations.Large:
        return large ?? '';
      case ERepresentations.Medium:
        return medium ?? '';
      case ERepresentations.Small:
        return small ?? '';
      case ERepresentations.Thumb:
        return thumb ?? '';
      case ERepresentations.ThumbSmall:
        return thumbSmall ?? '';
      case ERepresentations.ThumbTiny:
        return thumbTiny ?? '';
    }
  }

  factory Representations.fromJson(Map<String, dynamic> json) =>
      Representations(
        full: json['full'] as String?,
        large: json['large'] as String?,
        medium: json['medium'] as String?,
        small: json['small'] as String?,
        tall: json['tall'] as String?,
        thumb: json['thumb'] as String?,
        thumbSmall: json['thumb_small'] as String?,
        thumbTiny: json['thumb_tiny'] as String?,
      );
}

enum TagType {
  ARTIST,
  SPOILER,
  OC,
  AUTHOR,
  CONTENT,
  ERROR,
  CHARACTER,
  SPECIES,
  ORIGIN,
  EPISODE,
}

const Map<String, TagType> _tagTypeNames = {
  'artist': TagType.ARTIST,
  'spoiler': TagType.SPOILER,
  'oc': TagType.OC,
  'author': TagType.AUTHOR,
  'content': TagType.CONTENT,
  'error': TagType.ERROR,
  'character': TagType.CHARACTER,
  'species': TagType.SPECIES,
  'origin': TagType.ORIGIN,
  'episode': TagType.EPISODE,
};

class Tag {
  final TagType? type;
  final String label;

  const Tag(this.label, {this.type});

  static List<Tag> parse(Iterable<String> tags) => tags.map((label) {
    final colon = label.indexOf(':');
    if (colon > 0) {
      final prefix = label.substring(0, colon).toLowerCase();
      final type = _tagTypeNames[prefix];
      if (type != null) return Tag(label, type: type);
    }
    return Tag(label);
  }).toList();
}
