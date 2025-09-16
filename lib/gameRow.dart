import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';
import 'model.dart';

class GameRowItem extends StatelessWidget {
  const GameRowItem({Key? key, required this.data}) : super(key: key);
  final Data? data;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Theme.of(context).primaryColor,
        elevation: 0.0,
        child: new Container(
          padding: new EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(7.5),
                child: ImageWrapper(
                  url: data!.imageUrl!,
                ),
              )),
              Flexible(
                  flex: 2,
                  child: Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // This line is already uncommented
                          mainAxisAlignment: MainAxisAlignment.start,
                          // Add this line
                          children: _showText(data!.products.first),
                        ))
                      ]))
            ],
          ),
        ));
  }

  _showText(Product product) {
    var textItems = <Widget>[];
    if (product.releaseDate != null) {
      // textItems.add(const SizedBox(height: 6));
      final formatter = DateFormat('dd.MM.yyyy');
      var releaseDate = DateTime.parse(product.releaseDate!);
      final nowUtc = DateTime.now().toUtc();
      if (releaseDate.isAfter(nowUtc)) {
        String formattedDate = formatter.format(releaseDate);
        textItems.add(AutoSizeText(formattedDate,
            style: TextStyle(fontSize: 13), maxFontSize: 15));
      }
    }
    textItems.add(AutoSizeText(
      product.name!,
      style: _getTextStyle(),
      maxLines: 3,
      maxFontSize: 14,
    ));
    if (product.getBasePrice() != null) {
      if (isDiscountExist(product)) {
        textItems.add(AutoSizeText(
          product.getBasePrice(),
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxFontSize: 15,
        ));
        textItems.add(AutoSizeText(product.getDiscountedPrice(),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.red),
            maxFontSize: 15));
      } else {
        textItems.add(AutoSizeText(
          product.getBasePrice(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxFontSize: 15,
        ));
      }
    }

    return textItems;
  }

  _getTextStyle() {
    return TextStyle(fontSize: 14);
  }
}
