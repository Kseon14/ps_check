import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:ps_check/ga.dart';
import 'package:ps_check/model.dart';
import 'package:ps_check/notification_service.dart';
import 'package:ps_check/spw.dart';
import 'package:ps_check/theme.dart';
import 'package:ps_check/tutorialManager.dart';
import 'package:ps_check/web-b.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:workmanager/workmanager.dart';
import 'browser2.dart';
import 'hive_wrapper.dart';


var hiveWrapper = HiveWrapper.instance();
var sharedPropWrapper = SharedPropWrapper.instance();
var theme = ThemeInt.instance();
bool isActionInProgress = false;
int dataLength = 0;

var imageWidth = 95.0;
var imageHeight = 135.0;
var cacheExtentSize = 2000.0;
//var host = "http://localhost:9595";
var host = "https://web.np.playstation.com";

GlobalKey settingKey = GlobalKey();
GlobalKey addKeyMain = GlobalKey();
GlobalKey addKey2 = GlobalKey();
GlobalKey listViewKey = GlobalKey();

final GlobalKey<AnimatedListState> listKey = GlobalKey();

Future<List<Data?>> fetchDataV2(bool fromNotification) async {
  isActionInProgress = true;
  debugPrint("fetching data....");
  List<GameAttributes> gameAttributes = await hiveWrapper.readFromDb();
  List<Data?> dates = [];
  Map<String, String> headers = {
    "X-Psn-Store-Locale-Override": await sharedPropWrapper.readRegion()
  };
  if (gameAttributes.isNotEmpty) {
    List<Game> games = List<Game>.from(gameAttributes
        .map((gameAttribute) => convertToGame(gameAttribute))
        .where((game) => game != null)
        .toList());

    dates = await Future.wait(games.map((game) async {
      http.Response response =
          await http.Client().get(Uri.parse(game.url!), headers: headers);
      Data data = Data.fromJson(response.body, game);
      if (data.productRetrieve == null) {
        return Future.value(null);
      }
      data.imageUrl = game.imageUrl;
      GameAttributes? gm = gameAttributes
          .firstWhereOrNull((gms) => gms.gameId == data.productRetrieve!.id);
      if (gm == null) {
        return Future.value(null);
      }

      if (!fromNotification) {
        if (_isDiscountExist(data.productRetrieve!) &
            await isPriceLessThenSaved(data, gm)) {
          gm.discountedValue =
              data.productRetrieve!.webctas![0].price?.discountedValue;
        }
      }
      data.url = gm.url;
      return Future.value(data);
    }));

    debugPrint("GameAttributesOB: $gameAttributes");
    debugPrint("data: $dates");
  }
  dates = dates.where((data) => data != null).toList();
  dates.sort((a, b) {
    if (a!.productRetrieve!.webctas!.isEmpty  ||
        b!.productRetrieve!.webctas!.isEmpty) {
      return 0;
    }
    if (a.productRetrieve!.webctas![0].price!.discountedValue == null &&
        b.productRetrieve!.webctas![0].price!.discountedValue == null) {
      return 0;
    }
    if (a.productRetrieve!.webctas![0].price!.discountedValue == null) {
      return 1;
    }
    if (b.productRetrieve!.webctas![0].price!.discountedValue == null) {
      return -1;
    }
    return a.productRetrieve!.webctas![0].price!.discountedValue!
        .compareTo(b.productRetrieve!.webctas![0].price!.discountedValue!);
  });
  dataLength = dates.length;
  isActionInProgress = false;
  return dates;
}

_isDiscountExist(ProductRetrieve productRetrieve) {
  if(productRetrieve.webctas!.isEmpty) {
    return false;
  }
  if (productRetrieve.webctas![0].price!.discountedValue == null) {
    return false;
  }
  if (productRetrieve.webctas![0].price!.discountedValue == 0) {
    return false;
  }
  return productRetrieve.webctas![0].price!.discountedValue! <
      productRetrieve.webctas![0].price!.basePriceValue!;
}

// ga = null discount = 100
// ga = 100 discount = 100
// ga = 100 discount = 200
isPriceLessThenSaved(Data data, GameAttributes gameAttributes) async {
  if (gameAttributes.discountedValue == null) {
    if (data.productRetrieve!.webctas!.isEmpty){
      return false;
    }
    gameAttributes.discountedValue =
        data.productRetrieve!.webctas![0].price!.discountedValue;
    debugPrint("gameAttributes.discountedValue is null");
    debugPrint(
        "gameAttributes.discountedValue now ${gameAttributes.discountedValue}");
    await hiveWrapper.save(gameAttributes);
    return false;
  }
  if (data.productRetrieve!.webctas![0].price!.discountedValue == null) {
    return false;
  }
  if (data.productRetrieve!.webctas![0].price!.discountedValue! >
      gameAttributes.discountedValue!) {
    gameAttributes.discountedValue =
        data.productRetrieve!.webctas![0].price!.discountedValue;
    debugPrint("gameAttributes.discountedValue less then in data");
    debugPrint(
        "${data.productRetrieve!.webctas![0].price!.discountedValue} more then"
        "${gameAttributes.discountedValue}");
    debugPrint("gameAttributes.discountedValue less then in data");
    await hiveWrapper.save(gameAttributes);
    return false;
  }
  if (data.productRetrieve!.webctas![0].price!.discountedValue! <
      gameAttributes.discountedValue!) {
    gameAttributes.discountedValue =
        data.productRetrieve!.webctas![0].price!.discountedValue;
    debugPrint("gameAttributes.discountedValue more then in data");
    debugPrint(
        "${data.productRetrieve!.webctas![0].price!.discountedValue} less then"
        "${gameAttributes.discountedValue}");
    await hiveWrapper.save(gameAttributes);
    return true;
  }
  return false;
}

Game? convertToGame(GameAttributes gameAttribute) {
  switch (gameAttribute.type) {
    case GameType.PRODUCT:
      return Game(
          url: "$host/api/graphql/v1/op"
              "?operationName=productRetrieveForCtasWithPrice"
              "&variables=%7B%22productId%22%3A%22"
              "${gameAttribute.gameId}"
              "%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version"
              "%22%3A1%2C%22sha256Hash%22%3A%22dd61c9db18f39d1459b0b4927a58335125ca801c584ced5e138261075da230b2%22%7D%7D",
          imageUrl: gameAttribute.imgUrl,
          id: gameAttribute.gameId);
    case GameType.CONCEPT:
      return Game(
          url: "$host/api/graphql/v1/op?"
              "operationName=conceptRetrieveForCtasWithPrice"
              "&variables=%7B%22conceptId%22%3A%22"
              "${gameAttribute.gameId}"
              "%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash"
              "%22%3A%2268e483c8c56ded35047fc3015aa528c6191bf50bce2aae4f190120a1be1c8ba3%22%7D%7D",
          imageUrl: gameAttribute.imgUrl,
          id: gameAttribute.gameId);
    default:
      return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  debugPrint("init");
  await hiveWrapper.init();
  await NotificationService().init();
  await Firebase.initializeApp();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(GameChecker());
}

Future selectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: $payload');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('notification payload: $task');
    //await hiveWrapper.close();
    await hiveWrapper.init();
    List<Data?> datas = await fetchDataV2(true);
    List<GameAttributes> gameAttributes = await hiveWrapper.readFromDb();
    var badgeCount = 0;
    for (final data in datas) {
      GameAttributes? gm = gameAttributes
          .firstWhereOrNull((i) => i.gameId == data!.productRetrieve?.id);
      debugPrint("data :$data");
      debugPrint("gm :$gm");
      //  print("less or not"+ isPriceLessThenSaved(data, gm));
      // if (_isPriceLessThenSaved(data, gm)) {
      if (gm!.discountedValue == null) {
        gm.discountedValue =
            data!.productRetrieve?.webctas?[0].price?.discountedValue;
        await hiveWrapper.save(gm);
        //hiveWrapper.put(gm);
        debugPrint("gameAttributes.discountedValue is null");
        debugPrint("gameAttributes.discountedValue now ${gm.discountedValue}");
      }
      if (data!.productRetrieve?.webctas![0].price!.discountedValue == null) {
        continue;
      }
      if (data.productRetrieve!.webctas![0].price!.discountedValue! >
          gm.discountedValue!) {
        gm.discountedValue =
            data.productRetrieve!.webctas![0].price!.discountedValue;
        await hiveWrapper.save(gm);
        debugPrint("gameAttributes.discountedValue less then in data");
        debugPrint(
            "${data.productRetrieve!.webctas![0].price!.discountedValue} more then"
            "${gm.discountedValue}");
      }
      if (data.productRetrieve!.webctas![0].price!.discountedValue! <
          gm.discountedValue!) {
        gm.discountedValue =
            data.productRetrieve!.webctas![0].price!.discountedValue;
        await hiveWrapper.save(gm);
        //hiveWrapper.put(gm);
        debugPrint("gameAttributes.discountedValue more then in data");
        debugPrint(
            "${data.productRetrieve!.webctas![0].price!.discountedValue} less then"
            "${gm.discountedValue}");
        NotificationService().showNotification(data);
        badgeCount = badgeCount + 1;
      }
      FlutterAppBadger.updateBadgeCount(badgeCount);
    }
    await hiveWrapper.close();
    return Future.value(true);
  });
}

class GameChecker extends StatefulWidget {
  const GameChecker({Key? key}) : super(key: key);

  @override
  _GameCheckerState createState() => _GameCheckerState();
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> backgroundMessageHandler(RemoteMessage message) async {
  if (message.data.isNotEmpty) {
    var taskType = message.data['task'];
    if (taskType == 'update_data') {
      // Perform your data fetching task
      print("Handling a background message: ${message.messageId}");
    }
  }
}


class _GameCheckerState extends State<GameChecker> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Handle the initial message
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle a message that opened the app from the background
    });
    theme.addListener(() {
      refresh();
    });
  }

  refresh() async {
    try {
      if (isActionInProgress) {
        // Action is already in progress, skip executing it again.
        return;
      }
      print(">>>>>>>>> refreshing");
      // Perform the async operation here
     // await Future.delayed(Duration(seconds: 3));
      setState(() {
        isActionInProgress = true;
      });
      // Mark the operation as complete
    } finally {
      // Set the completer to null to free up memory
      await Future.microtask(() {
        isActionInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          // systemNavigationBarColor: Colors.white,
          // navigation bar color
          //statusBarColor: Colors.white,
          // status bar color
          // statusBarBrightness: Brightness.dark,
          //status bar brigtness
          //statusBarIconBrightness: Brightness.dark,
          //status barIcon Brightness
          // systemNavigationBarDividerColor: Colors.transparent,
          //Navigation bar divider color
          // systemNavigationBarIconBrightness:
          //Brightness.dark, //navigation bar icon
          ));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => GameCheckerMain(
            show: sharedPropWrapper.readTutorialFlagMain(),
            notifyParent: refresh),
        '/webView': (context) => GameBrowsingScreen('BASE_URL'),
      },
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.white,
          backgroundColor: Colors.white
          ),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.black45,
          backgroundColor: Colors.black54

          ),
      themeMode: ThemeMode.light,
    );
  }
}

class GameCheckerMain extends StatefulWidget {
  final Function() notifyParent;

  GameCheckerMain({Key? key, required this.show, required this.notifyParent})
      : super(key: key);
  Future<dynamic> show;

  @override
  _GameCheckerMainState createState() => _GameCheckerMainState();
}

class _GameCheckerMainState extends State<GameCheckerMain>
    with WidgetsBindingObserver {
  List<String>? gameIds;
  String selectedRegion = "";
  FixedExtentScrollController? firstController;
  int? index;

  _startTutorial(Future<dynamic> show) async {
    if (!await show) {
      var tutorialManager = TutorialManager(
        context: context,
        sharedPropWrapper: sharedPropWrapper, // Ensure you have this class defined
      );
      tutorialManager.startMainTutorial();
    }
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await hiveWrapper.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
      // force a close and start from fresh. Just incase
      // a box wasn't closed on inactive/paused
        NotificationService().cancelAllNotifications();
        FlutterAppBadger.updateBadgeCount(0);
        await hiveWrapper.close();
        await hiveWrapper.init();
        debugPrint("state: resumed");
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        debugPrint("state: paused");
        break;
      default:
        debugPrint("state: default");
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //NotificationService().cancelAllNotifications();
    firstController = FixedExtentScrollController(initialItem: 0);
    _startTutorial(widget.show);
    debugPrint("init State");
  }

  Future<void> _refreshList() async {
    widget.notifyParent();
  }

  refreshListButton() async {
    _refreshList();
  }

  //TODO revisit this method
  getLocationName() async {
    var value = await sharedPropWrapper.readRegion();
    if (value != null) {
      var regionName = getLocations()
          .firstWhere((element) => element.abbreviation == value)
          .name;
      index = _getIndex(regionName);
      return regionName;
    } else {
      debugPrint('default :$selectedRegion');
      index = 0;
      return getLocations()[0].name;
    }
  }

  _getIndex(String name) {
    return getLocations().indexWhere((region) => region.name == name);
  }

  _bottomRegionSelection() async {
    debugPrint("picker");
    showModalBottomSheet(
        backgroundColor: Colors.white.withOpacity(1),
        context: context,
        builder: (BuildContext context) {
          return Container(
              height: 200,
              child: CupertinoPicker(
                  //backgroundColor: Colors.white.withOpacity(0.6),
                //backgroundColor: Theme.of(context).primaryColor,
                  magnification: 1.2,
                  onSelectedItemChanged: (index) {
                    this.index = index;
                  },
                  itemExtent: 34.0,
                  scrollController:
                  FixedExtentScrollController(initialItem: index!),
                  children: getLocations()
                      .map((region) =>
                  new Text(
                    region.name,
                    style: TextStyle(color: Colors.black),
                  ))
                      .toList()));
        }).then((value) {
      if (selectedRegion != getLocations()[index!].name) {
        //TODO
        // setState(() {});
        widget.notifyParent();
        selectedRegion = getLocations()[index!].name;
        sharedPropWrapper.saveRegion(getLocations()[index!].abbreviation);
        Navigator.pop(context);
        _showModalSheet();
      }
    });
  }

  _showModalSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.5),
      barrierColor: Colors.transparent,
      builder: (context) {
        return Container(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 25.0,
                sigmaY: 25.0,
              ),
              child: Container(
                height: 250,
                child: Column(
                  children: [
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.25,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.black12,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder(
                        future: getLocationName(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            print(snapshot.data);
                            return new Container(
                              padding: EdgeInsets.all(10),
                              //margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                children: [
                                  GestureDetector(
                                      onTap: () => _bottomRegionSelection(),
                                      child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(Icons.language,
                                                color: Colors.black),
                                            SizedBox(
                                              width: 6,
                                            ),
                                            Text(
                                              "Region",
                                              style: TextStyle(fontSize: 17),
                                            ),
                                            //Spacer(),
                                            Container(
                                                child: Flexible(
                                                    flex: 7,
                                                    child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .end,
                                                        children: [
                                                          Container(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: Text(
                                                              snapshot.data
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  fontSize: 17),
                                                              textAlign:
                                                              TextAlign.end,
                                                            ),
                                                          )
                                                        ]))),
                                          ])),
                                ],
                              ),
                            );
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  GlobalKey refreshKey = GlobalKey();
  RefreshController refreshController = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
  // debugPrint("_GameCheckerMainState");

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        cacheExtent: cacheExtentSize,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: <Widget>[
          SliverAppBar(
            toolbarHeight: 44,
            //collapsedHeight: 20,
            //expandedHeight: 50.0,
           floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            forceElevated: true,
            backgroundColor: Colors.white.withOpacity(0.6),
            leading: GestureDetector(
              key: settingKey,
              onTap: () {
                _showModalSheet();
              },
              child:
                  Icon(Icons.settings, color: Color.fromARGB(255, 0, 114, 206)),
            ),
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    key: addKeyMain,
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/webView');
                      widget.notifyParent();
                    },
                    child: Icon(Icons.add,
                        size: 30.0, color: Color.fromARGB(255, 0, 114, 206)),
                  ))
            ],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.all(0.0),
                ),
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await Future.delayed(Duration(milliseconds: min((dataLength*200).floor(), 3000)));
              //print("onRefresh");
              //print("$dataLength");
              //print(min((dataLength*200).floor(), 3000));
              await widget.notifyParent();
              refreshController.refreshCompleted();
            },
          ),

          FutureBuilder<List<Data?>>(
              future: fetchDataV2(false),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  debugPrint('show list');
                  return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 12, top: 13),
                      sliver: GamesList(
                        data: snapshot.data ?? [],
                        notifyParent: widget.notifyParent,
                        refreshList: refreshListButton,
                      ));
                }
                return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                      IconButton(
                        key: addKey2,
                        iconSize: 31,
                        splashColor: Colors.green,
                        icon: const Icon(Icons.add),
                        color: Colors.green,
                        onPressed: () async {
                          await Navigator.of(context).pushNamed('/webView');
                          widget.notifyParent();
                        },
                      ),
                      IconButton(
                        iconSize: 31,
                        splashColor: Colors.green,
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          refreshListButton();
                        },
                      )
                    ]));
              }),
        ],
      ),
    );
  }
}

//List of items
class GamesList extends StatefulWidget {
  final List<Data?> data;
  final Function() notifyParent;
  final Function() refreshList;

  GamesList(
      {Key? key,
      required this.data,
      required this.notifyParent,
      required this.refreshList})
      : super(key: key);

  @override
  _GamesListState createState() => _GamesListState();
}

class _GamesListState extends State<GamesList> {

  @override
  Widget build(BuildContext context) {
    debugPrint("list builder");
    if (widget.data.length == 0) {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            IconButton(
              key: addKey2,
              iconSize: 31,
              splashColor: Colors.black26,
              icon: const Icon(Icons.add),
              color: Color(0x0000ffff),
              //tooltip: 'Increase volume by 10',
              onPressed: () async {
                await Navigator.of(context).pushNamed('/webView');
                widget.notifyParent();
              },
            ),
            IconButton(
              iconSize: 31,
              splashColor: Colors.green,
              icon: const Icon(Icons.refresh),
              //tooltip: 'Increase volume by 10',
              onPressed: () {
                widget.refreshList();
              },
            )
          ]));
    }
    return
        SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Slidable(
            key: UniqueKey(),
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.25,
              dismissible: DismissiblePane(
                onDismissed: () {
                  setState(() {
                    hiveWrapper
                        .removeFromDb(widget.data[index]!.productRetrieve!.id!);
                    widget.data.removeAt(index);
                  });
                },
              ),
              children: [
                SlidableAction(
                  label: 'Delete',
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  onPressed: (context) {
                    setState(() {
                      hiveWrapper.removeFromDb(
                          widget.data[index]!.productRetrieve!.id!);
                      widget.data.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            child: GestureDetector(
                onTap: () => _launchURL(context, widget.data[index]!.url),
                child: GameRowItem(data: widget.data[index]!)),
          );
        },
        childCount: widget.data.length,
      ),
    )
        //)
        ;
  }
}

_showText(ProductRetrieve productRetrieve) {
  var textItems = <Widget>[];
  textItems.add(AutoSizeText(
    productRetrieve.name!,
    style: _getTextStyle(),
    maxLines: 3,
    maxFontSize: 14,
  ));

  if (productRetrieve.webctas![0].price!.basePrice != null) {
    if (_isDiscountExist(productRetrieve)) {
      textItems.add(AutoSizeText(
        productRetrieve.webctas![0].price!.basePrice!,
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxFontSize: 15,
      ));
      textItems.add(AutoSizeText(
          productRetrieve.webctas![0].price!.discountedPrice!,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.red),
          maxFontSize: 15));
    } else {
      textItems.add(AutoSizeText(
        productRetrieve.webctas![0].price!.basePrice!,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxFontSize: 15,
      ));
    }
  }
  return textItems;
}

_getTextStyle() {
  return TextStyle(fontSize: 14);
}

void _launchURL(var context, var url) async => Navigator.push(
    context, MaterialPageRoute(builder: (context) => WebViewContainer(url)));

class ImageWrapper extends StatelessWidget {
  const ImageWrapper({Key? key, required this.url}) : super(key: key);
  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      alignment: Alignment.center,
      imageUrl: url,
      placeholder: (context, url) => Center(
          child: SizedBox(
        child: CircularProgressIndicator(
          backgroundColor: Colors.blue,
          valueColor: AlwaysStoppedAnimation(Colors.grey),
        ),
        height: 20.0,
        width: 20.0,
      )),
      errorWidget: (context, url, error) => Icon(Icons.error),
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.fitHeight,
    );
  }
}

class GameRowItem extends StatelessWidget {
  const GameRowItem({Key? key, required this.data}) : super(key: key);
  final Data? data;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Theme.of(context).primaryColor,
        elevation: 0.0,
        child: new Container(
          padding: new EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.5),
                    child: ImageWrapper(
                      url: data!.imageUrl!,
                    ),
                  )),
              Flexible(
                  flex: 2,
                  child: Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child:  Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // This line is already uncommented
                              mainAxisAlignment: MainAxisAlignment.start, // Add this line
                              children: _showText(data!.productRetrieve!),
                            ))
                      ]))
            ],
          ),
        ));
  }
}
