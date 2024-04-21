import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:ps_check/searchResult.dart';
import 'package:ps_check/spw.dart';
import 'package:http/http.dart' as http;

var sharedPropWrapper = SharedPropWrapper.instance();
double iconSize = 27;

class SearchScreen extends StatefulWidget {
  @override
  createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _focusNode = FocusNode();
  int? _selectedIdx;

  final TextEditingController _controller = TextEditingController();
  List<SearchResult> searchResult = List.empty();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() async {
    String text = _controller.text;
    // Perform action when text length is at least 3 characters
    if (text.length >= 3) {
      var data = await getSearchList(text);
      setState(() {
        searchResult = data;
      });
    } else {
      setState(() {
        searchResult = List.empty();
      });
    }
  }

  String getBaseUrl() {
    return "https://store.playstation.com/";
  }

  Future<String> getSearchUrl(String partOfUrl) async {
    var region = await sharedPropWrapper.readRegion();
    var baseUrl = getBaseUrl();
    return "$baseUrl/$region/search/$partOfUrl";
  }

  Future<List<SearchResult>> getSearchList(String text) async {
    var region = await sharedPropWrapper.readRegion();
    Map<String, String> headers = {"X-Psn-Store-Locale-Override": region};
    var url = await getSearchUrl(text);
    List<SearchResult> searchResults = [];
    var response = await http.Client().get(Uri.parse(url), headers: headers);
    //If the http request is successful the statusCode will be 200
    if (response.statusCode == 200) {
      var document = parse(response.body);
      var nameElements = document.getElementsByClassName(
          "psw-t-body psw-c-t-1 psw-t-truncate-2 psw-m-b-2");

      nameElements.forEach((element) async {
        var aElement = element.parentNode?.parentNode?.parentNode;
        // var imgElement = aElement?.nodes[0].nodes[0].nodes[0].nodes[1].nodes[1];
        var partOfUrl = aElement?.attributes["href"].toString();
        var baseUrl = getBaseUrl();
        var gameUrl = "$baseUrl$partOfUrl";
        var searchResult = new SearchResult(
            name: removeFirstAndLast(element.nodes[0].toString()),
            url: gameUrl,
            imgUrl: "img");
        searchResults.add(searchResult);
      });
    }
    return searchResults;
  }

  String removeFirstAndLast(String str) {
    if (str.length <= 2) {
      return "";
    }
    return str.substring(1, str.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    var bottomHeight = MediaQuery.of(context).viewInsets.bottom == 0
        ? screenHeight * 0.09
        : screenHeight * 0.055;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white,
        leadingWidth: 80,
        toolbarHeight: 40,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Done',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: Color.fromARGB(255, 0, 114, 206),
            ),
          ),
        ),
      ),
      body: Padding(
          padding: EdgeInsets.only(bottom: bottomHeight),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  shrinkWrap: false,
                  itemCount: searchResult.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      color: _selectedIdx == index
                          ? Colors.blueAccent
                          : Colors.transparent,
                      //padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                      child: GestureDetector(
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(15, 10, 7, 7),
                            child: Text(
                              searchResult[index].name,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.019,
                              ),
                            )),
                        onTap: () {
                          setState(() {
                            _selectedIdx = index;
                          });
                          Future.delayed(Duration(milliseconds: 80), () {
                            Navigator.pop(context, searchResult[index].url);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          )),
      bottomSheet: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.linear,
        height: bottomHeight,
        color: MediaQuery.of(context).viewInsets.bottom == 0
            ? Color(0xECF1F1F1)
            : Color.fromRGBO(210, 212, 217, 1),
        //Color(0xff003697),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedPadding(
              padding: EdgeInsets.fromLTRB(10, 5, 10,
                  MediaQuery.of(context).viewInsets.bottom == 0 ? 40 : 5),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              child: Container(
                width: screenWidth * 0.8,
                height: screenHeight * 0.040,
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  focusNode: _focusNode,
                  style: TextStyle(
                      fontSize: screenHeight * 0.020,
                      height: 1,
                      color: Colors.black),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    //contentPadding: const EdgeInsets.all(0.5),

                    prefixIcon: Icon(Icons.search, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: _controller,
                ),
              ),
            )
          ],
        ),
      ),
      // )
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class KeyboardAwareBottomAppBar extends StatelessWidget {
  final Widget child;

  KeyboardAwareBottomAppBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: BottomAppBar(
        child: child,
      ),
    );
  }
}
