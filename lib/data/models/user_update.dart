import 'package:flutter/foundation.dart';

import '../../core/utils/string_utils.dart';

// Request body for PUT /user/{user_id} (UpdateUserSchema in API)
@immutable
class UserUpdateRequest {
  UserUpdateRequest({
    required String firstName,
    required String lastName,
    required this.phoneNumber,
    required this.email,
  })  : firstName = capitalize(firstName),
        lastName = capitalize(lastName);

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

