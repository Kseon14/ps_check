import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:ps_check/searchResult.dart';
import 'package:ps_check/spw.dart';
import 'package:http/http.dart' as http;

var sharedPropWrapper = SharedPropWrapper.instance();
double iconSize = 27;

typedef void StringCallback(String url);

class SearchBottomScreen extends StatefulWidget {
  final StringCallback onUrlChange;
  final StringCallback onSearchTextChange;
  String searchText;

  SearchBottomScreen({
    Key? key,
    required this.onUrlChange,
    required this.searchText,
    required this.onSearchTextChange,
  });

  @override
  createState() => _SearchBottomScreenState();
}

class _SearchBottomScreenState extends State<SearchBottomScreen> {
  final FocusNode _focusNode = FocusNode();
  int? _selectedIdx;
  var searchResExist = false;
  Timer? _debounce;

  final TextEditingController _controller = TextEditingController();
  List<SearchResult> searchResult = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _controller.text = widget.searchText;
    print("search text: ${widget.searchText}");
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() async {
    String text = _controller.text;
    // Perform action when text length is at least 3 characters
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      if (text.length >= 3) {
        var data = await getSearchList(text);
        setState(() {
          widget.searchText = text;
          searchResult.clear();
          searchResult.addAll(data);
          searchResExist = true;
          widget.onSearchTextChange(text);
        });
      }
      if (text.length <= 2) {
        setState(() {
          searchResult.clear();
          searchResExist = false;
          widget.onSearchTextChange("");
        });
      }
    });
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
      var nameElements = document.querySelectorAll('a[data-track="web:store:product-tile"]');
      nameElements.forEach((element) async {
      //  var aElement = element.parentNode?.parentNode?.parentNode;
        // var imgElement = aElement?.nodes[0].nodes[0].nodes[0].nodes[1].nodes[1];
        var partOfUrl = element.attributes["href"].toString();
        var baseUrl = getBaseUrl();
        var gameUrl = "$baseUrl$partOfUrl";
        var productNameSpan = element.querySelector('#product-name');
        var name = productNameSpan?.text.trim() ?? '';

        var searchResult = new SearchResult(
            name: name,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // We'll show a bottom padding if the keyboard is hidden
    final bottomHeight = MediaQuery.of(context).viewInsets.bottom == 0
        ? screenHeight * 0.12
        : screenHeight * 0.055;

    // Decide what to show above the search field
    final bool hasResults = searchResult.isNotEmpty;
    final bool showResults = searchResExist && hasResults;
    final bool showNoResults = searchResExist && !hasResults;

    double topContainerHeight = 0.0;
    Widget topContainerChild = const SizedBox.shrink();

    if (showResults) {
      // We have a valid search, and the server returned items
      topContainerHeight = screenHeight * 0.45; // or whatever suits you
      topContainerChild = ListView.builder(
        shrinkWrap: true,
        itemCount: searchResult.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            color: _selectedIdx == index ? Colors.blueAccent : Colors.transparent,
            child: GestureDetector(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 7, 7),
                child: Text(
                  searchResult[index].name,
                  style: TextStyle(
                    fontSize: screenHeight * 0.019,
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedIdx = index;
                });
                // Slight delay, then pop
                Future.delayed(const Duration(milliseconds: 80), () {
                  widget.onUrlChange(searchResult[index].url);
                  Navigator.pop(context);
                });
              },
            ),
          );
        },
      );
    } else if (showNoResults) {
      // We have typed >= 3 chars but got 0 items back
      topContainerHeight = 40.0; // just enough for one row
      topContainerChild = Center(
        child:  Text("No results found",
          style: TextStyle(
          fontSize: screenHeight * 0.019,
          height: 1,
          color: Colors.black,
        ),),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // This top container either shows the list or "No results found" or is empty
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
              height: topContainerHeight,
              color: const Color.fromRGBO(247, 246, 250, 1),
              child: topContainerChild,
            ),

            // The search TextField row
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
              height: bottomHeight,
              color: MediaQuery.of(context).viewInsets.bottom == 0
                  ? const Color.fromRGBO(247, 246, 250, 1)
                  : const Color.fromRGBO(210, 212, 217, 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedPadding(
                    padding: EdgeInsets.fromLTRB(
                      10,
                      5,
                      10,
                      MediaQuery.of(context).viewInsets.bottom == 0 ? 60 : 5,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.038,
                      child: TextField(
                        focusNode: _focusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.019,
                          height: 1,
                          color: Colors.black,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Search...",
                          isCollapsed: true,
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 36,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                // Clear everything
                                _controller.clear();
                                widget.onSearchTextChange("");
                                searchResult.clear();
                                searchResExist = false;
                              });
                            },
                            child: Icon(
                              Icons.clear,
                              color: _controller.text.isNotEmpty
                                  ? Colors.grey
                                  : Colors.transparent,
                            ),
                          ),
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
          ],
        ),
      ),
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
