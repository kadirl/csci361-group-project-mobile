import 'package:flutter/foundation.dart';

// Request body for POST /user/ (UserSchema in API)
@immutable
class UserCreateRequest {
  const UserCreateRequest({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.role,
    required this.locale,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String password;
  final String role;
  final String locale;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
        'role': role,
        'locale': locale,
      };
}


