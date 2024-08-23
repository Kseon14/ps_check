import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

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
                          children: _showText(data!.productRetrieve!),
                        ))
                      ]))
            ],
          ),
        ));
  }

  _showText(ProductRetrieve productRetrieve) {
    var textItems = <Widget>[];
    textItems.add(AutoSizeText(
      productRetrieve.name!,
      style: _getTextStyle(),
      maxLines: 3,
      maxFontSize: 14,
    ));

    if (productRetrieve.webctas![0].price!.basePrice != null) {
      if (isDiscountExist(productRetrieve)) {
        textItems.add(AutoSizeText(
          productRetrieve.webctas![0].price!.basePrice!,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxFontSize: 15,
        ));
        textItems.add(AutoSizeText(
            productRetrieve.webctas![0].price!.discountedPrice!,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.red),
            maxFontSize: 15));
      } else {
        textItems.add(AutoSizeText(
          productRetrieve.webctas![0].price!.basePrice!,
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
