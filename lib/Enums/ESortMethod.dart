import 'dart:math';

enum ESortMethod {
  SCORE_ASC,
  SCORE_DESC,
  ID_ASC,
  ID_DESC,
  FAVES_ASC,
  FAVES_DESC,
  UPVOTES_ASC,
  UPVOTES_DESC,
  RANDOM
}

extension ESortMethodExtensions on ESortMethod {
  String name() {
    switch (this) {
      case ESortMethod.SCORE_ASC:
        return 'Score \u{25B2}';
      case ESortMethod.SCORE_DESC:
        return 'Score \u{25BC}';
      case ESortMethod.ID_ASC:
        return 'ID \u{25B2}';
      case ESortMethod.ID_DESC:
        return 'ID \u{25BC}';
      case ESortMethod.FAVES_ASC:
        return 'Favourites \u{25B2}';
      case ESortMethod.FAVES_DESC:
        return 'Favourites \u{25BC}';
      case ESortMethod.UPVOTES_ASC:
        return 'Upvotes \u{25B2}';
      case ESortMethod.UPVOTES_DESC:
        return 'Upvotes \u{25BC}';
      case ESortMethod.RANDOM:
        return 'Random ⚂';
      default:
        return 'Unknown';
    }
  }

  List<String> sortData() {
    switch (this) {
      case ESortMethod.SCORE_ASC:
        return ["score", "asc"];
      case ESortMethod.SCORE_DESC:
        return ["score", "desc"];
      case ESortMethod.ID_ASC:
        return ["id", "asc"];
      case ESortMethod.ID_DESC:
        return ["id", "desc"];
      case ESortMethod.FAVES_ASC:
        return ["faves", "asc"];
      case ESortMethod.FAVES_DESC:
        return ["faves", "desc"];
      case ESortMethod.UPVOTES_ASC:
        return ["upvotes", "asc"];
      case ESortMethod.UPVOTES_DESC:
        return ["upvotes", "desc"];
      case ESortMethod.RANDOM:
        var rnd = (new Random()).nextInt(10000).toString();
        return ["random:" + rnd, "desc"];
      default:
        return [];
    }
  }
}
