import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  final cookieManager = CookieManager.instance();

  _WebViewContainerState(this._url);


  @override
  void initState() {
    super.initState();
  }

  void clearCookies() async {
    var cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies(); // This deletes all cookies
  }

  void clearCache() async {
    if (_webViewController != null) {
      await _webViewController!.clearCache(); // This clears the WebView cache
    }
  }

  void resetWebView() {
    setState(() {
      _webViewController = null; // Resetting controller
    });
  }

  void setCookie2() async {
    await cookieManager.setCookie(
      url: WebUri('https://store.playstation.com'),
      name: "_evidon_consent_cookie",
      value: "date",
      expiresDate: DateTime.now().add(Duration(days: 5)).microsecondsSinceEpoch,
      isSecure: true,
    );
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
            onPressed: () {
              // Perform cleanup when user presses "Done"
              clearCookies();
              clearCache();
              Navigator.of(context).pop();  // Close the WebView screen
            },
            child: Text('Done',
                style: TextStyle(fontSize: MediaQuery.of(context).size.width*0.04,
                color: Color.fromARGB(255, 0, 114, 206))),
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
                  initialUrlRequest: URLRequest(url: WebUri(_url)),
                  initialSettings: InAppWebViewSettings(
                      allowsBackForwardNavigationGestures: true
                  ),
                  onWebViewCreated: (controller) async {
                    _webViewController = controller;
                   },
                  onProgressChanged:
                      (InAppWebViewController controller, int progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  onLoadStart: (controller, url) async {
                    setCookie2();
                  },
                  onReceivedServerTrustAuthRequest: (controller, challenge) async {
                    // Automatically proceed with every SSL certificate encountered
                    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint("Console Message: ${consoleMessage.message}");
                  },
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: """
      const hide = \`
        #sony-bar,
        #shared-nav-root,
        footer,
        #jetstream-tertiary-nav { 
          display: none !important; 
        }
      \`;
      const s = document.createElement('style');
      s.textContent = hide;
      document.documentElement.appendChild(s);
    """,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
                ),
              ),
            )
          ]),
        ));
  }
}
