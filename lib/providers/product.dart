import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.imageUrl,
    @required this.price,
    this.isFavorite = false,
  });

  void _setFavValue(bool newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  void toogleFavotiteStatus(String token, String userId) async {
    final oldStatus = isFavorite;

    isFavorite = !isFavorite;
    notifyListeners();

    // final url = Uri.https('shop-3dab8-default-rtdb.firebaseio.com',
    //     '/products/$id.json?auth=$token');
    final url = Uri.parse(
        'https://shop-3dab8-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json?auth=$token');

    try {
      //patch changed to put
      final response = await http.put(
        url,
        body: json.encode(
          //'isFavorite': isFavorite,
          isFavorite,
        ),
      );
      if (response.statusCode >= 400) {
        _setFavValue(oldStatus);
      }
    } catch (error) {
      _setFavValue(oldStatus);
    }
  }
}
