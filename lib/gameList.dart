import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ps_check/game-web-card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'gameRow.dart';
import 'main.dart';
import 'model.dart';

class GamesList extends StatefulWidget {
  final List<Data?> data;
  final Function() notifyParent;
  final Function() refreshList;
  final Function(void Function()) setResetCallback;

  GamesList(
      {Key? key,
      required this.data,
      required this.notifyParent,
      required this.refreshList,
        required this.setResetCallback,})
      : super(key: key);

  @override
  _GamesListState createState() => _GamesListState();
}

Future<void> _launchPlayStationLink(Uri url, String gameId) async {
  var psStoreUrl = 'psstore://store?PID=' + gameId;
  final bool nativeAppLaunchSucceeded =
      await launch(psStoreUrl, forceSafariVC: false);
  if (!nativeAppLaunchSucceeded) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  } else {
    throw 'Could not launch $url';
  }
}

class _GamesListState extends State<GamesList> {
  int? _selectedIndex;
  int? _expandedMediaIndex;
  Map<int, double> _blurValues = {};
  double maxBlur = 25;

  void _removeItem(int index) {
    setState(() {
      hiveWrapper.removeFromDb(widget.data[index]!.products.first.id!);
      widget.data.removeAt(index);
      if (widget.data.isEmpty) {
        widget.notifyParent();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.setResetCallback(_resetSelection);
  }

  void _resetSelection() {
    setState(() {
      if (_selectedIndex != null) {
        _blurValues[_selectedIndex!] = 0.0;
      }
      _selectedIndex = null;
      _expandedMediaIndex = null;
    });
  }

   _getHeight() {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 9) / 16;
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final hasMedia = _hasMedia(widget.data[index]!.products.first.media);
          return AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () {
                _handleRowTap(index);
              },
              child: Slidable(
                key: UniqueKey(),
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  extentRatio: 0.25,
                  dismissible:
                      DismissiblePane(onDismissed: () => _removeItem(index)),
                  children: [
                    SlidableAction(
                      label: 'Delete',
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      onPressed: (context) => _removeItem(index),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    GameRowItem(data: widget.data[index]!),
                    if (_expandedMediaIndex == index)
                      Container(
                        color: Colors.white,
                        height: _getHeight(),
                        child: InfiniteSwipeableMediaDisplayWidget(
                          media: widget.data[index]!.products.first.media ?? [],
                        ),
                      ),
                    if (_selectedIndex == index && _expandedMediaIndex == null)
                      Positioned.fill(
                        child: ClipRect(
                          // child: TweenAnimationBuilder<double>(
                          //   tween: Tween<double>(
                          //       begin: 0, end: _blurValues[index] ?? 0.0),
                          //   duration: Duration(milliseconds: 150),
                          //   curve: Curves.easeOut,
                          //   builder: (context, blur, child) {
                             // debugPrint("blur inside:" + blur.toString());
                              child:  BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 25, sigmaY: 25),
                                child: Container(
                                  color: Colors.grey.withOpacity(0.4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildIconButton(
                                        CupertinoIcons.globe,
                                        Colors.black,
                                        () => _launchURL(
                                            context, widget.data[index]!.url),
                                      ),
                                      _buildIconButton(
                                        CupertinoIcons.photo_on_rectangle,
                                        hasMedia ? Colors.black : Colors.grey,
                                        hasMedia
                                            ? () => _toggleMediaSwiper(index)
                                            : null,
                                      ),
                                      _buildIconButton(
                                        CupertinoIcons.share,
                                        widget.data[index]!.url != null
                                            ? Colors.black
                                            : Colors.grey,
                                        widget.data[index]!.url != null
                                            ? () => _launchPlayStationLink(
                                                Uri.parse(
                                                    widget.data[index]!.url!),
                                                widget.data[index]!.products.first.id!)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              //);
                            //},
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: widget.data.length,
      ),
    );
  }

  bool _hasMedia(List<Media>? media) {
    if (media == null || media.isEmpty) return false;
    return media.any((m) => m.role == "PREVIEW" || m.role == "SCREENSHOT");
  }

  void _handleRowTap(int index) {
    setState(() {
      if (_expandedMediaIndex != null) {
        _blurValues[_expandedMediaIndex!] = 0.0;
        _expandedMediaIndex = null;
      }

      if (_selectedIndex == index) {
        _blurValues[index] = 0.0;
        _selectedIndex = null;
      } else {
        if (_selectedIndex != null) {
          _blurValues[_selectedIndex!] = 0.0;
        }
        _selectedIndex = index;
        _blurValues[index] = maxBlur;
      }
    });
  }

  void _toggleMediaSwiper(int index) {
    if (_hasMedia(widget.data[index]!.products.first.media)) {
      setState(() {
        if (_expandedMediaIndex == index) {
          _expandedMediaIndex = null;
          _blurValues[index] = maxBlur;
        } else {
          _expandedMediaIndex = index;
          _blurValues[index] = 0.0;
          _selectedIndex = null;
        }
      });
    }
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 25),
      color: color,
      onPressed: onPressed,
    );
  }

  void _launchURL(var context, var url) async => Navigator.push(
      context, MaterialPageRoute(builder: (context) => WebViewContainer(url)));
}

class InfiniteSwipeableMediaDisplayWidget extends StatefulWidget {
  final List<Media> media;

  InfiniteSwipeableMediaDisplayWidget({required this.media});

  @override
  InfiniteSwipeableMediaDisplayWidgetState createState() =>
      InfiniteSwipeableMediaDisplayWidgetState();
}

class InfiniteSwipeableMediaDisplayWidgetState
    extends State<InfiniteSwipeableMediaDisplayWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  late int _totalPages;
  late List<Widget> _mediaWidgets;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final double _borderRadius = 10.0;

  late List<String> _imageUrls;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _processMedia();
    _totalPages = (_videoUrl != null ? 1 : 0) + _imageUrls.length;
    _pageController =
        PageController(initialPage: _totalPages * 1000, viewportFraction: 0.97);
    _buildMediaWidgets();
  }

  void _processMedia() {
    _imageUrls = widget.media
        .where((media) => media.role == "SCREENSHOT")
        .map((media) => media.url!)
        .toList();

    _videoUrl = widget.media
        .firstWhere((media) => media.role == "PREVIEW",
            orElse: () => Media(role: "", url: ""))
        .url;

    if (_videoUrl?.isEmpty ?? true) {
      _videoUrl = null;
    }
  }

  void _buildMediaWidgets() {
    _mediaWidgets = [];
    if (_videoUrl != null) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: true,
        aspectRatio: 16 / 9,
        placeholder: Container(
          color: Colors.black,
        ),
        // Adjust this as needed
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
      _mediaWidgets.add(_buildMediaItem(
        ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Chewie(controller: _chewieController!),
        ),
      ));
    }
    _mediaWidgets.addAll(_imageUrls.map((url) => _buildMediaItem(
          ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          ),
        )));
  }

  Widget _buildMediaItem(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void stopVideo() {
    _chewieController?.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                int newPage = page % _totalPages;
                if (_currentPage == 0 && newPage != 0) {
                  stopVideo();
                }
                _currentPage = newPage;
              });
            },
            itemBuilder: (context, index) {
              return _mediaWidgets[index % _totalPages];
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _totalPages; i++)
                Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? Color.fromARGB(255, 0, 114, 206)
                        : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
