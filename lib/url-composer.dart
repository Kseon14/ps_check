import 'dart:convert';

import 'package:ps_check/main.dart';

import 'ga.dart';

class ApiUrlComposer {

  static Uri composeUrl({
    required String id,
    required GameType type,
    required String operationName,
    required String sha256Hash,
  }) {
    final baseUrl = host + '/api/graphql/v1/op';
    final typeOfProd = type == GameType.PRODUCT || type == GameType.ADD_ON ? 'productId' :'conceptId';
    final variables = jsonEncode({ typeOfProd : id});
    final extensions = jsonEncode({
      'persistedQuery': {
        'version': 1,
        'sha256Hash': sha256Hash
      }
    });

    final queryParameters = {
      'operationName': operationName,
      'variables': variables,
      'extensions': extensions,
    };

    return Uri.parse(baseUrl).replace(queryParameters: queryParameters);
  }
}