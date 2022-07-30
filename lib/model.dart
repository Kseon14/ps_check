import 'dart:convert';

class Data {
  ProductRetrieve? productRetrieve;
  String? imageUrl;
  String? url;

  Data({this.productRetrieve});

  @override
  String toString() {
    return 'Data{productRetrieve: $productRetrieve, imageUrl: $imageUrl}';
  }

  factory Data.fromJson(String body, Game game) {
    Map<String, dynamic> inputJson = json.decode(body)['data'];
    if (inputJson['productRetrieve'] != null) {
      return Data(
        productRetrieve: ProductRetrieve.fromJson(inputJson['productRetrieve']),
      );
    }
    if (inputJson['conceptRetrieve'] != null) {
      Data conceptDate=  Data(productRetrieve: ProductRetrieve.fromJson(inputJson['conceptRetrieve']));
      if (conceptDate.productRetrieve!.webctas!.isEmpty){
       return Data(productRetrieve:
        ProductRetrieve(
            name: '${conceptDate.productRetrieve!.name}\n>>>> Not available for order, please remove and add again' ,
            id: game.id,
            webctas: [Webctas(
                price: Price(basePriceValue: 0,
                    discountedValue: 0,
                    discountedPrice: 'Not available for order, please remove and add again')
            )]),
        );
      } else {
        return conceptDate;
      }
    }
    else {
      List<Error> errors = json.decode(body)['errors']
          .map<Error>((json) => Error.fromJson(json)).toList();
      print("errors: $errors");
      return Data(productRetrieve:
      ProductRetrieve(
          name: 'Not available for selected region, please select game again' ,
          id: game.id,
          webctas: [Webctas(
              price: Price(basePriceValue: 0,
                  discountedValue: 0,
                  discountedPrice: "0")
          )]),
      );
    }
  }
  Data.fromJsonInt(Map<String, dynamic> json)
      : productRetrieve = json["productRetrieve"];

  Map<String, dynamic> toJson() => {
    "productRetrieve": productRetrieve,
  };
}

class ProductRetrieve {
  final List<Webctas>? webctas;
  final String? name;
  String? id;
  Concept? concept;

  ProductRetrieve({ this.name, this.webctas, this.id, this.concept});


  @override
  String toString() {
    return 'ProductRetrieve{webctas: $webctas, name: $name, id: $id, concept: $concept}';
  }

   static ProductRetrieve? fromJson(Map<String, dynamic>? json) {
    var isConcept = json!['__typename'] == 'Concept';
    Concept? concept;
    if (isConcept){
      Map<String, dynamic>? jsonDp = json['defaultProduct'];
      if (jsonDp == null){
        concept = Concept.fromJson(json);
      } else {
        json = jsonDp;
      }
    }
    if (json == null){
      return null;
    }

    if (concept == null) {
      concept = Concept.fromJson(json['concept']);
    }
    List<Webctas> wct = List.empty();
    if(concept == null) {
      if( json['webctas'] == null){
        return null;
      }
      var webctasList = json['webctas'] as List;
      wct = webctasList.map((wb) => Webctas.fromJson(wb)).toList();
    }

    return ProductRetrieve(
        id: isConcept && json['concept'] !=null ? json['concept']['id']
        : json['id'],
        name: json['name'] == null ? concept!.products![0].name : json['name'],
        webctas: wct,
         concept:concept);
  }
}

class Sku {
  String? id;

  Sku({this.id});

  factory Sku.fromJson(Map<String, dynamic> json) {
    return Sku(id: json['id']);
  }
}

class Concept {
   List<Product>? products;

   Concept({this.products});

   @override
   String toString() {
     return 'Concept{products: $products}';
   }

   static Concept? fromJson(Map<String, dynamic>? json) {
     if(json == null){
       return null;
     }
     var products = json['products'] == null ? null : json['products'] as List;

     if(products == null || products.length == 0) {
       return null;
     }

     List<Product> productList = products.map((wb) => Product.fromJson(wb)).toList();

     return Concept(products: productList);
   }
}

class Product{
  List<Media>? media;
  List<String>? platforms;
  String? id;
  String? name;
  final List<Webctas>? webctas;
  bool? isSelected = false;

  Product({this.media, this.platforms, this.id, this.name, this.webctas});


  @override
  String toString() {
    return 'Product{media: $media, platforms: $platforms, id: $id, name: $name, webctas: $webctas, isSelected: $isSelected}';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    var webctasList = ((json['webctas'] ?? []) as List);
    if(webctasList.isEmpty) {
      return Product(
          platforms: null,
          media: null,
          webctas: null,
          id: json['id'],
          name: json['name']
      );
    }
    var platformList = (json['platforms'] as List).cast<String>();
    var mediaList = json['media'] as List;

    List<Webctas> wct = webctasList.map((wb) => Webctas.fromJson(wb)).toList();
    List<Media> mda = mediaList.map((md) => Media.fromJson(md)).toList();

    return Product(
        platforms: platformList,
      media: mda,
      webctas: wct,
      id: json['id'],
      name: json['name']
    );
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

class ConceptRetrieve {
  final ProductRetrieve? productRetrieve;

  ConceptRetrieve({this.productRetrieve});

  @override
  String toString() {
    return 'ConceptRetrieve{productRetrieve: $productRetrieve}';
  }

  factory ConceptRetrieve.fromJson(Map<String, dynamic> json) {
    return ConceptRetrieve(productRetrieve:
        ProductRetrieve.fromJson(json['defaultProduct']));
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
  late final DateTime? endTime;

  Price(
      {this.basePrice, this.discountText, this.discountedPrice, this.endTime,
        this.basePriceValue, this.discountedValue});

  static Price? fromJson(Map<String, dynamic> json) {
    if (json['basePriceValue'] != 0) {
      return Price(
        basePrice: json['basePrice'],
        discountText: json['discountText'],
        discountedPrice: json['discountedPrice'],
        discountedValue: json['discountedValue'],
        basePriceValue: json['basePriceValue'],
        endTime: (json['endTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(int.parse(json['endTime']))),
      );
    }
    if(json['basePrice']!= null && json['discountedPrice']!= null) {
      return Price (
          basePrice: json['basePrice'],
          discountedPrice: json['discountedPrice']
      );
    }
    return null;
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

class Game {
  final String? url;
  final String? imageUrl;
  final String? id;

  Game({this.url, this.imageUrl, this.id});

  @override
  String toString() {
    return 'Game{url: $url, imageUrl: $imageUrl, id: $id}';
  }
}
