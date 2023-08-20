import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:ps_check/ga.dart';
import 'package:ps_check/spw.dart';
import 'package:tap_debouncer/tap_debouncer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'hive_wrapper.dart';
import 'main.dart';
import 'model.dart';
import 'dart:math';

//var box;
double iconSize = 25;
var buttonColor = Colors.black;
var hiveWrapper = HiveWrapper.instance();
var sharedPropWrapper = SharedPropWrapper.instance();

class InAppWebview extends StatefulWidget {
  @override
  _InAppWebviewState createState() => new _InAppWebviewState();
}

class _InAppWebviewState extends State<InAppWebview> {
  late FToast fToast;
  late TutorialCoachMark tutorialCoachMark;

  late InAppWebViewController webView;
  CookieManager cookieManager = CookieManager.instance();

  double progress = 0;
  var gameId;
  var showBlankScreen = false;

  Future<GameAttributes> saveInDb(Future<dynamic> gameAttributes) async {
    GameAttributes gm = await gameAttributes;
    //showSaveDialog(context);
    await hiveWrapper.putIfNotExist(gm);
    fToast.showToast(
      toastDuration: Duration(milliseconds: 500),
      child: Material(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          child: Container(
            width: 55,
            height: 55,
            child: Padding(
              // padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  //Text('added', style: TextStyle(fontSize: 20),),
                  Icon(
                    Icons.save,
                    color: Color(0xC4000000).withOpacity(0.93),
                    size: 50,
                  )
                ],
              ),
            ),
          )),
      gravity: ToastGravity.CENTER,
    );
    return gm;
  }

  @override
  void initState() {
    super.initState();
    _startTutorial();
    fToast = FToast();
    fToast.init(context);
  }

  getRegion() async {
    return await sharedPropWrapper.readRegion();
  }

  _startTutorial() async {
    if (!await sharedPropWrapper.readTutorialFlagWeb()) {
      initTarget();
      WidgetsBinding.instance.addPostFrameCallback(_layout);
    }
  }

  getWebView(){
    return webView;
  }

  void _layout(_) {
    Future.delayed(Duration(milliseconds: 100));
    showTutorial();
  }

  List<TargetFocus> targets = [];

  GlobalKey doneKey = GlobalKey();
  GlobalKey addKey = GlobalKey();
  GlobalKey browserKey = GlobalKey();

  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.pink,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        sharedPropWrapper.saveTutorialFlagWeb(true);
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
    )..show(context: context);
  }

  Offset getPosition() {
    return Offset(0, 100);
  }

  initTarget() {
    targets.add(
      TargetFocus(
        identify: "find game",
        targetPosition: TargetPosition(Size(700, 400), getPosition()),
        //keyTarget: browserKey,
        color: Colors.purple,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                      width: 200.0,
                      height: 300.0,
                      child: Text(
                        "Find the page of the game you want to track",
                        style: TextStyle(
                          //fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      )),
                ],
              ),
            ),
          )
        ],
        shape: ShapeLightFocus.RRect,
        radius: 0,
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Add game",
        keyTarget: addKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        color: Colors.green,
        contents: [
          TargetContent(
              align: ContentAlign.top,
              child: Container(
                  child: new Align(
                      alignment: FractionalOffset.bottomRight,
                      child: SizedBox(
                        width: 200.0,
                        height: 300.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              "Tap save on the page of the selected game",
                              style: TextStyle(
                                //fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20.0),
                              // )
                            ),
                            Text(
                              "If the page contains multiple game cards, "
                                  "a pop-up window with a selection of games will appear",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15.0),
                            ),
                          ],
                        ),
                      ))))
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Done",
        keyTarget: doneKey,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        color: Colors.cyan,
        contents: [
          TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                        width: 200.0,
                        height: 300.0,
                        child: Padding(
                            padding: const EdgeInsets.only(top: 30.0, left: 30),
                            child: Text(
                              "Click here to get back to list of selected games",
                              style: TextStyle(
                                //fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20.0),
                            ))),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: sharedPropWrapper.readRegion(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return WillPopScope(
              onWillPop: () async => false,
              child: Scaffold(
                extendBody: true,
                appBar: PreferredSize(
                    preferredSize: Size.fromHeight(40.0),
                    child: AppBar(
                      elevation: 0.0,
                      backgroundColor: Color(0xECF1F1F1),
                      leadingWidth: 80,
                      toolbarHeight: 44,
                      leading: TextButton(
                        key: doneKey,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Done',
                            style: TextStyle(
                                fontSize: 17,
                                color: Color.fromARGB(255, 0, 114, 206))),
                      ),
                      centerTitle: true,
                    )),
                body: Container(
                    child: showBlankScreen
                        ? Center(
                        child: SizedBox(
                            width: 300.0,
                            height: 300.0,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      "Sorry, you switched to PlayStation.com by mistake, "
                                          "it may have been in search, please return to PlayStation Store"),
                                  IconButton(
                                    iconSize: 28,
                                    splashColor: Colors.green,
                                    icon: const Icon(Icons.home_rounded),
                                    onPressed: () {
                                      setState(() {
                                        showBlankScreen = !showBlankScreen;
                                      });
                                    },
                                  )
                                ])))
                        : Column(children: <Widget>[
                      Container(
                          child: progress < 1.0
                              ? LinearProgressIndicator(
                            value: progress,
                            minHeight: 2,
                            backgroundColor: Colors.lightBlueAccent,
                            valueColor: AlwaysStoppedAnimation<
                                Color>(
                                Color.fromARGB(255, 0, 114, 206)),
                          )
                              : Container()),
                      Container(
                        child: Expanded(
                          child: InAppWebView(
                            key: browserKey,
                            initialUrlRequest: URLRequest(
                                url: Uri.parse(
                                    'https://store.playstation.com/'
                                        '${snapshot.data}'
                                        '/latest')),
                            initialOptions: InAppWebViewGroupOptions(
                                crossPlatform: InAppWebViewOptions(
                                    useShouldOverrideUrlLoading: true
                                )),
                            onWebViewCreated:
                                (InAppWebViewController controller) {
                              webView = controller;
                              webView.clearCache();
                              cookieManager.setCookie(
                                  url: Uri.parse(
                                      "https://store.playstation.com"),
                                  name: "eucookiepreference",
                                  value: "reject",
                                  domain: ".playstation.com",
                                  isHttpOnly: false);
                            },
                            onLoadStart:
                                (InAppWebViewController controller,
                                Uri? uri) {
                              var url = uri.toString().split('/')[2];
                              if (url == "www.playstation.com") {
                                setState(() {
                                  showBlankScreen = !showBlankScreen;
                                });
                              }
                            },
                            onProgressChanged:
                                (InAppWebViewController controller,
                                int progress) {
                              setState(() {
                                this.progress = progress / 100;
                              });
                            },
                          ),
                        ),
                      ),
                    ])),
                bottomNavigationBar: MyBottomAppBar(saveAction: saveGame,
                  getWebViewAction: getWebView,),
              ));
        } else {
          return CircularProgressIndicator();
        }
      });

  // Widget getBottomLine() {
  //   return BottomAppBar(
  //     shape: CircularNotchedRectangle(),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: <Widget>[
  //     Expanded(
  //     child:
  //         TextButton(
  //           style: TextButton.styleFrom(primary: buttonColor),
  //           child: Icon(Icons.arrow_back, size: iconSize),
  //           onPressed: () {
  //             if (webView != null) {
  //               webView.goBack();
  //             }
  //           },
  //         )),
  //   Expanded(
  //   child:
  //         TextButton(
  //           style: TextButton.styleFrom(primary: buttonColor),
  //           child: Icon(Icons.arrow_forward, size: iconSize),
  //           onPressed: () {
  //             if (webView != null) {
  //               webView.goForward();
  //             }
  //           },
  //         )),
  //   Expanded(
  //   child:
  //         TextButton(
  //           style: TextButton.styleFrom(primary: buttonColor),
  //           child: Icon(Icons.refresh, size: iconSize),
  //           onPressed: () {
  //             if (webView != null) {
  //               webView.reload();
  //             }
  //           },
  //         )),
  //   Expanded(
  //   child:
  //         TapDebouncer(onTap: () async {
  //           //GameAttributes gm;
  //           if (webView != null) {
  //             //gm = await saveInDb(_prepareAttributes(webView.getUrl()));
  //             // Navigator.of(context)
  //             //     .pop(_prepareAttributes(webView.getUrl()));
  //           }
  //          // saveGame(webView.getUrl());
  //          // await Future<void>.delayed(const Duration(milliseconds: 1000));
  //         },
  //             builder: (BuildContext context, TapDebouncerFunc? onTap) {
  //           return TextButton(
  //               key: addKey,
  //               style: TextButton.styleFrom(primary: buttonColor),
  //               child:  ButtonSave(saveAction: saveGame),
  //               onPressed: onTap);
  //         }))
  //       ],
  //     ),
  //     color: Colors.white.withOpacity(0.9),
  //   );
  // }

  saveGame() async {
    GameAttributes gm = await _prepareAttributes(await webView.getUrl());
    if(gm.imgUrl == ""){
      return;
    }
    Map details = await getGameInfo(await webView.getUrl());
    if (details['size'] > 1) {
      List<Product> products = (await getOptions(gm))
          .productRetrieve!
          .concept!
          .products!
          .where((p) => p.webctas!.length > 0)
          .where((p) => p.webctas![0].type != "CHOOSE_A_VERSION")
          .where((p) => p.webctas![0].price!.basePrice != null)
          .toList();
      if (products.length == 1) {
        await saveInDb(_prepareAttributes(await webView.getUrl()));
      } else {
        for (final product in products) {
          if (await hiveWrapper.getByIdFromDb(product.id) != null) {
            product.isSelected = true;
          }
        }
        products.sort((a, b) {
          if (a.webctas![0].price!.discountedValue == null &&
              b.webctas![0].price!.discountedValue == null) {
            return 0;
          }
          if (a.webctas![0].price!.discountedValue == null) {
            return 1;
          }
          if (b.webctas![0].price!.discountedValue == null) {
            return -1;
          }
          return a.webctas![0].price!.discountedValue!
              .compareTo(b.webctas![0].price!.discountedValue!);
        });
        showModalSheet(products);
      }
    } else {
      await saveInDb(_prepareAttributes(await webView.getUrl()));
    }
  }

  Future<Data> getOptions(GameAttributes gm) async {
    print("start retrieving");
    Map<String, String> headers = {
      "X-Psn-Store-Locale-Override": await sharedPropWrapper.readRegion()
    };
    http.Response response = await http.Client()
        .get(Uri.parse(getUrl(gm.gameId, gm.type)), headers: headers);
    Game? game = convertToGame(gm);
    return Future.value(Data.fromJson(response.body, game!));
  }

  Future<Map> getGameInfo(Uri? url) async {
    print("start retrieving");
    Map<String, String> headers = {
      "X-Psn-Store-Locale-Override": await sharedPropWrapper.readRegion()
    };
    http.Response response = await http.Client().get(url!, headers: headers);
    var document = parse(response.body);
    var details = new Map();
    details['size'] = document.getElementsByTagName("article").length;
    details['title'] = document.getElementsByClassName("psw-t-title-m")[0].nodes[0].toString();
    return details;
  }

  Size calcTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: WidgetsBinding.instance.window.textScaleFactor,
    )..layout();
    return textPainter.size;
  }

  static int roundUpAbsolute(double number) {
    return number.isNegative ? number.floor() : number.ceil();
  }

  getWidth(List<Product> products) {
    return products.map((product)  {
      var widthList = calcTextSize(product.webctas![0].price!.basePrice!, TextStyle(fontSize: 16)).width;
     return widthList;}
    ).reduce(max)+8;
  }

  getHigh(List<Product> products) {
    //390
    // 23 symb
    //16.95
    //428
    // 30 symb
    //14.26
    print('width of screen: ${MediaQuery.of(context).size.width}');
    // print('text height:  ${calcTextSize(products[0].name!, TextStyle(fontSize: 16)).height}');
    // print('text screenWidth >> ${products[0].name!} >>  '
    //     '${}');

    var screenWidth = MediaQuery.of(context).size.width;
    double high = (screenWidth *13) /100;
    var rowHeight = calcTextSize(products[0].name!, TextStyle(fontSize: 16)).height + 12;
    //print(base);
    //57%
    print('init high: $high');
    products.forEach((pr)  {
      var textWidth = calcTextSize(pr.name!, TextStyle(fontSize: 16)).width;
      print('text width: $textWidth');
      var minWidth = (screenWidth * 61) / 100;
      print('min width: $minWidth');
      print('division: ${ textWidth/ minWidth })');
      var times = pr.platforms!.length > roundUpAbsolute(textWidth/ minWidth)
          ? pr.platforms!.length : roundUpAbsolute(textWidth/ minWidth);
      print('how many times: $times');
      high = high + (times * rowHeight) ;
      print('------');
    });
    print('#####');
    print(high);
    print('#####');
    return high;
  }

  showModalSheet(List<Product> products) {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter myState) {
            return Container(
              height: (getHigh(products)).toDouble(),
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (BuildContext c, int index) {
                          return GestureDetector(
                            onTap: () async {
                              if (products[index].isSelected!) {
                                await hiveWrapper
                                    .removeFromDb(products[index].id!);
                              } else {
                                await saveInDb(_prepareAttributesFromProduct(
                                    products[index]));
                              }
                              myState(() {
                                products[index].isSelected =
                                    !products[index].isSelected!;
                              });
                            },
                            child: Container(
                                decoration: products[index].isSelected!
                                    ? BoxDecoration(
                                        color: Colors.lightBlue,
                                      )
                                    : BoxDecoration(
                                        color: Colors.white,
                                      ),
                                padding: EdgeInsets.all(3),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                              width: 40,
                                              padding: EdgeInsets.all(6),
                                              child: Text(
                                                  products[index]
                                                      .platforms!
                                                      .join('\n'),
                                                  style:
                                                      TextStyle(fontSize: 13)))
                                          //)
                                          ),
                                      Flexible(
                                          flex: 3,
                                          child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text(
                                                      products[index].name!,
                                                      style: TextStyle(
                                                          fontSize: 16))))),
                                    Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                  width: getWidth(products),
                                                  padding: EdgeInsets.all(4),
                                                  child: Text(
                                                      products[index]
                                                          .webctas![0]
                                                          .price!
                                                          .basePrice!,
                                                      style: TextStyle(
                                                          fontSize: 16))))
                                    ])),
                          );
                        }),
                  )
                ],
              ),
            );
          });
        });
  }
}

String getUrl(String id, GameType type) {
  print("id $id");
  switch (type) {
    case GameType.PRODUCT:
      return "https://web.np.playstation.com/api/graphql/v1/op?"
          "operationName=productRetrieveForUpsellWithCtas"
          "&variables=%7B%22productId%22%3A%22"
          "$id"
          "%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%22bedffc84f86faddaf8897c2a19e3a3308cf58aecd772a4a363fe438fa18ed45f%22%7D%7D";
    case GameType.CONCEPT:
      return "https://web.np.playstation.com/api/graphql/v1/op?"
          "operationName=conceptRetrieveForUpsellWithCtas"
          "&variables=%7B%22conceptId%22%3A%22"
          "$id"
          "%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%224460d00afbeeb676c0d6ef3365b73d1c4f122378b175d6fda13b8ee07ca1d0a2%22%7D%7D";
  }
}

_prepareAttributes(Uri? futureUrl) async {
  return new GameAttributes(
      gameId: await _getGameId(futureUrl),
      imgUrl: await _getGameImageUrl(futureUrl),
      type: (await _getType(futureUrl)),
      url: (await futureUrl).toString());
}

_prepareAttributesFromProduct(Product product) async {
  String region = await sharedPropWrapper.readRegion();
  return new GameAttributes(
      gameId: product.id!,
      imgUrl:
      product.media!.firstWhere((m) => m.role == "MASTER").url! + "?w=250",
      type: GameType.PRODUCT,
      url: "https://store.playstation.com/$region/product/" + product.id!);
}

_getGameImageUrl(Uri? futureUrl) async {
  Uri url = futureUrl!;
  final response = await http.get(url);
  dom.Document document = parser.parse(response.body);
  //gameBackgroundImage#tileImage#image
  var imgElement = document
      .querySelector('img[data-qa="gameBackgroundImage#heroImage#preview"]');
  if (imgElement == null) {
    imgElement = document
        .querySelector('img[data-qa="gameBackgroundImage#tileImage#preview"]');
  }
  if (imgElement == null) {
    return "";
  }
  String imageUrl = imgElement!.attributes['src']!;
  return imageUrl.substring(0, imageUrl.indexOf("?")) + "?w=250";
}

_getGameId(Uri? url) async {
  var urlList = url.toString().split('/');
  if (urlList.last.isEmpty) {
    return urlList[urlList.length - 2];
  }
  return urlList.last;
}

_getType(Uri? url) async {
  var str = url!.toString();
  if (str.substring(str.length - 1, str.length) == '/') {
    str = str.substring(0, str.length - 1);
  }
  var urlList = str.split('/');
  if (urlList[urlList.length - 2] == 'concept') {
    return GameType.CONCEPT;
  }
  return GameType.PRODUCT;
}

showSaveDialog(var context) {
  showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        Future.delayed(Duration(milliseconds: 400), () {
          Navigator.of(context).pop(true);
        });
        return
          Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.0)),
              backgroundColor: Colors.white.withOpacity(0.93),
              // insetPadding: EdgeInsets.symmetric(horizontal: 160),
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                //clipBehavior: Clip.antiAlias,
                alignment: Alignment.topCenter,
                children: [
                  //   new BackdropFilter(
                  // filter: new ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  //  child:
                  Container(
                    width: double.infinity,
                    height: 55,
                    child: Padding(
                      // padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        children: [
                          //Text('added', style: TextStyle(fontSize: 20),),
                          Icon(
                            Icons.save,
                            color: Color(0xC4000000).withOpacity(0.93),
                            size: 50,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )
          );
      });
}

class MyBottomAppBar extends StatefulWidget {
  final Function() saveAction;
  final Function() getWebViewAction;

  MyBottomAppBar({Key? key, required this.saveAction, required this.getWebViewAction} )
      : super(key: key);

  @override
  _MyBottomAppBarState createState() => _MyBottomAppBarState();
}

class _MyBottomAppBarState extends State<MyBottomAppBar> {
  bool _isLoading = false;

  void _onButtonPressed() async {
    setState(() {
      _isLoading = true;
    });
    await widget.saveAction();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      //color: Colors.white,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.3),
            child: Row(
              //mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: iconSize, color: buttonColor,),
                  onPressed: () {
                    (widget.getWebViewAction() as InAppWebViewController).goBack();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, size: iconSize, color: buttonColor,),
                  onPressed: () {
                    (widget.getWebViewAction() as InAppWebViewController).goForward();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: iconSize, color: buttonColor,),
                  onPressed: () {
                    (widget.getWebViewAction() as InAppWebViewController).reload();
                    },
                ),
                IconButton(
                  icon: _isLoading ?
                  SizedBox(
                      height: 25.0,
                      width: 25.0,
                      child:
                  CircularProgressIndicator(
                    color: Colors.blueAccent,
                    strokeWidth: 3,
                  ))
                      : Icon(Icons.add_box_outlined, size: 30 , color: Colors.blueAccent),
                  onPressed: () {
                    _onButtonPressed();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}