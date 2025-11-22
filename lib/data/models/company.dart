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
  final CompanyType companyType;
  final String? description;
  final String? logoUrl;
  final Map<String, dynamic> extra;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      // Some endpoints return 'company_id' instead of 'id'
      id: (json['id'] as int?) ?? (json['company_id'] as int?),
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      companyType: CompanyTypeX.fromJson(json['company_type'] as String?),
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      extra: Map<String, dynamic>.from(json),
    );
  }
}

// Enumerates the only valid company types returned by the backend.
enum CompanyType { supplier, consumer }

extension CompanyTypeX on CompanyType {
  static CompanyType fromJson(String? value) {
    return CompanyType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CompanyType.supplier,
    );
  }

  String get apiValue => name;
}

