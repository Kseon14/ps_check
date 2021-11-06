// import 'package:objectbox/objectbox.dart';
//
//
//
// // export PATH="$PATH:/Users/alexandermamedov/git/flutter/bin"
// // to generate adapter : flutter packages pub run build_runner build
//
// @Entity()
// class GameAttributes{
//   //@Id()
//   int id;
//
//   String gameId;
//
//   // @Transient()
//   // GameType type;
//
//   int index;
//
//   String imgUrl;
//
//   int discountedValue;
//   String url;
//
//   GameAttributes({this.gameId, this.imgUrl, this.index, this.url});
//
//
//   // set typeDb(int index) {
//   //   type = index != null ? GameType.values[index] : null;
//   // }
//   //
//   // int get typeDb {
//   //   return type != null ? type.index : null;
//   // }
//
//   // @override
//   // String toString() {
//   //   return 'GameAttributes{gameId: $gameId, type: $type, imgUrl: $imgUrl, discountedValue: $discountedValue, url: $url}';
//   // }
//
//   // GameAttributesOB.fromJson(Map<String, dynamic> json)
//   //     : gameId = json["gameId"],
//   //       type = json["type"],
//   //       imgUrl = json["imgUrl"],
//   //       discountedValue = json["discountedValue"],
//   //       url = json["url"];
//   //
//   // Map<String, dynamic> toJson() => {
//   //   "gameId": gameId,
//   //   "type": type,
//   //   "imgUrl": imgUrl,
//   //   "discountedValue": discountedValue,
//   //   "url": url,
//   // };
//
//
// }
//
//
//
//
//
