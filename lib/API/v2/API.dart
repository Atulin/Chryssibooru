// To parse this JSON data, do
//
//     final derpibooru = derpibooruFromJson(jsonString);

import 'dart:convert';

import 'package:chryssibooru/Helpers.dart';

Derpibooru derpibooruFromJson(String str) {
  final jsonData = json.decode(str);
  return Derpibooru.fromJson(jsonData);
}

String derpibooruToJson(Derpibooru data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Derpibooru {
  List<Derpi> images;
  List<dynamic> interactions;
  int total;

  Derpibooru({
    this.images,
    this.interactions,
    this.total,
  });

  factory Derpibooru.fromRawJson(String str) => Derpibooru.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Derpibooru.fromJson(Map<String, dynamic> json) => Derpibooru(
    images: List<Derpi>.from(json["images"].map((x) => Derpi.fromJson(x))),
    interactions: List<dynamic>.from(json["interactions"].map((x) => x)),
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "images": List<dynamic>.from(images.map((x) => x.toJson())),
    "interactions": List<dynamic>.from(interactions.map((x) => x)),
    "total": total,
  };
}

class Derpi {
  Format format;
  String origSha512Hash;
  DateTime firstSeenAt;
  double wilsonScore;
  int uploaderId;
  int upvotes;
  int duplicateOf;
  String description;
  String viewUrl;
  String sourceUrl;
  DateTime updatedAt;
  List<Tag> tags;
  int downvotes;
  int commentCount;
  Representations representations;
  int score;
  int width;
  String deletionReason;
  int height;
  bool spoilered;
  int faves;
  bool processed;
  Intensities intensities;
  String uploader;
  double aspectRatio;
  int tagCount;
  List<int> tagIds;
  int id;
  bool thumbnailsGenerated;
  bool hiddenFromUsers;
  MimeType mimeType;
  String name;
  DateTime createdAt;
  String sha512Hash;

  Derpi({
    this.format,
    this.origSha512Hash,
    this.firstSeenAt,
    this.wilsonScore,
    this.uploaderId,
    this.upvotes,
    this.duplicateOf,
    this.description,
    this.viewUrl,
    this.sourceUrl,
    this.updatedAt,
    this.tags,
    this.downvotes,
    this.commentCount,
    this.representations,
    this.score,
    this.width,
    this.deletionReason,
    this.height,
    this.spoilered,
    this.faves,
    this.processed,
    this.intensities,
    this.uploader,
    this.aspectRatio,
    this.tagCount,
    this.tagIds,
    this.id,
    this.thumbnailsGenerated,
    this.hiddenFromUsers,
    this.mimeType,
    this.name,
    this.createdAt,
    this.sha512Hash,
  });

  factory Derpi.fromRawJson(String str) => Derpi.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Derpi.fromJson(Map<String, dynamic> json) => Derpi(
    format: formatValues.map[json["format"]],
    origSha512Hash: json["orig_sha512_hash"],
    firstSeenAt: DateTime.parse(json["first_seen_at"]),
    wilsonScore: json["wilson_score"].toDouble(),
    uploaderId: json["uploader_id"] == null ? null : json["uploader_id"],
    upvotes: json["upvotes"],
    duplicateOf: json["duplicate_of"],
    description: json["description"],
    viewUrl: json["view_url"],
    sourceUrl: json["source_url"] == null ? null : json["source_url"],
    updatedAt: DateTime.parse(json["updated_at"]),
    tags: Tag.parse(List<String>.from(json["tags"])),
    downvotes: json["downvotes"],
    commentCount: json["comment_count"],
    representations: Representations.fromJson(json["representations"]),
    score: json["score"],
    width: json["width"],
    deletionReason: json["deletion_reason"],
    height: json["height"],
    spoilered: json["spoilered"],
    faves: json["faves"],
    processed: json["processed"],
    intensities: Intensities.fromJson(json["intensities"]),
    uploader: json["uploader"] == null ? null : json["uploader"],
    aspectRatio: json["aspect_ratio"].toDouble(),
    tagCount: json["tag_count"],
    tagIds: List<int>.from(json["tag_ids"].map((x) => x)),
    id: json["id"],
    thumbnailsGenerated: json["thumbnails_generated"],
    hiddenFromUsers: json["hidden_from_users"],
    mimeType: mimeTypeValues.map[json["mime_type"]],
    name: json["name"],
    createdAt: DateTime.parse(json["created_at"]),
    sha512Hash: json["sha512_hash"],
  );

  Map<String, dynamic> toJson() => {
    "format": formatValues.reverse[format],
    "orig_sha512_hash": origSha512Hash,
    "first_seen_at": firstSeenAt.toIso8601String(),
    "wilson_score": wilsonScore,
    "uploader_id": uploaderId == null ? null : uploaderId,
    "upvotes": upvotes,
    "duplicate_of": duplicateOf,
    "description": description,
    "view_url": viewUrl,
    "source_url": sourceUrl == null ? null : sourceUrl,
    "updated_at": updatedAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((x) => x)),
    "downvotes": downvotes,
    "comment_count": commentCount,
    "representations": representations.toJson(),
    "score": score,
    "width": width,
    "deletion_reason": deletionReason,
    "height": height,
    "spoilered": spoilered,
    "faves": faves,
    "processed": processed,
    "intensities": intensities.toJson(),
    "uploader": uploader == null ? null : uploader,
    "aspect_ratio": aspectRatio,
    "tag_count": tagCount,
    "tag_ids": List<dynamic>.from(tagIds.map((x) => x)),
    "id": id,
    "thumbnails_generated": thumbnailsGenerated,
    "hidden_from_users": hiddenFromUsers,
    "mime_type": mimeTypeValues.reverse[mimeType],
    "name": name,
    "created_at": createdAt.toIso8601String(),
    "sha512_hash": sha512Hash,
  };
}

enum Format { PNG, JPG }

final formatValues = EnumValues({
  "jpg": Format.JPG,
  "png": Format.PNG
});

class Intensities {
  double ne;
  double nw;
  double se;
  double sw;

  Intensities({
    this.ne,
    this.nw,
    this.se,
    this.sw,
  });

  factory Intensities.fromRawJson(String str) => Intensities.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Intensities.fromJson(Map<String, dynamic> json) => Intensities(
    ne: json["ne"].toDouble(),
    nw: json["nw"].toDouble(),
    se: json["se"].toDouble(),
    sw: json["sw"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "ne": ne,
    "nw": nw,
    "se": se,
    "sw": sw,
  };
}

enum MimeType { IMAGE_PNG, IMAGE_JPEG, VIDEO_WEBM, VIDEO_MP4 }

final mimeTypeValues = EnumValues({
  "image/jpeg": MimeType.IMAGE_JPEG,
  "image/png":  MimeType.IMAGE_PNG,
  "video/webm": MimeType.VIDEO_WEBM,
  "video/mp4":  MimeType.VIDEO_MP4
});

class Representations {
  String full;
  String large;
  String medium;
  String small;
  String tall;
  String thumb;
  String thumbSmall;
  String thumbTiny;

  Representations({
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
        return this.full;
        break;
      case ERepresentations.Large:
        return this.large;
        break;
      case ERepresentations.Medium:
        return this.medium;
        break;
      case ERepresentations.Small:
        return this.small;
        break;
      case ERepresentations.Thumb:
        return this.thumb;
        break;
      case ERepresentations.ThumbSmall:
        return this.thumbSmall;
        break;
      case ERepresentations.ThumbTiny:
        return this.thumbTiny;
        break;
      default:
        return this.thumbTiny;
        break;
    }
  }

  factory Representations.fromRawJson(String str) => Representations.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Representations.fromJson(Map<String, dynamic> json) => Representations(
    full: json["full"],
    large: json["large"],
    medium: json["medium"],
    small: json["small"],
    tall: json["tall"],
    thumb: json["thumb"],
    thumbSmall: json["thumb_small"],
    thumbTiny: json["thumb_tiny"],
  );

  Map<String, dynamic> toJson() => {
    "full": full,
    "large": large,
    "medium": medium,
    "small": small,
    "tall": tall,
    "thumb": thumb,
    "thumb_small": thumbSmall,
    "thumb_tiny": thumbTiny,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}

enum TagType { ARTIST, SPOILER, OC }

final tagTypeValues = new EnumValues({
  "artist": TagType.ARTIST,
  "spoiler": TagType.SPOILER,
  "oc": TagType.OC
});

class Tag {
  TagType type;
  String label;

  Tag(String tag) {
    var splitTag = tag.split(':');
    if (splitTag.length >= 2) {
      this.type = tagTypeValues.map[splitTag[0]];
      this.label = tag;
    } else {
      this.label = tag;
    }
  }

  static List<Tag> parse(List<String> tags) {
    List<Tag> outTags = new List<Tag>();
    outTags = tags.map((x) => new Tag(x)).toList();
    return outTags;
  }
}