import 'package:flutter/foundation.dart';

// Immutable representation of a company entity.
@immutable
class Company {
  const Company({
    required this.name,
    required this.location,
    required this.companyType,
    this.id,
    this.description,
    this.logoUrl,
    this.extra = const <String, dynamic>{},
  });

  final int? id;
  final String name;
  final String location;
  final String companyType;
  final String? description;
  final String? logoUrl;
  final Map<String, dynamic> extra;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      companyType: json['company_type'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      extra: Map<String, dynamic>.from(json),
    );
  }
}

