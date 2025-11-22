import 'package:flutter/foundation.dart';

import '../../core/utils/string_utils.dart';

@immutable
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };
}

@immutable
class RegisterCompanyRequest {
  const RegisterCompanyRequest({required this.company, required this.user});

  final RegisterCompanyCompany company;
  final RegisterCompanyUser user;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'company': company.toJson(),
    'user': user.toJson(),
  };
}

@immutable
class RegisterCompanyCompany {
  const RegisterCompanyCompany({
    required this.name,
    required this.location,
    required this.companyType,
    this.description,
    this.logoUrl,
  });

  final String name;
  final String location;
  final String companyType;
  final String? description;
  final String? logoUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'location': location,
    'company_type': companyType,
    'description': description,
    'logo_url': logoUrl,
  };
}

@immutable
class RegisterCompanyUser {
  RegisterCompanyUser({
    required String firstName,
    required String lastName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.role,
    required this.locale,
  })  : firstName = capitalize(firstName),
        lastName = capitalize(lastName);

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

@immutable
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}

// Signup response that includes tokens and company_id
@immutable
class SignUpResponse {
  const SignUpResponse({
    required this.companyId,
    required this.tokens,
  });

  final int companyId;
  final AuthTokens tokens;

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      companyId: json['company_id'] as int? ?? 0,
      tokens: AuthTokens.fromJson(json),
    );
  }
}
