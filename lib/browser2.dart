import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class WebViewContainer extends StatefulWidget {
  final url;

  WebViewContainer(this.url);

  @override
  createState() => _WebViewContainerState(this.url);
}

class _WebViewContainerState extends State<WebViewContainer> {
  var _url;
  inapp.InAppWebViewController? _webViewController;
  double progress = 0;

  //inapp.CookieManager cookieManager = inapp.CookieManager.instance();
  final cookieManager1 = WebviewCookieManager();

  _WebViewContainerState(this._url);

  @override
  void initState() {
    super.initState();
   // cookieManager.deleteAllCookies();
   // setCookie();
    setCookie2();
  }

  void setCookie2() async {
    await cookieManager1.clearCookies();
    cookieManager1.setCookies([
      Cookie('eucookiepreference', 'reject')
        ..domain = '.playstation.com'
        ..expires = DateTime.now().add(Duration(days: 5))
        ..httpOnly = false
    ], origin: 'https://store.playstation.com');
  }

  //void setCookie() async {

  //   await cookieManager.setCookie(
  //       url: Uri.parse("https://store.playstation.com"),
  //       name: "eucookiepreference",
  //       value: "reject",
  //       domain: ".playstation.com",
  //       isHttpOnly: false,
  //       path: "/",
  //       sameSite: inapp.HTTPCookieSameSitePolicy.NONE,
  //       expiresDate: DateTime
  //           .now()
  //           .add(Duration(days: 7))
  //           .millisecondsSinceEpoch ~/ 1000);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Color(0xECF1F1F1),
          leadingWidth: 80,
          toolbarHeight: 44,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done', style: TextStyle(fontSize: 17)),
          ),
        ),
        body: Container(child:
          Column(children: <Widget>[
            Container(
                // padding: EdgeInsets.all(10.0),
                child: progress < 1.0
                    ? LinearProgressIndicator(value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.lightBlueAccent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),)
                    : Container()),
            Container(
              child: Expanded(
                child: inapp.InAppWebView(
                  initialUrlRequest: inapp.URLRequest(url: Uri.parse(_url)),
                  initialOptions: inapp.InAppWebViewGroupOptions(
                      crossPlatform:
                      inapp.InAppWebViewOptions(useShouldOverrideUrlLoading: true
                              //debuggingEnabled: true,
                              )),
                  onWebViewCreated: (inapp.InAppWebViewController controller) async {
                    _webViewController = controller;
                   // _webViewController?.clearCache();
                   },
                  onProgressChanged:
                      (inapp.InAppWebViewController controller, int progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                ),
              ),
            )
          ]),
        ));
  }
}
