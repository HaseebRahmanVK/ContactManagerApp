// import 'dart:collection';

import 'package:scoped_model/scoped_model.dart';
import 'dart:async';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';

import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../models/user.dart';
import '../models/auth.dart';

class ConnectedContactsModel extends Model {
  List<Contact> _contacts = [];
  User _authenticatedUser;
  bool _isLoading = false;
}

class ContactsModel extends ConnectedContactsModel {
  List<Contact> get allContacts {
    return List.from(_contacts);
  }

  List<Contact> get displayedContacts {
    return List.from(_contacts);
  }

  Future<Null> fetchContacts({onlyForUser = false}) {
    _isLoading = true;
    _contacts = [];
    notifyListeners();
    return http
        .get(
            'https://flutter-products-2c3e2.firebaseio.com/contacts.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      final List<Contact> fetchedContactList = [];
      final Map<String, dynamic> contactListData = json.decode(response.body);
      if (contactListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      contactListData.forEach((String contactId, dynamic contactData) {
        final Contact contact = Contact(
            id: contactId,
            name: contactData['name'],
            phone_number: contactData['phone_number'],
            email: contactData['email'],
            userEmail: contactData['userEmail'],
            userId: contactData['userId']);
        fetchedContactList.add(contact);
      });
      _contacts = onlyForUser
          ? fetchedContactList.where((Contact contact) {
              return contact.userId == _authenticatedUser.id;
            }).toList()
          : fetchedContactList;
      _isLoading = false;
      notifyListeners();
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  Future<bool> addContact(
      String name, String phone_number, String email) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> contactData = {
      'name': name,
      'phone_number': phone_number,
      'email': email,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id
    };

    try {
      final http.Response response = await http.post(
          'https://flutter-products-2c3e2.firebaseio.com/contacts.json?auth=${_authenticatedUser.token}',
          body: json.encode(contactData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);

      final Contact newContact = Contact(
          id: responseData['name'],
          name: name,
          phone_number: phone_number,
          email: email,
          userEmail: _authenticatedUser.email,
          userId: _authenticatedUser.id);
      _contacts.add(newContact);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

class UserModel extends ConnectedContactsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
    http.Response response;
    if (mode == AuthMode.Login) {
      response = await http.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyA1VmrJb-qcolcYgsI6VYgjiea7BYDcpoY',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      response = await http.post(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyA1VmrJb-qcolcYgsI6VYgjiea7BYDcpoY',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went Wrong';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeeded!';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);

      setAuthTimeout(int.parse(responseData['expiresIn']));
      _userSubject.add(true);
      final DateTime now = DateTime.now();
      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'Email already Exists';
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This Email was not found';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'The Password is Invalid';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      final int tokenLifeSpan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifeSpan);
      notifyListeners();
    }
  }

  void logout() async {
    print('Logout');
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

class UtilityModel extends ConnectedContactsModel {
  bool get isLoading {
    return _isLoading;
  }
}
