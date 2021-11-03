import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
//import 'package:shop/providers/product.dart';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String authToken;
  final String userId;

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  // void addOrders(List<CartItem> cartProdcts, double total) {
  //   _orders.insert(
  //     0,
  //     OrderItem(
  //         id: DateTime.now().toString(),
  //         amount: total,
  //         products: cartProdcts,
  //         dateTime: DateTime.now()),
  //   );
  //   notifyListeners();
  // }

  Future<void> fetchAndSetOrders() async {
    // final url = Uri.https('shop-3dab8-default-rtdb.firebaseio.com',
    //     '/orders.json?auth=$authToken');
    final url = Uri.parse(
        'https://shop-3dab8-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    final response = await http.get(url);
    //print(json.decode(response.body));
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;

    if (extractedData == null) {
      return; //if there is no order is the server or db
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
        id: orderId,
        amount: orderData['amount'],
        dateTime: DateTime.parse(orderData['dateTime']),
        products: (orderData['products'] as List<dynamic>)
            .map((item) => CartItem(
                id: item['id'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price']))
            .toList(),
      ));
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrders(List<CartItem> cartProdcts, double total) async {
    // final url = Uri.https('shop-3dab8-default-rtdb.firebaseio.com',
    //     '/orders.json?auth=$authToken');
    final url = Uri.parse(
        'https://shop-3dab8-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    final timestamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'products': cartProdcts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        }));
    _orders.insert(
      0,
      OrderItem(
          id: json.decode(response.body)['name'],
          amount: total,
          products: cartProdcts,
          dateTime: DateTime.now()),
    );
    notifyListeners();
  }
}
