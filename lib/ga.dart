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


  GameAttributes({ required this.gameId,
    this.imgUrl,
    required this.type,
    required this.url,
    this.conceptId,
    this.addon});


  @override
  String toString() {
    return 'GameAttributes{gameId: $gameId, \n'
        'type: $type, imgUrl: $imgUrl, \n'
        'discountedValue: $discountedValue, \n'
        'url: $url,\n'
        'conceptId: $conceptId, \n'
        'addon: $addon, \n'
        '}\n';
  }

  GameAttributes.fromJson(Map<String, dynamic> json)
      : gameId = json["gameId"],
        type = json["type"],
        imgUrl = json["imgUrl"],
        discountedValue = json["discountedValue"],
        conceptId = json["conceptId"],
        addon = json["addon"],
        url = json["url"];

  Map<String, dynamic> toJson() => {
    "gameId": gameId,
    "type": type,
    "imgUrl": imgUrl,
    "discountedValue": discountedValue,
    "conceptId": conceptId,
    "addon": addon,
    "url": url,
  };
}

@HiveType(typeId: 11)
  enum GameType {
  @HiveField(0)
  PRODUCT,
  @HiveField(1)
  CONCEPT,
  @HiveField(2)
  ADD_ON
}
