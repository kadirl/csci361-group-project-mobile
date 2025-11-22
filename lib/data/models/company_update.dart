import 'package:flutter/foundation.dart';

// Request body for PUT /company/{company_id} (UpdateCompany schema in API)
@immutable
class CompanyUpdateRequest {
  const CompanyUpdateRequest({
    this.name,
    this.description,
    this.logoUrl,
    this.location,
    this.status,
  });

  final String? name;
  final String? description;
  final String? logoUrl;
  final String? location;
  final String? status; // "active" or "suspended"

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    
    if (name != null) {
      json['name'] = name;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (logoUrl != null) {
      json['logo_url'] = logoUrl;
    }
    if (location != null) {
      json['location'] = location;
    }
    if (status != null) {
      json['status'] = status;
    }
    
    return json;
  }
}

