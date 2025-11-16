import 'package:flutter/foundation.dart';

/// Linking status enum matching backend LinkingStatus.
enum LinkingStatus {
  pending,
  accepted,
  rejected,
  unlinked,
}

/// Parse a raw status string from backend into a LinkingStatus enum.
LinkingStatus parseLinkingStatus(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'pending':
      return LinkingStatus.pending;
    case 'accepted':
      return LinkingStatus.accepted;
    case 'rejected':
      return LinkingStatus.rejected;
    case 'unlinked':
      return LinkingStatus.unlinked;
    default:
      throw ArgumentError('Invalid linking status: $raw');
  }
}

/// Extension to convert LinkingStatus to API string value.
extension LinkingStatusX on LinkingStatus {
  String get apiValue => name;
}

/// Immutable representation of a linking entity returned by the backend.
@immutable
class Linking {
  const Linking({
    required this.consumerCompanyId,
    required this.supplierCompanyId,
    required this.requestedByUserId,
    required this.status,
    this.linkingId,
    this.respondedByUserId,
    this.assignedSalesmanUserId,
    this.message,
    this.createdAt,
    this.updatedAt,
    this.additionalData = const <String, dynamic>{},
  });

  final int? linkingId;
  final int consumerCompanyId;
  final int supplierCompanyId;
  final int requestedByUserId;
  final int? respondedByUserId;
  final int? assignedSalesmanUserId;
  final LinkingStatus status;
  final String? message;
  final String? createdAt;
  final String? updatedAt;

  /// Store any unmodeled payload fields so we do not silently drop data.
  final Map<String, dynamic> additionalData;

  /// Build an instance from the backend payload.
  factory Linking.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return Linking(
      // Some endpoints return linking_id instead of id
      linkingId: (json['id'] as int?) ?? (json['linking_id'] as int?),
      consumerCompanyId: json['consumer_company_id'] as int? ?? 0,
      supplierCompanyId: json['supplier_company_id'] as int? ?? 0,
      requestedByUserId: json['requested_by_user_id'] as int? ?? 0,
      respondedByUserId: json['responded_by_user_id'] as int?,
      assignedSalesmanUserId: json['assigned_salesman_user_id'] as int?,
      status: parseLinkingStatus(json['status'] as String?),
      message: json['message'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      additionalData: extra,
    );
  }
}

/// Request DTO used for creating a linking.
@immutable
class LinkingRequest {
  const LinkingRequest({
    this.message,
  });

  final String? message;

  /// Convert to API payload according to LinkingSchema.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (message != null) 'message': message,
    };
  }
}

/// Request DTO used for updating a linking response.
@immutable
class LinkingResponseRequest {
  const LinkingResponseRequest({
    required this.status,
  });

  final LinkingStatus status;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.apiValue,
    };
  }
}

