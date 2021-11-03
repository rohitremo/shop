import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null; // its not null then it means user is authenticate
  }

  String get token {
    if (_expiryDate != null && //if its null we dont have a valid token
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    //if it returns null then we dont have an valid token or the token is expire
    return null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCp2cVvDIR0AX4OG4kN7iK5DEMcnc5Ud1s');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final responseData = json.decode(response.body);
      //will give a map of error which also had a nested map of message
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      _token = responseData['idToken']; //set the token
      // 'idToken' is given by firebase to get the token
      _userId = responseData['localId']; //get the user id
      //'localId' also given by firebae which is an id of the user
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));
      //'expiresIn' given by firebase we add current time to it to get the total expiretime
      _autoLogout();
      notifyListeners();

      //following code is to store user info on the device
      final sharePrefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate.toIso8601String()
      });
      sharePrefs.setString('dataOnDevice', userData);
    } catch (error) {
      throw error;
    }
    //print(json.decode(response.body));
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
    //sign up and in url will be found on firebase auth rest api/
    //as the code is repetative we put in a sapareate function and just change the part of the url where it is different
    // final url = Uri.parse(
    //     'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyCp2cVvDIR0AX4OG4kN7iK5DEMcnc5Ud1s');
    // final response = await http.post(
    //   url,
    //   body: json.encode({
    //     'email': email,
    //     'password': password,
    //     'returnSecureToken': true,
    //   }),
    // );
    // print(json.decode(response.body));
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
    //as the code is repetative we put in a sapareate function and just change the part of the url where it is different
    // final url = Uri.parse(
    //     'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyCp2cVvDIR0AX4OG4kN7iK5DEMcnc5Ud1s');
    // final response = await http.post(
    //   url,
    //   body: json.encode({
    //     'email': email,
    //     'password': password,
    //     'returnSecureToken': true,
    //   }),
    // );
    // print(json.decode(response.body));
  }

  Future<bool> tryAutoLogin() async {
    final sharePrefs = await SharedPreferences.getInstance();

    //if statement means there is no data saved on 'dataOnDevice' key
    if (!sharePrefs.containsKey('dataOnDevice')) {
      return false;
    }

    final extractedUserData = json.decode(sharePrefs.getString('dataOnDevice'))
        as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isAfter(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  // void logOut() {
  Future<void> logOut() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel(); //cancels the current timer
      _authTimer = null;
    }
    notifyListeners();
    final sharePrefs = await SharedPreferences.getInstance();
    sharePrefs.clear();
    //sharePrefs.remove('dataOnDevice') //not to clear all the data
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel(); //cancels the current timer
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logOut);
    //put seconds: 3 to see how it works
  }
}
