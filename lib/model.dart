
import 'package:flutter/cupertino.dart';

class Data {
  List<Product> products;
  String? imageUrl;
  String? url;
  String? conceptId;
  List<Media>? dataMedia;

  Data({
    required this.products,
    this.imageUrl,
    this.url,
    this.conceptId,
    this.dataMedia
  });

  //1. error :
  //   json["data"]["productRetrieve"] == null
  //2. concept :
  //  json["data"]["conceptRetrieve"] == {}
  //3. product :
  //  json["data"]["productRetrieve"] == {}
  //4. announced :
  //  json["data"]["conceptRetrieve"] == {}
  //  json["data"]["conceptRetrieve"] ["products"] == [](Empty list)

  factory Data.fromJson(Map<String, dynamic> json) {
    var conceptId;
    var productsJson;

    var productType = null;
    //debugPrint("1>>" + json.toString());
    if(json["data"]["conceptRetrieve"]!= null &&
        (json["data"]["conceptRetrieve"]["products"]).length == 0) {
        //debugPrint("2>>" + "products is empty");
        var concept = json["data"]["conceptRetrieve"];
        return Data(products: [Product(name: concept["name"],
            conceptId: concept["id"])
        ]);
      }

    var dataMedia;
    if(json["data"]["productRetrieve"] != null ){
     // debugPrint("3>>" + "productRetrieve");
      conceptId = json["data"]["productRetrieve"]["concept"]["id"];

      if(json["data"]["productRetrieve"]["concept"]["media"] != null
         && json["data"]["productRetrieve"]["concept"]["media"].length != 0){
        var jsonMedia = json["data"]["productRetrieve"]["concept"]["media"];
        dataMedia= (jsonMedia as List<dynamic>?)
            ?.map((item) => Media.fromJson(item))
            .toList();
      }

      if(json["data"]["productRetrieve"]["concept"]["products"] != null) {
        productsJson = json["data"]["productRetrieve"]["concept"]["products"];
      } else {
        productsJson = [json["data"]["productRetrieve"]];
      }
      var prodType = json["data"]["productRetrieve"]["topCategory"];
      //debugPrint("3.1>>" + "products type: " + prodType);
      productType = prodType == null ? null : ProductType.fromString(prodType);
    }

    if(json["data"]["conceptRetrieve"] != null) {
     // debugPrint("4>>" + "conceptRetrieve");
      conceptId = json["data"]["conceptRetrieve"]["id"];
      productsJson = json["data"]["conceptRetrieve"]["products"];
    }

    //debugPrint("5>>" + "productsJson: " + productsJson.toString());
    List<Product> products = (productsJson as List<dynamic>)
        .map((prod) => Product.fromJson(prod as Map<String, dynamic>, productType, conceptId))
        .where((product) => product.price?.basePrice != null)
        .toList();

    return Data(
      conceptId: conceptId,
      products: products,
      dataMedia: dataMedia
    );
  }

  @override
  String toString() {
    return 'Data{products: $products, imageUrl: $imageUrl, url: $url,}';
  }

}

class Product{
  List<Media>? media;
  List<String>? platforms;
  String? id;
  String? name;
  final Price? price;
  bool? isSelected = false;
  ProductType? productType;
  String? conceptId;

  DateTime? releaseDate;

  Product({this.media,
    this.platforms,
    this.id,
    this.name,
    this.price,
    this.releaseDate,
    this.conceptId,
    this.productType});

  @override
  String toString() {
    return 'Product{media: $media, '
        'platforms: $platforms,'
        'id: $id, '
        'name: $name, '
        'price: $price, '
        'releaseDate: $releaseDate, '
        'productType: $releaseDate, '
        'conceptId: $conceptId, '
        'isSelected: $isSelected}';
  }

  factory Product.fromJson(Map<String, dynamic> json, ProductType? productType, String conceptId) {
    if (json.isEmpty) {
      return Product();
    }

    Price? price;
    if (json['webctas'] != null && json['webctas'] is List) {
      List<dynamic> webctasList = json['webctas'];
      if (webctasList.isNotEmpty) {
        price = Price.fromJson(webctasList.first["price"]);
      }
    }

    List<String>? platforms = (json['platforms'] as List<dynamic>?)
        ?.map((item) => item as String)
        .toList();

    List<Media>? media = (json['media'] as List<dynamic>?)
        ?.map((item) => Media.fromJson(item))
        .toList();


     DateTime? releaseDate;
    if (json['releaseDate'] != null) {
      releaseDate = DateTime.tryParse(json['releaseDate']);
    }

    return Product(
      platforms: platforms,
      media: media,
      price: price,
      id: json['id'] as String?,
      name: json['name'] as String?,
      releaseDate: releaseDate,
      productType: productType,
      conceptId: conceptId,
    );
  }


  getDiscountPriceValue(){
    return price?.discountedValue;
  }

  getDiscountedPrice(){
    return price?.discountedPrice;
  }

  getBasePrice(){
    return price?.basePrice;
  }

  getBasePriceValue(){
    return price?.basePriceValue;
  }

}

class Media {
  String? role;
  String? url;

  Media({this.role, this.url});

  @override
  String toString() {
    return 'Media{role: $role, url: $url}';
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(role:
    json['role'],
    url: json['url']);
  }

}

class Webctas {
   final Price? price;
   final String? type;

  Webctas({this.price, this.type});

  factory Webctas.fromJson(Map<String, dynamic> json) {
    return Webctas(
      price: Price.fromJson(json['price']),
      type: json['type'],
    );
  }

  @override
  String toString() {
    return 'Webctas{price: $price}';
  }
}

class Price {
  final String? basePrice;
  final String? discountText;
  final String? discountedPrice;
  final int? discountedValue;
  final int? basePriceValue;
  final bool? isFree;
  late final DateTime? endTime;

  Price(
      {this.basePrice, this.discountText, this.discountedPrice, this.endTime,
        this.basePriceValue, this.discountedValue, this.isFree});

  static Price? fromJson(Map<String, dynamic> json) {
   var isFree = json['isFree'];

    //if (json['basePriceValue'] != 0) {
      return Price(
        basePrice: isFree? json['discountedPrice'] : json['basePrice'],
        discountText: json['discountText'],
        discountedPrice:  json['discountedPrice'],
        discountedValue: isFree? 0: json['discountedValue'],
        basePriceValue: isFree? 0: json['basePriceValue'],
        isFree:  isFree,
        endTime: (json['endTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(int.parse(json['endTime']))),
      );
    //}
    // if(json['basePrice']!= null && json['discountedPrice']!= null) {
    //   return Price (
    //       basePrice: json['basePrice'],
    //       discountedPrice: json['discountedPrice']
    //   );
    // }
    // return null;
  }

  @override
  String toString() {
    return 'Price{basePrice: $basePrice, discountText: $discountText, discountedPrice: $discountedPrice, discountedValue: $discountedValue, basePriceValue: $basePriceValue, endTime: $endTime}';
  }
}

class Error {
  final String? message;

  Error({this.message});

  factory Error.fromJson(Map<String, dynamic> inputJson) {
    return Error(message: inputJson['message']);
  }

  @override
  String toString() {
    return 'Error{message: $message}';
  }
}

enum ProductType {
  GAME("GAME"),
  ADD_ON("ADD_ON");

  final String value;

  const ProductType(this.value);

  static ProductType? fromString(String value) {
    return ProductType.values.firstWhere((e) => e.value == value,
        orElse: () => ProductType.GAME);
  }
}



