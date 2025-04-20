import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart' as parser;
import 'package:collection/src/iterable_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ps_check/bottomModalSize.dart';
import 'package:ps_check/ga.dart';
import 'package:ps_check/spw.dart';
import 'package:ps_check/tutorialManager.dart';
import 'package:html/dom.dart' as dom;

import 'bottomSearch.dart';
import 'hive_wrapper.dart';
import 'main.dart';
import 'model.dart';

//var box;
double iconSize = 27;
var buttonColor = Colors.black;
var hiveWrapper = HiveWrapper.instance();
var sharedPropWrapper = SharedPropWrapper.instance();
String searchText = "";

GlobalKey doneKey = GlobalKey();
GlobalKey addKey = GlobalKey();
GlobalKey browserKey = GlobalKey();
GlobalKey searchKey = GlobalKey();

class GameBrowsingScreen extends StatefulWidget {
  final url;

  GameBrowsingScreen(this.url);

  @override
  _GameBrowsingScreenState createState() =>
      new _GameBrowsingScreenState(this.url);
}

class _GameBrowsingScreenState extends State<GameBrowsingScreen> {
  var _url;
  late FToast fToast;

  _GameBrowsingScreenState(this._url);

  late InAppWebViewController webView;
  CookieManager cookieManager = CookieManager.instance();

  double progress = 0;

  var showBlankScreen = false;

  Future<GameAttributes> saveInDb(Future<dynamic> gameAttributes) async {
    GameAttributes gm = await gameAttributes;
    //showSaveDialog(context);
    await hiveWrapper.putIfNotExist(gm);
    _showToast(Icons.save, Color(0xC4000000).withOpacity(0.93));
    return gm;
  }

  _showToast(IconData icon, Color color) {
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
                    icon,
                    color: color,
                    size: 50,
                  )
                ],
              ),
            ),
          )),
      gravity: ToastGravity.CENTER,
    );
  }

  @override
  void initState() {
    super.initState();
    _startTutorial();
    deleteAllCookies();
    fToast = FToast();
    fToast.init(context);
  }

  Future<void> deleteAllCookies() async {
    await cookieManager.deleteAllCookies();
  }

  getRegion() async {
    return await sharedPropWrapper.readRegion();
  }

  _startTutorial() async {
    if (!await sharedPropWrapper.readTutorialFlagWeb()) {
      var tutorialManager = TutorialManager(
        context: context,
        sharedPropWrapper:
            sharedPropWrapper, // Ensure you have this class defined
      );
      tutorialManager.startWebTutorial();
    }
  }

  getWebView() {
    return webView;
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
          return PopScope(
              canPop: false,
              child: Scaffold(
                  extendBody: true,
                  appBar: PreferredSize(
                      preferredSize: Size.fromHeight(40.0),
                      child: AppBar(
                        elevation: 0.0,
                        backgroundColor: Color(0xECF1F1F1),
                        leadingWidth: 70,
                        toolbarHeight: 44,
                        leading: TextButton(
                          key: doneKey,
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Done',
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  color: Color.fromARGB(255, 0, 114, 206))),
                        ),
                        // actions: <Widget>[
                        //   Padding(
                        //       padding: EdgeInsets.only(right: 20.0),
                        //       child: GestureDetector(
                        //         key: searchKey,
                        //         onTap: () async {
                        //           final result = await Navigator.push(
                        //             context,
                        //             CupertinoPageRoute(
                        //                 builder: (context) => SearchScreen()),
                        //           );
                        //           if (result != null) {
                        //             setState(() {
                        //               _url = result;
                        //             });
                        //           } else {
                        //             _url = 'BASE_URl';
                        //           }
                        //           webView.loadUrl(
                        //               urlRequest: URLRequest(
                        //                   url: WebUri(_url == 'BASE_URL'
                        //                       ? 'https://store.playstation.com/'
                        //                           '${snapshot.data}'
                        //                           '/latest'
                        //                       : _url)));
                        //         },
                        //         child: Icon(
                        //           Icons.search,
                        //           size: iconSize,
                        //           color: buttonColor,
                        //         ),
                        //       ))
                        // ],
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
                                            "please return to PlayStation Store"),
                                        IconButton(
                                          iconSize: 28,
                                          splashColor: Colors.green,
                                          icon: const Icon(Icons.home_rounded),
                                          onPressed: () {
                                            setState(() {
                                              showBlankScreen =
                                                  !showBlankScreen;
                                              webView.loadUrl(
                                                  urlRequest: URLRequest(
                                                      url: WebUri(_url ==
                                                              'BASE_URL'
                                                          ? 'https://store.playstation.com/'
                                                              '${snapshot.data}'
                                                              '/latest'
                                                          : _url)));
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
                                          backgroundColor:
                                              Colors.lightBlueAccent,
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
                                        url: WebUri(_url == 'BASE_URL'
                                            ? 'https://store.playstation.com/'
                                                '${snapshot.data}'
                                                '/latest'
                                            : _url)),
                                    initialSettings: InAppWebViewSettings(
                                        userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) "
                                            "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                                            "Version/16.0 Mobile/15E148 Safari/604.1",
                                        //  useShouldOverrideUrlLoading: true,
                                        allowsBackForwardNavigationGestures:
                                            true),
                                    onWebViewCreated:
                                        (InAppWebViewController controller) {
                                      webView = controller;
                                      webView.clearCache();
                                      setCookie2();
                                    },
                                    onLoadStart: (controller, uri) {
                                      setCookie2();
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
                                    onLoadStop: (controller, url) async {
                                      await controller
                                          .evaluateJavascript(source: """
                  document.getElementById('sony-bar').style.display = 'none';
                  document.getElementById('shared-nav-root').style.display = 'none';
                  var footer = document.getElementsByTagName('footer')[0];
                  footer.parentNode.removeChild(footer);
                """);
                                    },
                                  ),
                                ),
                              ),
                            ])),
                  bottomNavigationBar: MyBottomAppBar(
                    saveAction: saveGame,
                    getWebViewAction: getWebView,
                  )));
        } else {
          return CircularProgressIndicator();
        }
      });

  void setCookie2() async {
    // await cookieManager1.removeSessionCookies();
    await cookieManager.setCookie(
      url: WebUri('https://store.playstation.com'),
      name: "_evidon_consent_cookie",
      value: "date",
      expiresDate: DateTime.now().add(Duration(days: 5)).microsecondsSinceEpoch,
      isSecure: true,
    );
  }

  saveGame() async {
    GameAttributes gm = await _prepareAttributes(await webView.getUrl());

    //List<Product> addons = await getAddons(await webView.getUrl());

    Data? gameData = await getGameData(gm);
    if (gameData == null) {
      _showToast(Icons.dangerous_outlined, Color(0xC4FF1616).withOpacity(0.93));
      return;
    }
    if (gameData.products.isEmpty) {
      _showToast(Icons.dangerous_outlined, Color(0xC4FF1616).withOpacity(0.93));
      return;
    }
    if (gameData.products.isNotEmpty && gameData.products.first.media == null) {
      _showToast(Icons.dangerous_outlined, Color(0xC4FF1616).withOpacity(0.93));
      return;
    }

    List<Product> products = gameData.products;
    if (gameData.products.length == 1) {
      gm.imgUrl = _getGameImageUrl(products.first);
      gm.gameId = products.first.productType == ProductType.ADD_ON
          ? gm.gameId
          : products.first.id!;
      gm.type = products.first.productType == ProductType.ADD_ON
          ? GameType.ADD_ON
          : GameType.PRODUCT;
      gm.addon = products.first.productType == ProductType.ADD_ON;
      await saveInDb(Future.value(gm));
      return;
    }

    for (final product in products) {
      if (await hiveWrapper.getByIdFromDb(product.id) != null) {
        product.isSelected = true;
      }
    }

    products.sort((a, b) {
      if (a.getDiscountPriceValue() == null &&
          b.getDiscountPriceValue() == null) {
        return 0;
      }
      if (a.getDiscountPriceValue() == null) {
        return 1;
      }
      if (b.getDiscountPriceValue() == null) {
        return -1;
      }
      return a.getDiscountPriceValue()!.compareTo(b.getDiscountPriceValue()!);
    });
    showModalSheet(products);
  }

  getAddons(WebUri? uri) async {
    http.Response response = await requestDate(uri);
    dom.Document document = parser.parse(response.body);

    List<Product> products = [];

    List<dom.Element> links = document
        .querySelectorAll("section.psw-product-tile__details.psw-m-t-2");

    for (var link in links) {
      dom.Element? spanName = link.querySelector(
          "span.psw-t-body.psw-c-t-1.psw-t-truncate-2.psw-m-b-2");
      String? gameName;
      if (spanName != null) {
        gameName = spanName.nodes[0].text;
      }

      String? price;

      var elementsByClassName = link.getElementsByClassName("psw-m-r-3");
      if (elementsByClassName.length > 0) {
        price = elementsByClassName[0].text;
      }

      String? imageUrl;
      var querySelector = link.parent!.querySelector("img");
      if (querySelector != null && querySelector.attributes["src"] != null) {
        imageUrl = querySelector.attributes["src"].toString().split('?')[0];
      }

      String? productId;
      var aTag;
      var metaJson;
      if (link.parent != null &&
          link.parent!.parent != null &&
          link.parent!.parent!.parent != null) {
        aTag = link.parent!.parent!.parent!
            .querySelectorAll("a.psw-link.psw-content-link");
        if (aTag.length > 0) {
          metaJson = aTag[0].attributes['data-telemetry-meta'];
        }
      }
      if (metaJson != null) {
        productId = json.decode(metaJson)["tile"]?["productId"];
        if (productId == null) {
          productId = json.decode(metaJson)["productId"];
        }
      }

      List<String> platforms = [];

      if (link.parent != null && link.parent!.parent != null) {
        var platformDivs = link.parent!.parent!.querySelectorAll(
            "span.psw-platform-tag.psw-p-x-2.psw-l-line-left.psw-t-tag.psw-on-graphic");
        for (var platform in platformDivs) {
          platforms.add(platform.text);
        }
      }
      int priceInt = extractNumbers(price);

      if (imageUrl != null &&
          price != null &&
          gameName != null &&
          priceInt != 0) {
        products.add(Product(
            media: [Media(role: "MASTER", url: imageUrl)],
            id: productId,
            platforms: platforms.length == 0 ? [""] : platforms,
            name: gameName,
            price: Price(
                basePrice: price, basePriceValue: extractNumbers(price))));
      }
    }
    return products;
  }

  extractNumbers(String? price) {
    if (price == null) {
      return 0;
    }
    String clean = price
        .replaceAll(RegExp(r'[^\d,\.]'), '')
        .replaceAll(',', '.')
        .replaceAll(' ', '');
    if (clean.isEmpty) {
      return 0;
    }
    double value = double.parse(clean) * 100;
    return value.toInt();
  }

  Future<Data?> getGameData(GameAttributes gm) async {
    debugPrint("start retrieving");
    var conceptId;
    Data dataProduct;
    if (gm.type == GameType.PRODUCT) {
      http.Response response = await requestDate(getUrl(gm.gameId, gm.type));
      dataProduct = Data.fromJson(json.decode(response.body));
      if (dataProduct.products.first.productType == ProductType.ADD_ON) {
        gm.addon = true;
        gm.type = GameType.ADD_ON;
        response = await requestDate(getUrl(gm.gameId, gm.type));
        var data = Data.fromJson(json.decode(response.body));
        if(data.products.first.media == null) {
          data.products.first.media = dataProduct.dataMedia;
        }
        return data;
      }
      conceptId = dataProduct.conceptId;
    } else {
      conceptId = gm.gameId;
    }
    http.Response response =
        await requestDate(getUrl(conceptId, GameType.CONCEPT));
    return Data.fromJson(json.decode(response.body));
  }

  isIdExist(List products, String id) {
    return products.firstWhereOrNull((product) => product[id] == id) == null
        ? false
        : true;
  }

  static Size calcTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: WidgetsBinding.instance.window.textScaleFactor,
    )..layout();
    return textPainter.size;
  }

  static double getColumnWidth(List<Product> products, double mainTextSize) {
    var textWidth = 0.0;
    products.forEach((pr) {
      var width =
          calcTextSize(pr.price!.basePrice!, TextStyle(fontSize: mainTextSize))
              .width;
      textWidth = width > textWidth ? width : textWidth;
    });
    return textWidth;
  }

  static int getTextLinesCount(
      Product products, double textSize, double columnWidth) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: products.name, style: TextStyle(fontSize: textSize)),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: columnWidth);

    List<ui.LineMetrics> lines = textPainter.computeLineMetrics();
    return lines.length;
  }

  BottomModalSize getSizes(List<Product> products) {
    // 10, 70, 20
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    var paddingWidth = screenWidth * 0.01;
    var paddingHeight = screenWidth * 0.012;
    var mainTextSize = screenHeight * 0.019;
    var auxiliaryTextSize = screenHeight * 0.0135;

    var platformWidth = screenWidth * 0.08;
    var priceWidth =
        getColumnWidth(products, mainTextSize) + (paddingWidth * 2);
    var nameWidth =
        screenWidth - platformWidth - priceWidth - (paddingWidth * 6);

    double height = 0.0;

    products.forEach((pr) {
      var platformTextHeight = calcTextSize(
              pr.platforms!.first, TextStyle(fontSize: auxiliaryTextSize))
          .height;
      var spaceBetweenPlatformText = pr.platforms!.length > 1
          ? (platformTextHeight * 1.2) - platformTextHeight
          : 0;
      var platformHeight = (platformTextHeight * pr.platforms!.length +
          spaceBetweenPlatformText);

      var nameRowCount = getTextLinesCount(pr, mainTextSize, nameWidth);
      var textHeight =
          calcTextSize(pr.name!, TextStyle(fontSize: mainTextSize)).height;

      if (nameRowCount > 1) {
        // var spaceBetweenNameText = ((textHeight * 1.2) - textHeight) * (nameRowCount -1);
        height = height + (nameRowCount * textHeight) + (paddingHeight * 2);
      } else {
        height = height +
            (pr.platforms!.length > 1 ? platformHeight : textHeight) +
            (paddingHeight * 2);
      }
    });
    debugPrint('#####');
    debugPrint(height.toString());
    debugPrint('#####');

    return BottomModalSize(
      height: height + MediaQuery.of(context).size.width * 0.2,
      auxiliaryTextSize: auxiliaryTextSize,
      mainTextSize: mainTextSize,
      platformWidth: platformWidth + paddingWidth,
      nameWidth: nameWidth,
      priceWidth: priceWidth,
    );
  }

  showModalSheet(List<Product> products) {
    var sizes = getSizes(products);
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter myState) {
            return Container(
              height: sizes.height,
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: getOptionsListForBottom(
                        products, myState, context, sizes),
                  )
                ],
              ),
            );
          });
        });
  }

  ListView getOptionsListForBottom(List<Product> products, StateSetter myState,
      BuildContext context, BottomModalSize sizes) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        // Change divider color and height as needed
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (BuildContext c, int index) {
          return GestureDetector(
              onTap: () async {
                if (products[index].isSelected!) {
                  await hiveWrapper.removeFromDb(products[index].id!);
                } else {
                  await saveInDb(
                      _prepareAttributesFromProduct(products[index]));
                }
                myState(() {
                  products[index].isSelected = !products[index].isSelected!;
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.fromLTRB(
                            MediaQuery.of(context).size.width * 0.01,
                            MediaQuery.of(context).size.width * 0.012,
                            0,
                            MediaQuery.of(context).size.width * 0.012),
                        child: Container(
                            width: sizes.platformWidth,
                            child: Center(
                              child: Text(products[index].platforms!.join('\n'),
                                  style: TextStyle(
                                      fontSize: sizes.auxiliaryTextSize),
                                  textAlign: TextAlign.center),
                            ))),
                    Padding(
                        padding: EdgeInsets.fromLTRB(
                            MediaQuery.of(context).size.width * 0.01,
                            MediaQuery.of(context).size.width * 0.012,
                            MediaQuery.of(context).size.width * 0.01,
                            MediaQuery.of(context).size.width * 0.012),
                        child: Container(
                          width: sizes.nameWidth,
                          child: Text(products[index].name!,
                              style: TextStyle(fontSize: sizes.mainTextSize)),
                        )),
                    Padding(
                        padding: EdgeInsets.fromLTRB(
                            0,
                            MediaQuery.of(context).size.width * 0.012,
                            MediaQuery.of(context).size.width * 0.01,
                            MediaQuery.of(context).size.width * 0.012),
                        child: Container(
                          width: sizes.priceWidth,
                          child: Text(products[index].price!.basePrice!,
                              style: TextStyle(fontSize: sizes.mainTextSize)),
                        )),
                  ],
                ),
              ));
        });
  }
}

_prepareAttributes(Uri? futureUrl) async {
  return GameAttributes(
      gameId: _getGameId(futureUrl),
      type: _getType(futureUrl),
      url: futureUrl.toString(),
      addon: false);
}

_prepareAttributesFromProduct(Product product) async {
  String region = await sharedPropWrapper.readRegion();
  return GameAttributes(
      gameId: product.id!,
      imgUrl: _getGameImageUrl(product),
      type: product.productType == ProductType.ADD_ON
          ? GameType.ADD_ON
          : GameType.PRODUCT,
      addon: product.productType == ProductType.ADD_ON,
      conceptId: product.conceptId,
      url: "https://store.playstation.com/$region/product/" + product.id!);
}

_getGameImageUrl(Product product) {
  Media? image =
      product.media?.firstWhereOrNull((m) => m.role == "PORTRAIT_BANNER");
  if (image == null) {
    image = product.media?.firstWhereOrNull((m) => m.role == "MASTER");
  }
  return image!.url! + "?w=250";
}

_getGameId(Uri? url) {
  var urlList = url.toString().split('/');
  if (urlList.last.isEmpty) {
    return urlList[urlList.length - 2];
  }
  return urlList.last;
}

_getType(Uri? url) {
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

class MyBottomAppBar extends StatefulWidget {
  final Function() saveAction;
  final Function() getWebViewAction;

  MyBottomAppBar(
      {Key? key, required this.saveAction, required this.getWebViewAction})
      : super(key: key);

  @override
  _MyBottomAppBarState createState() => _MyBottomAppBarState();
}

class _MyBottomAppBarState extends State<MyBottomAppBar> {
  bool _isLoading = false;

  bool tappedBtn1 = false;
  bool tappedBtn2 = false;
  bool tappedBtn3 = false;
  bool tappedBtn4 = false;
  bool tappedBtn5 = false;

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
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = screenHeight * 0.085;
    double iconSizeBtn = screenHeight * 0.0285;
    var left = (screenWidth / 5 - iconSizeBtn - 15) / 2;
    var right = (screenWidth / 5 - iconSizeBtn - 15) / 2;

    return Container(
      height: appBarHeight,
      //color: Colors.white,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.6),
            //  height: appBarHeight - 10,
            child: Row(
              //mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      tappedBtn1 = true;
                    });
                    Future.delayed(Duration(milliseconds: 120), () {
                      setState(() {
                        tappedBtn1 = false;
                      });
                    });
                    (widget.getWebViewAction() as InAppWebViewController)
                        .goBack();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent)),
                      // width: 75.0, // Adjust the width as needed
                      // height: 50.0, // Adjust the height as needed
                      padding:
                          EdgeInsets.only(left: left, right: right, bottom: 5),
                      child: Icon(
                        Icons.arrow_back,
                        size: iconSizeBtn,
                        color: tappedBtn1 ? Colors.purpleAccent : buttonColor,
                      )),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      tappedBtn2 = true;
                    });
                    Future.delayed(Duration(milliseconds: 80), () {
                      setState(() {
                        tappedBtn2 = false;
                      });
                    });
                    (widget.getWebViewAction() as InAppWebViewController)
                        .goForward();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent)),
                      // color: Colors.amber,
                      // width: 75.0, // Adjust the width as needed
                      // height: 50.0, // Adjust the height as needed
                      padding:
                          EdgeInsets.only(left: left, right: right, bottom: 3),
                      child: Icon(
                        Icons.arrow_forward,
                        size: iconSizeBtn,
                        color: tappedBtn2 ? Colors.purpleAccent : buttonColor,
                      )),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      tappedBtn3 = true;
                    });
                    Future.delayed(Duration(milliseconds: 80), () {
                      setState(() {
                        tappedBtn3 = false;
                      });
                    });
                    (widget.getWebViewAction() as InAppWebViewController)
                        .reload();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent)),
                      // color: Colors.amber,
                      // width: 75.0, // Adjust the width as needed
                      // height: 50.0, // Adjust the height as needed
                      padding:
                          EdgeInsets.only(left: left, right: right, bottom: 3),
                      child: Icon(
                        Icons.refresh,
                        size: iconSizeBtn,
                        color: tappedBtn3 ? Colors.purpleAccent : buttonColor,
                      )),
                ),
                GestureDetector(
                  key: searchKey,
                  onTap: () {
                    setState(() {
                      tappedBtn5 = true;
                    });
                    Future.delayed(Duration(milliseconds: 80), () {
                      setState(() {
                        tappedBtn5 = false;
                      });
                    });
                    _showSearchModalSheet();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent)),
                      // color: Colors.amber,
                      // width: 75.0, // Adjust the width as needed
                      // height: 50.0, // Adjust the height as needed
                      padding:
                          EdgeInsets.only(left: left, right: right, bottom: 3),
                      child: Icon(
                        Icons.search,
                        size: iconSizeBtn,
                        color: tappedBtn5 ? Colors.purpleAccent : buttonColor,
                      )),
                ),
                GestureDetector(
                  key: addKey,
                  onTap: () {
                    setState(() {
                      tappedBtn4 = true;
                    });
                    Future.delayed(Duration(milliseconds: 80), () {
                      setState(() {
                        tappedBtn4 = false;
                      });
                    });
                    _onButtonPressed();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent)),
                      alignment: Alignment.center,
                      //color: Colors.amber,
                      // width: 75.0, // Adjust the width as needed
                      // height: 50.0, // Adjust the height as needed
                      padding:
                          EdgeInsets.only(left: left, right: right, bottom: 3),
                      child: _isLoading
                          ? SizedBox(
                              child:
                                  // Padding(
                                  //     padding: const EdgeInsets.only(
                                  //         left: 2, right: 2, bottom: 0, top: 0),
                                  //     child:
                                  LoadingAnimationWidget.halfTriangleDot(
                                color: Colors.blue,
                                size: iconSizeBtn,
                                // )
                              ),
                              height: iconSizeBtn,
                              width: iconSizeBtn,
                            )
                          : Icon(
                              Icons.add_box_outlined,
                              size: iconSizeBtn,
                              color: tappedBtn4
                                  ? Colors.purpleAccent
                                  : buttonColor,
                            )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _showSearchModalSheet() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        // backgroundColor: Colors.transparent,
        //barrierColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SearchBottomScreen(
              searchText: searchText,
              onUrlChange: (String url) {
                widget
                    .getWebViewAction()
                    .loadUrl(urlRequest: URLRequest(url: WebUri(url)));
              },
              onSearchTextChange: (String text) {
                setState(() {
                  searchText = text;
                });
              },
            );
          });
        });
  }
}
