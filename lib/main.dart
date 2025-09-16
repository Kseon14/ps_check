import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ps_check/ga.dart';
import 'package:ps_check/model.dart';
import 'package:ps_check/notification_service.dart';
import 'package:ps_check/spw.dart';
import 'package:ps_check/sql_light_wrapper.dart';
import 'package:ps_check/theme.dart';
import 'package:ps_check/tutorialManager.dart';
import 'package:ps_check/url-composer.dart';
import 'package:ps_check/web-b.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:workmanager/workmanager.dart';
import 'gameList.dart';
import 'hive_wrapper.dart';
import 'package:pool/pool.dart';
import 'package:collection/collection.dart';

var hiveWrapper = HiveWrapper.instance();
final sqlWrapper = SqlWrapper.instance();
var sharedPropWrapper = SharedPropWrapper.instance();
var theme = ThemeInt.instance();
bool isActionInProgress = false;
int dataLength = 0;

var imageWidth = 90.0;
var imageHeight = 135.0;
var cacheExtentSize = 2000.0;
const int maxRetries = 3;
//var host = "http://localhost:9597";
//var host = "http://192.168.1.2:9595";
var host = "https://web.np.playstation.com";

Future<Map<String, String>> getHeader() async {
  return {
    "X-Psn-Store-Locale-Override": await sharedPropWrapper.readRegion(),
    "content-type": "application/json"
  };
}

Future<http.Response> requestDate(Uri? url) async {
  Map<String, String> headers = await getHeader();
  http.Response response = await http.Client().get(url!, headers: headers);
  return response;
}

Uri getUrl(String id, GameType type) {
  switch (type) {
    case GameType.ADD_ON:
      return ApiUrlComposer.composeUrl(
          id: id,
          type: type,
          operationName: "productRetrieveForCtasWithPrice",
          sha256Hash:
              "8872b0419dcab2fea5916ef698544c237b1096f9e76acc6aacf629551adee8cd");
    case GameType.PRODUCT:
      return ApiUrlComposer.composeUrl(
          id: id,
          type: type,
          operationName: "productRetrieveForUpsellWithCtas",
          sha256Hash:
              "fb0bfa0af4d8dc42b28fa5c077ed715543e7fb8a3deff8117a50b99864d246f1");
    case GameType.CONCEPT:
      return ApiUrlComposer.composeUrl(
          id: id,
          type: type,
          operationName: "conceptRetrieveForUpsellWithCtas",
          sha256Hash:
              "278822e6c6b9f304e4c788867b3e8a448c67847ac932d09213d5085811be3a18");
    case GameType.CONCEPT_PRE_ORDER:
      return ApiUrlComposer.composeUrl(
          id: id,
          type: GameType.CONCEPT,
          operationName: "conceptRetrieveForCtasWithPrice",
          sha256Hash:
          "eab9d873f90d4ad98fd55f07b6a0a606e6b3925f2d03b70477234b79c1df30b5");
  }
}

GlobalKey settingKey = GlobalKey();
GlobalKey addKeyMain = GlobalKey();
GlobalKey addKey2 = GlobalKey();
GlobalKey listViewKey = GlobalKey();
bool isRefreshing = false;

final GlobalKey<AnimatedListState> listKey = GlobalKey();

class HttpClients {
  static final HttpClient _hc = HttpClient()
    ..maxConnectionsPerHost = 4
    ..idleTimeout = const Duration(seconds: 15)
    ..connectionTimeout = const Duration(seconds: 10);

  static final IOClient shared = IOClient(_hc);
}

Future<http.Response?> _getWithRetry(Uri uri,
    {int maxRetries = 2}) async {
  final rand = Random();
  int attempt = 0;
  while (true) {
    try {
      final res = await requestDate(uri);
      if (res.statusCode == 200) return res;
      // Server error; retry a bit
      if (attempt >= maxRetries) return res;
    } catch (e) {
      if (attempt >= maxRetries) return null;
    }
    final backoffMs = (400 * pow(2, attempt)).toInt() + rand.nextInt(250);
    await Future.delayed(Duration(milliseconds: backoffMs));
    attempt++;
  }
}

Future<List<Data?>> fetchDataV2(bool fromNotification) async {
  isActionInProgress = true;
  try {
    final gms = await sqlWrapper.readFromDb();
    debugPrint("fetching data.... count=${gms.length}");
    if (gms.isEmpty) return <Data?>[];

    final pool = Pool(4); // limit concurrency
    final results = <Future<Data?>>[];

    for (final gm in gms) {
      results.add(pool.withResource(() async {
        debugPrint("fetching data for ${gm.gameId}....");

        // ensure concept/addon
        if (gm.conceptId == null || gm.addon == null) {
          if (gm.type == GameType.CONCEPT) {
            gm.conceptId = gm.gameId;
          } else {
            http.Response? tmpResponse =
            await _getWithRetry(getUrl(gm.gameId, gm.type));
            if (tmpResponse == null || tmpResponse.statusCode != 200) {
              debugPrint(
                  'bootstrap fetch failed for ${gm.gameId} status=${tmpResponse?.statusCode}');
              return null;
            }

            var responseBody = json.decode(tmpResponse.body);
            if (responseBody["errors"] != null) {
              debugPrint("errors for ${gm.gameId}: ${responseBody["errors"]}");
              return Data(
                products: [
                  Product(
                      name:
                      "❌ The game was removed or moved by PS Store, please re-add.")
                ],
                imageUrl: gm.imgUrl,
                url: gm.url,
              );
            }

            Data data = Data.fromJson(responseBody);
            if (data.products.isNotEmpty) {
              gm.conceptId = data.conceptId;
              if (data.products.first.productType == ProductType.ADD_ON) {
                gm.type = GameType.ADD_ON;
                gm.addon = true;
              }
            }
            await sqlWrapper.save(gm);
          }
        }

        // main fetch
        final uri = getUrl(
          gm.addon == true ? gm.gameId : (gm.conceptId ?? gm.gameId),
          gm.addon == true ? GameType.ADD_ON : GameType.CONCEPT,
        );
        final response = await _getWithRetry(uri);
        if (response == null || response.statusCode != 200) {
          debugPrint(
              'main fetch failed for ${gm.gameId} status=${response?.statusCode}');
          return null;
        }

        Data data = Data.fromJson(json.decode(response.body))
          ..imageUrl = gm.imgUrl
          ..url = gm.url;

        // release date fetch
        if (data.conceptId != null) {
          http.Response? relRes = await _getWithRetry(
              getUrl(data.conceptId!, GameType.CONCEPT_PRE_ORDER),
              maxRetries: 1);
          if (relRes != null && relRes.statusCode == 200) {
            final body = json.decode(relRes.body);
            final concept = body["data"]?["conceptRetrieve"];
            final type = concept?["releaseDate"]?["type"];
            final date = concept?["releaseDate"]?["value"];
            if (type == "DAY_MONTH_YEAR" && date != null) {
              final releaseDate = DateTime.tryParse(date);
              if (releaseDate != null &&
                  releaseDate.isAfter(DateTime.now().toUtc())) {
                gm.releaseDate =
                    releaseDate.toLocal().toIso8601String().split('T').first;
              }
            }
          }
        }

        // pick selected product
        final selected =
        data.products.firstWhereOrNull((p) => p.id == gm.gameId);
        if (selected == null) {
          debugPrint("No matching product found for ${gm.gameId}");
          return null;
        }

        debugPrint('Selected Product: ${selected.name}');
        selected.releaseDate = gm.releaseDate;
        Data gameInfo = Data(
            products: [selected], imageUrl: gm.imgUrl!, url: gm.url);

        if (!fromNotification) {
          if (await isPriceLessThenSaved(selected, gm)) {
            gm.discountedValue = selected.getDiscountPriceValue();
            debugPrint(
                "updated discountedValue for ${gm.gameId} -> ${gm.discountedValue}");
          }
        }
        await sqlWrapper.save(gm);
        return gameInfo;
      }));
    }

    final dates = (await Future.wait(results)).whereType<Data>().toList();
    debugPrint("Fetched ${dates.length}/${gms.length} successfully");

    // sort unchanged
    dates.sort((a, b) {
      final ap = a.products.first;
      final bp = b.products.first;
      final aPrice = ap.getDiscountPriceValue();
      final bPrice = bp.getDiscountPriceValue();

      int compareIds(String? x, String? y) {
        if (x == null && y == null) return 0;
        if (x == null) return -1;
        if (y == null) return 1;
        return x.compareTo(y);
      }

      if (aPrice == null && bPrice == null) return compareIds(ap.id, bp.id);
      if (aPrice == null) return -1;
      if (bPrice == null) return 1;
      if (aPrice == 0 && bPrice == 0) return compareIds(ap.id, bp.id);
      if (aPrice == 0) return 1;
      if (bPrice == 0) return -1;

      final cmp = aPrice.compareTo(bPrice);
      return cmp != 0 ? cmp : compareIds(ap.id, bp.id);
    });

    dataLength = dates.length;
    return dates;
  } finally {
    isActionInProgress = false;
  }
}


isDiscountExist(Product product) {
  if (product.getDiscountPriceValue() == null) {
    return false;
  }
  if (product.getDiscountPriceValue() == 0) {
    return false;
  }
  return product.getDiscountPriceValue() < product.getBasePriceValue();
}

// ga = null discount = 100
// ga = 100 discount = 100
// ga = 100 discount = 200
isPriceLessThenSaved(Product product, GameAttributes gameAttributes) async {
  if (product.getDiscountPriceValue() == null) {
    return false;
  }
  if (gameAttributes.discountedValue == null) {
    gameAttributes.discountedValue = product.getDiscountPriceValue();
    debugPrint("gameAttributes.discountedValue is null");
    debugPrint(
        "gameAttributes.discountedValue now ${gameAttributes.discountedValue}");
    await sqlWrapper.save(gameAttributes);
    return false;
  }
  if (product.getDiscountPriceValue() > gameAttributes.discountedValue!) {
    gameAttributes.discountedValue = product.getDiscountPriceValue();
    debugPrint("gameAttributes.discountedValue less then in data");
    debugPrint("${product.getDiscountPriceValue()} more then"
        "${gameAttributes.discountedValue}");
    debugPrint("gameAttributes.discountedValue less then in data");
    await sqlWrapper.save(gameAttributes);
    return false;
  }

  if (product.getDiscountPriceValue() < gameAttributes.discountedValue!) {
    gameAttributes.discountedValue = product.getDiscountPriceValue();
    debugPrint("gameAttributes.discountedValue more then in data");
    debugPrint("${product.getDiscountPriceValue()} less then"
        "${gameAttributes.discountedValue}");
    await sqlWrapper.save(gameAttributes);
    return true;
  }
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST
  await Firebase.initializeApp();

  // Then register the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint("init");

  await hiveWrapper.init();
  await sqlWrapper.migrateFromHiveIfNeeded(hiveWrapper);

  await NotificationService().init();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(GameChecker());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('notification payload: $task');
    //await sqlWrapper.close();
    await hiveWrapper.init();
    List<Data?> datas = await fetchDataV2(true);
    List<GameAttributes> gameAttributes = await sqlWrapper.readFromDb();
    var badgeCount = 0;
    for (final data in datas) {
      if (data == null || data.products.isEmpty) {
        continue;
      }
      var product = data.products.first;
      GameAttributes? gm =
          gameAttributes.firstWhereOrNull((i) => i.gameId == product.id);
      debugPrint("data :$data");
      debugPrint("gm :$gm");

      if (gm!.discountedValue == null) {
        gm.discountedValue = product.getDiscountPriceValue();
        await sqlWrapper.save(gm);
        //sqlWrapper.put(gm);
        debugPrint("gameAttributes.discountedValue is null");
        debugPrint("gameAttributes.discountedValue now ${gm.discountedValue}");
      }
      if (product.getDiscountPriceValue() == null) {
        continue;
      }
      if (product.getDiscountPriceValue()! > gm.discountedValue!) {
        gm.discountedValue = product.getDiscountPriceValue();
        await sqlWrapper.save(gm);
        debugPrint("gameAttributes.discountedValue less then in data");
        debugPrint("${product.getDiscountPriceValue()} more then"
            "${gm.discountedValue}");
      }
      if (product.getDiscountPriceValue() < gm.discountedValue!) {
        gm.discountedValue = product.getDiscountPriceValue();
        await sqlWrapper.save(gm);
        //sqlWrapper.put(gm);
        debugPrint("gameAttributes.discountedValue more then in data");
        debugPrint("${product.getDiscountPriceValue()} less then"
            "${gm.discountedValue}");
        NotificationService().showNotification(data);
        badgeCount = badgeCount + 1;
      }
      FlutterAppBadger.updateBadgeCount(badgeCount);
    }
    await sqlWrapper.flush();
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
  debugPrint("Handling a background message: ${message.messageId}");
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
      debugPrint(">>>>>>>>> refreshing");
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
    final ThemeData apptheme =
        ThemeData(primaryColor: Colors.white, brightness: Brightness.light);
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
      theme: apptheme,
      darkTheme: ThemeData.from(
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
        ),
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
  ScrollController _scrollController = ScrollController();
  void Function()? _resetGamesListSelection;

  _startTutorial(Future<dynamic> show) async {
    if (!await show) {
      var tutorialManager = TutorialManager(
        context: context,
        sharedPropWrapper: sharedPropWrapper,
      );
      tutorialManager.startMainTutorial();
    }
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await sqlWrapper.close();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
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
        debugPrint("state: resumed");
        //setState(() {
        isRefreshing = true;
        widget.notifyParent();
        // });

        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        debugPrint("state: paused");
        sqlWrapper.flush();
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
    _scrollController.addListener(_handleScroll);
    debugPrint("init State");
  }

  void _handleScroll() {
    if (_resetGamesListSelection != null) {
      _resetGamesListSelection!();
    }
  }

  void _setResetCallback(void Function() resetCallback) {
    _resetGamesListSelection = resetCallback;
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
                      .map((region) => new Text(
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
      backgroundColor: Colors.grey.withOpacity(0.4),
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
                            //debugPrint(snapshot.data.toString());
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
  RefreshController refreshController =
      RefreshController(initialRefresh: false);


  // Add a separate state for refresh loading

  @override
  Widget build(BuildContext context) {
    // debugPrint("_GameCheckerMainState");

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        //controller: _scrollController,
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
            //elevation: 0,
            // forceElevated: true,
            backgroundColor: Colors.white.withOpacity(0.6),
            leading: GestureDetector(
              key: settingKey,
              onTap: () {
                _showModalSheet();
              },
              child: Icon(Icons.settings,
                  size: 24.0, color: Color.fromARGB(255, 0, 114, 206)),
            ),
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    key: addKeyMain,
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/webView');
                      isRefreshing = true;
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
              isRefreshing = true;
              await Future.wait<void>([
                widget.notifyParent(),
                Future.delayed(Duration(
                    milliseconds: min((dataLength * 60).floor(), 3000))),
              ]);
              refreshController.refreshCompleted();
            },
          ),
          FutureBuilder<List<Data?>>(
              future: fetchDataV2(false),
              builder: (context, snapshot) {
                if (!isRefreshing &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  isRefreshing = false;
                  // Show a spinner while data is loading
                  return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.blue,
                          size: 35,
                        ), // Or any other spinner widget
                      ));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  isRefreshing = true;
                }
                if (snapshot.hasError) {
                  debugPrint(snapshot.error.toString());
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  debugPrint('show list');
                  isRefreshing = false;
                  return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 12, top: 13),
                      sliver: GamesList(
                        data: snapshot.data ?? [],
                        notifyParent: widget.notifyParent,
                        refreshList: refreshListButton,
                        setResetCallback: _setResetCallback,
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
                            splashColor: Colors.greenAccent,
                            icon: const Icon(Icons.add),
                            color: Colors.green,
                            onPressed: () async {
                              await Navigator.of(context).pushNamed('/webView');
                              isRefreshing = true;
                              widget.notifyParent();
                            },
                          ),
                          IconButton(
                            iconSize: 31,
                            splashColor: Colors.purpleAccent,
                            color: Colors.deepPurple,
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
