import 'package:flutter/foundation.dart';

// Request body for PUT /user/{user_id} (UpdateUserSchema in API)
@immutable
class UserUpdateRequest {
  const UserUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'email': email,
      };
}

