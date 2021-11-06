import 'dart:io';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:ps_check/ga.dart';
import 'package:ps_check/hive_wrapper.dart';
import 'package:ps_check/model.dart';
import 'package:ps_check/notification_service.dart';
import 'package:ps_check/spw.dart';
import 'package:ps_check/web-b.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:workmanager/workmanager.dart';

import 'browser2.dart';

//flutter pub run flutter_launcher_icons:main
//var box;
var hiveWrapper = HiveWrapper.instance();
var sharedPropWrapper = SharedPropWrapper.instance();
var imageWidth = 95.0;
var imageHight = 135.0;
var cacheExtentSize = 5000.0;
var host = "http://localhost:9595";
//var host = "https://web.np.playstation.com";

Future<List<Data?>> fetchDataV2(bool fromNotification) async {
  print("fetching data....");
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

    print("GameAttributesOB: $gameAttributes");
    print("data: $dates");
  }
  return dates.where((data) => data != null).toList();
}

_isDiscountExist(ProductRetrieve productRetrieve) {
  if (productRetrieve.webctas![0].price!.discountedValue == null) {
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
    gameAttributes.discountedValue =
        data.productRetrieve!.webctas![0].price!.discountedValue;
    print("gameAttributes.discountedValue is null");
    print(
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
    print("gameAttributes.discountedValue less then in data");
    print(
        "${data.productRetrieve!.webctas![0].price!.discountedValue} more then"
        "${gameAttributes.discountedValue}");
    print("gameAttributes.discountedValue less then in data");
    await hiveWrapper.save(gameAttributes);
    return false;
  }
  if (data.productRetrieve!.webctas![0].price!.discountedValue! <
      gameAttributes.discountedValue!) {
    gameAttributes.discountedValue =
        data.productRetrieve!.webctas![0].price!.discountedValue;
    print("gameAttributes.discountedValue more then in data");
    print(
        "${data.productRetrieve!.webctas![0].price!.discountedValue} less then"
        "${gameAttributes.discountedValue}");
    await hiveWrapper.save(gameAttributes);
    return true;
  }
  return false;
}

// _initHive() async {
//   await Hive.initFlutter();
//   Hive.registerAdapter(GameAttributesOBAdapter());
//   Hive.registerAdapter(GameTypeAdapter());
//   box = await Hive.openBox<GameAttributesOB>('game-box');
// }

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
  await hiveWrapper.init();
  //ns = new NotificationService();

  await NotificationService().init();

  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');
  // final IOSInitializationSettings initializationSettingsIOS =
  //     IOSInitializationSettings();
  //
  // final InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsIOS);
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings,
  //     onSelectNotification: selectNotification);
  //
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  //
  if (Platform.isAndroid) {
    Workmanager().registerPeriodicTask(
      "game-checker",
      "getUpdateForPrice",
      frequency: Duration(hours: 12),
    );
  }
  runApp(GameChecker());
}
//
// _initOB() async{
//   // if(boxOB == null) {
//   //   Store store = await openStore();
//   //   boxOB = store.box<GameAttributesOB>();
//   // }
//   // Store store = await openStore();
//   // var boxTest = store.box<TestObj>();
//   // boxTest.put(new TestObj(text:"test"));
//   //print(boxTest.getAll());
// }

Future selectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: $payload');
  }
}

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
      print("data :$data");
      print("gm :$gm");
      //  print("less or not"+ isPriceLessThenSaved(data, gm));
      // if (_isPriceLessThenSaved(data, gm)) {
      if (gm!.discountedValue == null) {
        gm.discountedValue =
            data!.productRetrieve?.webctas?[0].price?.discountedValue;
        await hiveWrapper.save(gm);
        //hiveWrapper.put(gm);
        print("gameAttributes.discountedValue is null");
        print("gameAttributes.discountedValue now ${gm.discountedValue}");
      }
      if (data!.productRetrieve?.webctas![0].price!.discountedValue == null) {
        continue;
      }
      if (data.productRetrieve!.webctas![0].price!.discountedValue! >
          gm.discountedValue!) {
        gm.discountedValue =
            data.productRetrieve!.webctas![0].price!.discountedValue;
        await hiveWrapper.save(gm);
        print("gameAttributes.discountedValue less then in data");
        print(
            "${data.productRetrieve!.webctas![0].price!.discountedValue} more then"
            "${gm.discountedValue}");
      }
      if (data.productRetrieve!.webctas![0].price!.discountedValue! <
          gm.discountedValue!) {
        gm.discountedValue =
            data.productRetrieve!.webctas![0].price!.discountedValue;
        await hiveWrapper.save(gm);
        //hiveWrapper.put(gm);
        print("gameAttributes.discountedValue more then in data");
        print(
            "${data.productRetrieve!.webctas![0].price!.discountedValue} less then"
            "${gm.discountedValue}");
        NotificationService().showNotification(data);
        badgeCount = badgeCount + 1;
      }
      FlutterAppBadger.updateBadgeCount(badgeCount);
    }
    await hiveWrapper.close();

    //if (task == 'uniqueKey') {
    ///do the task in Backend for how and when to send notification
    //   var response = await http.get(Uri.parse('https://reqres.in/api/users/2'));
    //   Map dataComingFromTheServer = json.decode(response.body);
    //
    //   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    //       FlutterLocalNotificationsPlugin();
    //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
    //       AndroidNotificationDetails('your channel id', 'your channel name',
    //           'your channel description',
    //           importance: Importance.max,
    //           priority: Priority.high,
    //           showWhen: false);
    //   const NotificationDetails platformChannelSpecifics =
    //       NotificationDetails(android: androidPlatformChannelSpecifics);
    //   await flutterLocalNotificationsPlugin.show(
    //       0,
    //       dataComingFromTheServer['data']['first_name'],
    //       dataComingFromTheServer['data']['email'],
    //       platformChannelSpecifics,
    //       payload: 'item x');
    // }
    return Future.value(true);
  });
}

class GameChecker extends StatefulWidget {
  @override
  _GameCheckerState createState() => _GameCheckerState();
}

class _GameCheckerState extends State<GameChecker> with WidgetsBindingObserver {
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
      //theme: new ThemeData(scaffoldBackgroundColor: Colors.white),
      initialRoute: '/',
      routes: {
        '/': (context) => GameCheckerMain(),
        // '/settings': (context) => Settings(),
        '/webView': (context) => InAppWebview(),
      },
    );
  }

  @override
  void dispose() async {
    WidgetsBinding.instance!.removeObserver(this);
    await hiveWrapper.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    //NotificationService().cancelAllNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // force a close and start from fresh. Just incase
        // a box wasn't closed on inactive/paused
        NotificationService().cancelAllNotifications();
        FlutterAppBadger.updateBadgeCount(0);
        //await hiveWrapper.close();
        await hiveWrapper.init();
        print("state: resumed");
        //fetchDataV2(false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        await hiveWrapper.close();
        print("state: paused");
        break;
      default:
        print("state: default");
        break;
    }
  }
}

class GameCheckerMain extends StatefulWidget {
  @override
  _GameCheckerMainState createState() => _GameCheckerMainState();
}

class _GameCheckerMainState extends State<GameCheckerMain>
    with AutomaticKeepAliveClientMixin<GameCheckerMain> {
  List<String>? gameIds;
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  String selectedRegion = "";
  FixedExtentScrollController? firstController;
  int? index;

  Future<Null> _refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));
    fetchDataV2(false);
    // setState(() {
    //
    // });
    return null;
  }

  _refreshListButton() async {
    _refreshList();
  }

  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];

  GlobalKey settingKey = GlobalKey();
  GlobalKey addKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    firstController = FixedExtentScrollController(initialItem: 0);
    _startTutorial();
  }

  _startTutorial() async {
    if (!await sharedPropWrapper.readTutorialFlagMain()) {
      initTarget();
      WidgetsBinding.instance?.addPostFrameCallback(_layout);
    }
  }

  void _layout(_) {
    Future.delayed(Duration(milliseconds: 100));
    showTutorial();
  }

  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      context,
      targets: targets,
      colorShadow: Colors.pink,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        sharedPropWrapper.saveTutorialFlagMain(true);
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onSkip: () {
        print("skip");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
    )..show();
  }

  initTarget() {
    targets.add(
      TargetFocus(
        identify: "Setting region",
        keyTarget: settingKey,
        color: Colors.red,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Select your region",
                    style: TextStyle(
                        //fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  SizedBox(
                    width: 200.0,
                    height: 300.0,
                    child: Text(
                      "Base on this selection ps store will show regional site, "
                      "games and price",
                      style: TextStyle(color: Colors.white, fontSize: 15.0),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
        //shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Add game",
        keyTarget: addKey,
        enableOverlayTab: true,
        contents: [
          TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                        width: 200.0,
                        height: 300.0,
                        child: Text(
                          "Click here to start game selection",
                          style: TextStyle(
                              //fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20.0),
                        )),
                  ],
                ),
              ))
        ],
      ),
    );
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
      print('default :$selectedRegion');
      index = 0;
      return getLocations()[0].name;
    }
  }

  _getIndex(String name) {
    return getLocations().indexWhere((region) => region.name == name);
  }

  _showPicker() async {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
              height: 200,
              child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  magnification: 1.2,
                  onSelectedItemChanged: (index) {
                    this.index = index;
                  },
                  itemExtent: 34.0,
                  scrollController:
                      FixedExtentScrollController(initialItem: index!),
                  children: getLocations()
                      .map((region) => new Text(region.name))
                      .toList()));
        }).then((value) {
      if (selectedRegion != getLocations()[index!].name) {
        setState(() {});
        selectedRegion = getLocations()[index!].name;
        sharedPropWrapper.saveRegion(getLocations()[index!].abbreviation);
        Navigator.pop(context);
        _showModalSheet();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _showModalSheet() {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return FutureBuilder(
              future: getLocationName(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print(snapshot.data);
                  return new Container(
                    height: 250,
                    color: Colors.white,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      //margin: EdgeInsets.fromLTRB(15, 10, 0, 10),
                      child: Column(
                        children: [
                          GestureDetector(
                              onTap: () => _showPicker(),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 1,
                                        child: Icon(Icons.language,
                                            color: Colors.black)),
                                    Flexible(
                                        //key: _key1,
                                        flex: 2,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                " Region",
                                                style: TextStyle(fontSize: 17),
                                              )
                                            ])),
                                    //Spacer(),
                                    Container(
                                        child: Flexible(
                                            flex: 7,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      snapshot.data.toString(),
                                                      style: TextStyle(
                                                          fontSize: 17),
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  )
                                                ]))),
                                  ])),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            //brightness: Brightness.light,
            toolbarHeight: 44,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: GestureDetector(
              key: settingKey,
              onTap: () {
                // Navigator.of(context).pushNamed('/settings');
                // Navigator.push(context, PageTransition(type: PageTransitionType.bottomToTop, child: Settings()));
                _showModalSheet();
                //setState(() {
                //should refresh the list
                // });
              },
              child: Icon(Icons.settings,
                  color: Colors.blue // add custom icons also
                  ),
            ),
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    key: addKey,
                    onTap: () async {
                      // GameAttributes gameAttribute =
                      //(await
                      await Navigator.of(context).pushNamed('/webView');
                      // )
                      // as GameAttributes;
                      // if (gameAttribute != null) {
                      //   hiveWrapper.put(gameAttribute);
                      // }
                      setState(() {
                        //should refresh the state
                      });
                    },
                    child: Icon(Icons.add, size: 30.0, color: Colors.blue),
                  ))
            ]),
        body: FutureBuilder<List<Data?>>(
            future: fetchDataV2(false),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);
              // if (snapshot.hasData && snapshot.data.isNotEmpty) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  print('show list');
                  return RefreshIndicator(
                      key: refreshKey,
                      child: GamesList(data: snapshot.data ?? []),
                      onRefresh: () {
                        return _refreshList();
                      });
                } else {
                  print('show empty list');
                  return Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        Text("no any games in list"),
                        IconButton(
                          iconSize: 27,
                          splashColor: Colors.green,
                          icon: const Icon(Icons.refresh),
                          //tooltip: 'Increase volume by 10',
                          onPressed: () {
                            _refreshListButton();
                            // setState(() {
                            //   _refreshListButton();
                            // });
                          },
                        )
                        //      TextButton.icon(onPressed: _refreshListButton(),
                        // icon: Icon(Icons.refresh),label: null)
                      ]));
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
  }

  @override
  bool get wantKeepAlive => true;
}

class GamesList extends StatefulWidget {
  final List<Data?> data;

  GamesList({Key? key, required this.data}) : super(key: key);

  @override
  _GamesListState createState() => _GamesListState();
}

class _GamesListState extends State<GamesList>
    with AutomaticKeepAliveClientMixin<GamesList> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        cacheExtent: cacheExtentSize,
        //padding: const EdgeInsets.all(1.0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.data.length,
        itemExtent: imageHight,
        itemBuilder: (BuildContext context, int index) {
          return Slidable(
            key: UniqueKey(),
            actionPane: SlidableDrawerActionPane(),
            actionExtentRatio: 0.25,
            dismissal: SlidableDismissal(
              child: SlidableDrawerDismissal(),
              onDismissed: (actionType) {
                setState(() {
                  hiveWrapper
                      .removeFromDb(widget.data[index]!.productRetrieve!.id!);
                  // ScaffoldMessenger.of(context)
                  //      ..hideCurrentSnackBar()
                  //     ..showSnackBar(SnackBar(
                  //     duration: Duration(milliseconds: 500),
                  //     content: Text(
                  //         "${widget.data[index].productRetrieve.name} dismissed")));
                  widget.data.removeAt(index);
                });
              },
            ),
            child: GestureDetector(
              onTap: () => _launchURL(context, widget.data[index]!.url),
              child: new Card(
                  elevation: 0.0,
                  child: new Container(
                    padding: new EdgeInsets.all(1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                            child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.5),
                          child: CachedNetworkImage(
                            alignment: Alignment.center,
                            imageUrl: widget.data[index]!.imageUrl!,
                            placeholder: (context, url) => Center(
                                child: SizedBox(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.blue,
                                valueColor: AlwaysStoppedAnimation(Colors.grey),
                                //strokeWidth: 20,
                              ),
                              height: 20.0,
                              width: 20.0,
                            )),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                            width: imageWidth,
                            height: 600,
                            fit: BoxFit.fitHeight,
                          ),
                        )),
                        Flexible(
                            flex: 2,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _showText(
                                        widget.data[index]!.productRetrieve!),
                                  ))
                                ]))
                      ],
                    ),
                  )),
            ),
            secondaryActions: <Widget>[
              IconSlideAction(
                  caption: 'Delete',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => {
                        setState(() {
                          hiveWrapper.removeFromDb(
                              widget.data[index]!.productRetrieve!.id!);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                                duration: Duration(milliseconds: 600),
                                content: Text(
                                    "${widget.data[index]!.productRetrieve!.name!} dismissed")));
                          widget.data.removeAt(index);
                          // _showSnackBar(context, 'Delete');
                        })
                      }),
            ],
          );
        });
  }
}

void _showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
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

// _save(final String key, final value) async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> savedItems = await _read(key);
//   savedItems.add(value);
//   prefs.setStringList(key, savedItems);
//   print('saved $savedItems');
// }

// _remove(final String key, final String id) async {
//   final prefs = await SharedPreferences.getInstance();
//   List<String> gameIds = await _read(key);
//   gameIds.removeAt(gameIds.indexWhere((element) => element == id));
//   prefs.setStringList(key, gameIds);
// }

// _read(final String key) async {
//   final prefs = await SharedPreferences.getInstance();
//   final value = prefs.getStringList(key) ?? [];
//   return value;
// }

// void _launchURL(var url) async =>
//     await canLaunch(url) ? await launch(url,
//      forceWebView: true,
//      forceSafariVC: true,
//      // enableDomStorage: true,
//         headers: <String, String>{'Cookie': 'eucookiepreference=accept;at_check=true;s_cc=true'}) : throw 'Could not launch $url';

void _launchURL(var context, var url) async => Navigator.push(
    context, MaterialPageRoute(builder: (context) => WebViewContainer(url)));
