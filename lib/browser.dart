// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:webview_cookie_manager/webview_cookie_manager.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class WebViewContainer extends StatefulWidget {
//   final url;
//
//   WebViewContainer(this.url);
//
//   @override
//   createState() => _WebViewContainerState(this.url);
// }
//
// class _WebViewContainerState extends State<WebViewContainer> {
//   var _url;
//   final _key = UniqueKey();
//   final cookieManager = WebviewCookieManager();
//
//   _WebViewContainerState(this._url);
//
//   @override
//   void initState() {
//     super.initState();
//     cookieManager.clearCookies();
//     if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           elevation: 0.0,
//           backgroundColor: Platform.isAndroid ? Colors.white : Color(0xECECECFF),
//           leadingWidth: 80,
//           toolbarHeight: 44,
//           leading: TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Done', style: TextStyle(fontSize: 17)),
//           ),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//                 child: WebView(
//                     key: _key,
//                     //debuggingEnabled: true,
//                     javascriptMode: JavascriptMode.unrestricted,
//                     onWebViewCreated: (controller) async {
//                       controller.clearCache();
//                       await cookieManager.setCookies([
//                         Cookie("eucookiepreference", "accept")
//                           ..domain=".playstation.com"
//                           ..httpOnly = false
//                       ]);
//                     },
//                     javascriptChannels: [
//                       JavascriptChannel(name: 'CHANNEL_NAME', onMessageReceived: (message) {
//                         print(message.message);
//                       })
//                     ].toSet(),
//                     // onPageFinished: (_) async {
//                     //   final gotCookies = await cookieManager.getCookies(_url);
//                     //   for (var item in gotCookies) {
//                     //     print(item);
//                     //   }
//                     // },
//                     initialUrl: _url))
//           ],
//         ));
//   }
// }