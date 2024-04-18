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

  //inapp.CookieManager cookieManager = inapp.CookieManager.instance();
  final cookieManager1 = CookieManager.instance();

  _WebViewContainerState(this._url);

  // Future<void> deleteAllCookies() async {
  //   await cookieManager1.deleteAllCookies();
  // }

  @override
  void initState() {
    super.initState();
   // deleteAllCookies();
   // setCookie();
    //setCookie2();
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
   // await cookieManager1.removeSessionCookies();
    await cookieManager1.setCookie(
      url: WebUri('https://store.playstation.com'),
      name: "eucookiepreference",
      value: "reject",
      expiresDate: DateTime.now().add(Duration(days: 5)).microsecondsSinceEpoch,
      isSecure: true,
    );
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
                  //  useShouldOverrideUrlLoading: true,
                      allowsBackForwardNavigationGestures: true
                  ),
                  onWebViewCreated: (controller) async {
                    _webViewController = controller;
                   // _webViewController?.clearCache();
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
                    print("Console Message: ${consoleMessage.message}");
                  },
                  onLoadStop: (InAppWebViewController controller, Uri? url) async {
                    if (url != null && url.toString().contains("/**/error")) {
                      controller.reload();
                    }
                    await controller.evaluateJavascript(source: """
                  document.getElementById('sony-bar').style.display = 'none';
                  document.getElementById('shared-nav-root').style.display = 'none';
                  var footer = document.getElementsByTagName('footer')[0];
                  footer.parentNode.removeChild(footer);
                """);
                  },
                ),
              ),
            )
          ]),
        ));
  }
}
