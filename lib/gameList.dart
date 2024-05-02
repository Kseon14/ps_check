import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'browser2.dart';
import 'gameRow.dart';
import 'main.dart';
import 'model.dart';

class GamesList extends StatefulWidget {
  final List<Data?> data;
  final Function() notifyParent;
  final Function() refreshList;

  GamesList(
      {Key? key,
      required this.data,
      required this.notifyParent,
      required this.refreshList})
      : super(key: key);

  @override
  _GamesListState createState() => _GamesListState();
}

class _GamesListState extends State<GamesList> {
  @override
  Widget build(BuildContext context) {
    debugPrint("list builder");
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Slidable(
            key: UniqueKey(),
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.25,
              dismissible: DismissiblePane(
                onDismissed: () {
                  setState(() {
                    hiveWrapper
                        .removeFromDb(widget.data[index]!.productRetrieve!.id!);
                    widget.data.removeAt(index);
                    if (widget.data.length == 0) {
                      widget.notifyParent();
                    }
                  });
                },
              ),
              children: [
                SlidableAction(
                  label: 'Delete',
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  onPressed: (context) {
                    setState(() {
                      hiveWrapper.removeFromDb(
                          widget.data[index]!.productRetrieve!.id!);
                      widget.data.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            child: GestureDetector(
                onTap: () => _launchURL(context, widget.data[index]!.url),
                child: GameRowItem(data: widget.data[index]!)),
          );
        },
        childCount: widget.data.length,
      ),
    );
  }

  void _launchURL(var context, var url) async => Navigator.push(
      context, MaterialPageRoute(builder: (context) => WebViewContainer(url)));
}
