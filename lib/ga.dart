import 'package:hive/hive.dart';

part 'ga.g.dart';

//export PATH="$PATH:/Users/alexandermamedov/git/flutter/bin"
//to generate adapter : flutter packages pub run build_runner build
// ./ffmpeg -i "Simulator Screen Recording - iPhone 15 Pro Max - 2024-04-22 at 13.27.50.mp4" -i "music.mp3" -c:v libx264 -crf 12 -r 30 -shortest -vf "scale=886:1920,setsar=1:1,crop=886:1920:97:0" -af "volume=0" "output.mp4"
@HiveType(typeId: 1)
class GameAttributes extends HiveObject {
  @HiveField(0)
  String gameId;
  @HiveField(1)
  GameType type;
  @HiveField(2)
  String? imgUrl;
  @HiveField(3)
  int? discountedValue;
  @HiveField(4)
  String url;
  @HiveField(5)
  String? conceptId;
  @HiveField(6)
  bool? addon;
  @HiveField(7)
  String? releaseDate;


  GameAttributes({ required this.gameId,
    this.imgUrl,
    required this.type,
    required this.url,
    this.conceptId,
    this.addon,
    this.releaseDate});


  @override
  String toString() {
    return 'GameAttributes{gameId: $gameId, \n'
        'type: $type, imgUrl: $imgUrl, \n'
        'discountedValue: $discountedValue, \n'
        'url: $url,\n'
        'conceptId: $conceptId, \n'
        'addon: $addon, \n'
        'releaseDate: $releaseDate, \n'
        '}\n';
  }

  GameAttributes.fromJson(Map<String, dynamic> json)
      : gameId = json["gameId"],
        type = json["type"],
        imgUrl = json["imgUrl"],
        discountedValue = json["discountedValue"],
        conceptId = json["conceptId"],
        addon = json["addon"],
        releaseDate = json["releaseDate"],
        url = json["url"];

  Map<String, dynamic> toJson() => {
    "gameId": gameId,
    "type": type,
    "imgUrl": imgUrl,
    "discountedValue": discountedValue,
    "conceptId": conceptId,
    "addon": addon,
    "url": url,
    "releaseDate": releaseDate,
  };
}

@HiveType(typeId: 11)
  enum GameType {
  @HiveField(0)
  PRODUCT,
  @HiveField(1)
  CONCEPT,
  @HiveField(2)
  ADD_ON,
  @HiveField(3)
  CONCEPT_PRE_ORDER
}

extension GameAttributesSql on GameAttributes {
  Map<String, Object?> toMap() => {
    'gameId': gameId,
    'type': type.name,               // PRODUCT / CONCEPT / ADD_ON
    'imgUrl': imgUrl,
    'discountedValue': discountedValue,
    'url': url,
    'conceptId': conceptId,
    'releaseDate': releaseDate,
    'addon': (addon ?? false) ? 1 : 0,
  };

  static GameAttributes fromMap(Map<String, Object?> m) {
    final t = (m['type'] as String);
    return GameAttributes(
      gameId: m['gameId'] as String,
      type: GameType.values.firstWhere((e) => e.name == t, orElse: () => GameType.PRODUCT),
      imgUrl: m['imgUrl'] as String?,
      url: m['url'] as String,
      releaseDate: m["releaseDate"] as String?,
      conceptId: m['conceptId'] as String?,
      addon: (m['addon'] as int?) == 1,
    )..discountedValue = (m['discountedValue'] as int?);
  }
}
