import 'package:flutter/foundation.dart';

/// Immutable representation of a user returned by the backend.
@immutable
class AppUser {
  const AppUser({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    required this.locale,
    this.id,
    this.companyId,
    this.additionalData = const <String, dynamic>{},
  });

  final int? id;
  final int? companyId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String role;
  final String locale;

  /// Store any unmodeled payload fields so we do not silently drop data.
  final Map<String, dynamic> additionalData;

  /// Build an instance from the backend payload.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return AppUser(
      id: json['id'] as int?,
      companyId: json['company_id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      additionalData: extra,
    );
  }
}

