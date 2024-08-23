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
  String imgUrl;
  @HiveField(3)
  int? discountedValue;
  @HiveField(4)
  String url;


  GameAttributes({ required this.gameId,
    required this.imgUrl,
    required this.type,
    required this.url});


  @override
  String toString() {
    return 'GameAttributes{gameId: $gameId, type: $type, imgUrl: $imgUrl, discountedValue: $discountedValue, url: $url}';
  }

  GameAttributes.fromJson(Map<String, dynamic> json)
      : gameId = json["gameId"],
        type = json["type"],
        imgUrl = json["imgUrl"],
        discountedValue = json["discountedValue"],
        url = json["url"];

  Map<String, dynamic> toJson() => {
    "gameId": gameId,
    "type": type,
    "imgUrl": imgUrl,
    "discountedValue": discountedValue,
    "url": url,
  };
}

@HiveType(typeId: 11)
  enum GameType {
  @HiveField(0)
  PRODUCT,
  @HiveField(1)
  CONCEPT
}
