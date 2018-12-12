// To parse this JSON data, do
//
//     final derpibooru = derpibooruFromJson(jsonString);

import 'dart:convert';

Derpibooru derpibooruFromJson(String str) {
  final jsonData = json.decode(str);
  return Derpibooru.fromJson(jsonData);
}

String derpibooruToJson(Derpibooru data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Derpibooru {
  List<Derpi> search;
  int total;
  List<dynamic> interactions;

  Derpibooru({
    this.search,
    this.total,
    this.interactions,
  });

  factory Derpibooru.fromJson(Map<String, dynamic> json) => new Derpibooru(
    search: new List<Derpi>.from(json["search"].map((x) => Derpi.fromJson(x))),
    total: json["total"],
    interactions: new List<dynamic>.from(json["interactions"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "search": new List<dynamic>.from(search.map((x) => x.toJson())),
    "total": total,
    "interactions": new List<dynamic>.from(interactions.map((x) => x)),
  };
}

class Derpi {
  int id;
  String createdAt;
  String updatedAt;
  String firstSeenAt;
  int score;
  int commentCount;
  int width;
  int height;
  String fileName;
  String description;
  String uploader;
  int uploaderId;
  String image;
  int upvotes;
  int downvotes;
  int faves;
  String tags;
  List<int> tagIds;
  double aspectRatio;
  OriginalFormat originalFormat;
  MimeType mimeType;
  String sha512Hash;
  String origSha512Hash;
  String sourceUrl;
  Representations representations;
  bool isRendered;
  bool isOptimized;

  Derpi({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.firstSeenAt,
    this.score,
    this.commentCount,
    this.width,
    this.height,
    this.fileName,
    this.description,
    this.uploader,
    this.uploaderId,
    this.image,
    this.upvotes,
    this.downvotes,
    this.faves,
    this.tags,
    this.tagIds,
    this.aspectRatio,
    this.originalFormat,
    this.mimeType,
    this.sha512Hash,
    this.origSha512Hash,
    this.sourceUrl,
    this.representations,
    this.isRendered,
    this.isOptimized,
  });

  factory Derpi.fromJson(Map<String, dynamic> json) => new Derpi(
    id: json["id"],
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    firstSeenAt: json["first_seen_at"],
    score: json["score"],
    commentCount: json["comment_count"],
    width: json["width"],
    height: json["height"],
    fileName: json["file_name"],
    description: json["description"],
    uploader: json["uploader"],
    uploaderId: json["uploader_id"] == null ? null : json["uploader_id"],
    image: json["image"],
    upvotes: json["upvotes"],
    downvotes: json["downvotes"],
    faves: json["faves"],
    tags: json["tags"],
    tagIds: new List<int>.from(json["tag_ids"].map((x) => x)),
    aspectRatio: json["aspect_ratio"].toDouble(),
    originalFormat: originalFormatValues.map[json["original_format"]],
    mimeType: mimeTypeValues.map[json["mime_type"]],
    sha512Hash: json["sha512_hash"],
    origSha512Hash: json["orig_sha512_hash"],
    sourceUrl: json["source_url"],
    representations: Representations.fromJson(json["representations"]),
    isRendered: json["is_rendered"],
    isOptimized: json["is_optimized"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "first_seen_at": firstSeenAt,
    "score": score,
    "comment_count": commentCount,
    "width": width,
    "height": height,
    "file_name": fileName,
    "description": description,
    "uploader": uploader,
    "uploader_id": uploaderId == null ? null : uploaderId,
    "image": image,
    "upvotes": upvotes,
    "downvotes": downvotes,
    "faves": faves,
    "tags": tags,
    "tag_ids": new List<dynamic>.from(tagIds.map((x) => x)),
    "aspect_ratio": aspectRatio,
    "original_format": originalFormatValues.reverse[originalFormat],
    "mime_type": mimeTypeValues.reverse[mimeType],
    "sha512_hash": sha512Hash,
    "orig_sha512_hash": origSha512Hash,
    "source_url": sourceUrl,
    "representations": representations.toJson(),
    "is_rendered": isRendered,
    "is_optimized": isOptimized,
  };
}

enum MimeType { IMAGE_JPEG, IMAGE_PNG, VIDEO_WEBM }

final mimeTypeValues = new EnumValues({
  "image/jpeg": MimeType.IMAGE_JPEG,
  "image/png": MimeType.IMAGE_PNG,
  "video/webm": MimeType.VIDEO_WEBM
});

enum OriginalFormat { JPEG, PNG, WEBM }

final originalFormatValues = new EnumValues({
  "jpeg": OriginalFormat.JPEG,
  "png": OriginalFormat.PNG,
  "webm": OriginalFormat.WEBM
});

class Representations {
  String thumbTiny;
  String thumbSmall;
  String thumb;
  String small;
  String medium;
  String large;
  String tall;
  String full;
  String webm;
  String mp4;

  Representations({
    this.thumbTiny,
    this.thumbSmall,
    this.thumb,
    this.small,
    this.medium,
    this.large,
    this.tall,
    this.full,
    this.webm,
    this.mp4,
  });

  factory Representations.fromJson(Map<String, dynamic> json) => new Representations(
    thumbTiny: json["thumb_tiny"],
    thumbSmall: json["thumb_small"],
    thumb: json["thumb"],
    small: json["small"],
    medium: json["medium"],
    large: json["large"],
    tall: json["tall"],
    full: json["full"],
    webm: json["webm"] == null ? null : json["webm"],
    mp4: json["mp4"] == null ? null : json["mp4"],
  );

  Map<String, dynamic> toJson() => {
    "thumb_tiny": thumbTiny,
    "thumb_small": thumbSmall,
    "thumb": thumb,
    "small": small,
    "medium": medium,
    "large": large,
    "tall": tall,
    "full": full,
    "webm": webm == null ? null : webm,
    "mp4": mp4 == null ? null : mp4,
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
