// import 'package:isar/isar.dart';
//
// // export PATH="$PATH:/Users/alexandermamedov/git/flutter/bin"
// // to generate adapter : flutter packages pub run build_runner build
//
// @Collection()
// class GameAttributes{
//   //@Id()
//   int? id;
//
//   @Index(indexType: IndexType.words)
//   String? gameId;
//
//   @GameTypeConverter()
//   late GameType type;
//
//   String? imgUrl;
//
//   int? discountedValue;
//   String? url;
//
//   GameAttributes();
//
//   GameAttributes.partiallyDefined({ this.gameId, this.imgUrl, required this.type, this.url});
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
// enum GameType  {
//   PRODUCT,
//   CONCEPT
// }
//
//
// class GameTypeConverter extends TypeConverter<GameType, int> {
//   const GameTypeConverter(); // Converters need to have an empty const constructor
//
//   @override
//   GameType fromIsar(int index) {
//     return GameType.values[index];
//   }
//
//   @override
//   int toIsar(GameType type) {
//     return type.index;
//   }
// }
//
