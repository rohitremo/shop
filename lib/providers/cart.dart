import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem({
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
  });
}

class Cart with ChangeNotifier {
  //Map<Keys, Values>
  Map<String, CartItem> _cartItems = {};

  //getter
  Map<String, CartItem> get items {
    return {..._cartItems}; //returns a copy of origial map
  }

  int get itemCount {
    return _cartItems.length;
    //_cartItems == null ? 0 : _cartItems.length  "only needed if 'Map<String, CartItem> _cartItems;' is not innitialised like"
    //Map<String, CartItem> _cartItems = {};
  }

  //total of all the cart item
  double get totalAmount {
    var total = 0.0;
    _cartItems.forEach((key, cItem) {
      total += cItem.price * cItem.quantity;
    });
    return total;
  }

  //add Item to cart Logic
  void addItem(String productId, double price, String title) {
    if (_cartItems.containsKey(productId)) {
      //change quentity
      //use to update only quantity everything else remain same for that product
      _cartItems.update(
        productId,
        (existingCartItem) => CartItem(
            id: existingCartItem.id,
            title: existingCartItem.title,
            price: existingCartItem.price,
            quantity: existingCartItem.quantity + 1),
      );
    } else {
      _cartItems.putIfAbsent(
        productId,
        () => CartItem(
            id: DateTime.now().toString(),
            title: title,
            price: price,
            quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  //lec 9 from part 2
  void removeSingleItem(String productId) {
    if (!_cartItems.containsKey(productId)) {
      return; //if there is no product in the cart just return statement cancel the function
    }

    if (_cartItems[productId].quantity > 1) {
      _cartItems.update(
        productId,
        (existingCartItem) => CartItem(
            id: existingCartItem.id,
            title: existingCartItem.title,
            //to remove a singel item from the cart of a perticular product as when we add it
            quantity: existingCartItem.quantity - 1,
            price: existingCartItem.price),
      );
    } else {
      _cartItems.remove(productId);
    }

    notifyListeners();
  }

  void clear() {
    _cartItems = {};
    notifyListeners();
  }
}
