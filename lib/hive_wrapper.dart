import 'dart:io';

import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import 'ga.dart';

class HiveWrapper{
  var boxName= 'game-box';
  Box<GameAttributes>? box;
  static HiveWrapper hiveInternal = HiveWrapper();
  static var lock = Lock();

  static HiveWrapper instance(){
    return hiveInternal;
  }

  init() async{
    await lock.synchronized(() async {
      if (box == null) {
        print("box is null");
        //openIfNotOpened();
        await Hive.initFlutter();
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(GameAttributesAdapter());
        }
        if (!Hive.isAdapterRegistered(11)) {
          Hive.registerAdapter(GameTypeAdapter());
        }
        try {
          box = await Hive.openBox<GameAttributes>(boxName);
        } on HiveError {
          // If we come here, we have probably a Hive box corrupted for some reasons.
          // We found that some null values are added randomly at the begining of the .hive file.
          // This is why the file is considered as corrupted.
          // To fix this we remove these null values.
          //final Directory documentDirectory = await getApplicationDocumentsDirectory();

          // We get the corrupted box file.
          // final boxPath = path.join(
          //   documentDirectory.path,
          //   _localDataDirectory,
          //   '$boxName.hive',
          // );
          var dir = await getApplicationDocumentsDirectory();
          String dirPath = dir.path;

          String boxName = this.boxName.toLowerCase();

          File boxFile = File('$dirPath/$boxName.hive');

          //final boxFile = File(boxPath);

          // We read the corrupted content.
          final corruptedContent = await boxFile.readAsBytes();

          // We remove the null elements symbolyzed by the first sequence of 0 values. (ex: [0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 1, 21, 112, 101, 114, 109, 105, 115, 115, 105, ...])
          final correctedContent = corruptedContent.skipWhile(
                (value) => value == 0,
          );
          // We save the new content in the file
          await boxFile.writeAsBytes(correctedContent.toList());
          // We retry to open the box
          if (!Hive.isBoxOpen(boxName)) {
            await Hive.openBox<GameAttributes>(boxName);
          }
        }
      }
    });
  }

  save(GameAttributes gm) async{
    await openIfNotOpened();
    await lock.synchronized(() async {
      print("saving");
      gm.save();
    });
  }

   readFromDb() async {
    await openIfNotOpened();
    print('read from db');
    var values = box!.values;
    return values.length == 0 ? List<GameAttributes>.empty(): values.toList();
  }

  // put(GameAttributes gm) async{
  //   await openIfNotOpened();
  //   box.add(gm);
  // }

  putIfNotExist(GameAttributes gm) async{
    await lock.synchronized(() async {
      await openIfNotOpened();
      List<GameAttributes> values = await readFromDb();
      final index = values
          .indexWhere((gameAttr) => gameAttr.gameId == gm.gameId);
      if (index == -1) {
        box!.add(gm);
        print('saved in box$gm');
      }
    });
  }

  getByIdFromDb(var id) async {
    await openIfNotOpened();
    List<GameAttributes> gms = await readFromDb();
    if (gms.isEmpty) return null;
    return gms.firstWhereOrNull((gm) => gm.gameId == id);
  }

  removeFromDb(final String id) async {
    await lock.synchronized(() async {
      await openIfNotOpened();
      print('remove from db $id');
      List<GameAttributes> values = await readFromDb();
      GameAttributes? item = values.firstWhereOrNull((gm) =>
      gm.gameId == id);
      item!.delete();
    });
  }

  flush() async {
    await box?.flush();
  }

  close() async{
    try {
      await box?.flush();
      await box?.close();
    } on FileSystemException {
      debugPrint("error");
    }
    print("box is closed");
    box = null;
  }

  openIfNotOpened() async {
    if (!Hive.isBoxOpen(boxName)) {
      print("box was closed");
      box = await Hive.openBox(boxName);
    } else {
      print("box is opened");
    }
  }
}