import 'package:flutter/material.dart';

class Contact {
  final String id;
  final String name;
  // ignore: non_constant_identifier_names
  final String phone_number;
  final String email;
  final String userEmail;
  final String userId;

  Contact({
    @required this.id,
    @required this.name,
    // ignore: non_constant_identifier_names
    @required this.phone_number,
    @required this.email,
    @required this.userEmail,
    @required this.userId,
  });
}
