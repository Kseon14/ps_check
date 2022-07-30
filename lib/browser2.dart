import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class WebViewContainer extends StatefulWidget {
  final url;

  WebViewContainer(this.url);

  @override
  createState() => _WebViewContainerState(this.url);
}

class _WebViewContainerState extends State<WebViewContainer> {
  var _url;
  InAppWebViewController? _webViewController;
  double progress = 0;

  // final cookieManager = WebviewCookieManager();
  CookieManager cookieManager = CookieManager.instance();

  _WebViewContainerState(this._url);

  @override
  void initState() {
    super.initState();
    cookieManager.deleteAllCookies();
  }

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
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse(_url)),
                  initialOptions: InAppWebViewGroupOptions(
                      crossPlatform:
                          InAppWebViewOptions(useShouldOverrideUrlLoading: true
                              //debuggingEnabled: true,
                              )),
                  onWebViewCreated: (InAppWebViewController controller) async {
                    _webViewController = controller;
                    _webViewController?.clearCache();
                    cookieManager.setCookie(
                        url: Uri.parse("https://store.playstation.com"),
                        name: "eucookiepreference",
                        value: "accept",
                        domain: ".playstation.com",
                        isHttpOnly: false);
                  },
                  onProgressChanged:
                      (InAppWebViewController controller, int progress) {
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
