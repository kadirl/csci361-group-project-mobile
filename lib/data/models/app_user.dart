import 'package:flutter/foundation.dart';

import '../../core/utils/string_utils.dart';

/// Supported application user roles.
enum UserRole {
  owner,
  manager,
  staff,
}

/// Parse a raw role string from backend into a UserRole enum.
UserRole parseUserRole(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'owner':
      return UserRole.owner;
    case 'manager':
      return UserRole.manager;
    case 'staff':
      return UserRole.staff;
    default:
      throw ArgumentError('Invalid user role: $raw');
  }
}

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
  final UserRole role;
  final String locale;

  /// Store any unmodeled payload fields so we do not silently drop data.
  final Map<String, dynamic> additionalData;

  /// Build an instance from the backend payload.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return AppUser(
      // Some endpoints return user_id instead of id
      id: (json['id'] as int?) ?? (json['user_id'] as int?),
      companyId: json['company_id'] as int?,
      firstName: capitalize(json['first_name'] as String? ?? ''),
      lastName: capitalize(json['last_name'] as String? ?? ''),
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      // Enforce only supported roles from backend payload.
      role: parseUserRole(json['role'] as String?),
      locale: json['locale'] as String? ?? '',
      additionalData: extra,
    );
  }
}

