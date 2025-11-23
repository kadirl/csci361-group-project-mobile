import 'package:flutter/foundation.dart';

/// Complaint status enum matching backend complaint statuses.
enum ComplaintStatus {
  open,
  escalated,
  inProgress,
  resolved,
  closed,
}

/// Parse a raw status string from backend into a ComplaintStatus enum.
ComplaintStatus parseComplaintStatus(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'open':
      return ComplaintStatus.open;
    case 'escalated':
      return ComplaintStatus.escalated;
    case 'in_progress':
      return ComplaintStatus.inProgress;
    case 'resolved':
      return ComplaintStatus.resolved;
    case 'closed':
      return ComplaintStatus.closed;
    default:
      // Default to 'open' for null or unknown statuses instead of throwing
      print('WARNING: Unknown complaint status "$raw", defaulting to "open"');
      return ComplaintStatus.open;
  }
}

/// Extension to convert ComplaintStatus to API string value.
extension ComplaintStatusX on ComplaintStatus {
  String get apiValue {
    switch (this) {
      case ComplaintStatus.open:
        return 'open';
      case ComplaintStatus.escalated:
        return 'escalated';
      case ComplaintStatus.inProgress:
        return 'in_progress';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.closed:
        return 'closed';
    }
  }
}

/// Immutable representation of a complaint entity returned by the backend.
@immutable
class Complaint {
  const Complaint({
    required this.complaintId,
    required this.orderId,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.consumerStaffId,
    this.assignedSalesmanId,
    this.assignedManagerId,
    this.resolutionNotes,
    this.cancelOrder,
    this.additionalData = const <String, dynamic>{},
  });

  final int complaintId;
  final int orderId;
  final ComplaintStatus status;
  final String description;
  final String createdAt;
  final String updatedAt;
  final int? consumerStaffId;
  final int? assignedSalesmanId;
  final int? assignedManagerId;
  final String? resolutionNotes;
  final bool? cancelOrder;

  /// Store any unmodeled payload fields so we do not silently drop data.
  final Map<String, dynamic> additionalData;

  /// Build an instance from the backend payload.
  factory Complaint.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return Complaint(
      // Some endpoints return 'id' instead of 'complaint_id'
      complaintId: (json['complaint_id'] as int?) ?? (json['id'] as int?) ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      status: parseComplaintStatus(
        json['status'] as String?,
      ),
      description: json['description'] as String? ?? '',
      // API returns 'created_at' or 'complaint_created_at'
      createdAt: (json['complaint_created_at'] as String?) ??
          (json['created_at'] as String?) ??
          '',
      // API returns 'updated_at' or 'complaint_updated_at'
      updatedAt: (json['complaint_updated_at'] as String?) ??
          (json['updated_at'] as String?) ??
          '',
      consumerStaffId: (json['consumer_staff_id'] as num?)?.toInt(),
      // Try multiple possible field names for assigned personnel
      assignedSalesmanId: (json['assigned_salesman_id'] as num?)?.toInt() ??
          (json['assignedSalesmanId'] as num?)?.toInt() ??
          (json['assigned_salesman_user_id'] as num?)?.toInt(),
      assignedManagerId: (json['assigned_manager_id'] as num?)?.toInt() ??
          (json['assignedManagerId'] as num?)?.toInt() ??
          (json['assigned_manager_user_id'] as num?)?.toInt(),
      resolutionNotes: json['resolution_notes'] as String?,
      cancelOrder: json['cancel_order'] as bool?,
      additionalData: extra,
    );
  }
}

/// Request DTO used for creating a complaint.
@immutable
class CreateComplaintRequest {
  const CreateComplaintRequest({
    required this.description,
  });

  final String description;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'description': description,
    };
  }
}

/// Request DTO used for resolving a complaint.
@immutable
class ResolveComplaintRequest {
  const ResolveComplaintRequest({
    required this.resolutionNotes,
    this.cancelOrder = false,
  });

  final String resolutionNotes;
  final bool cancelOrder;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resolution_notes': resolutionNotes,
      'cancel_order': cancelOrder,
    };
  }
}

/// Request DTO used for updating complaint status (escalate).
@immutable
class UpdateComplaintStatusRequest {
  const UpdateComplaintStatusRequest({
    this.notes,
  });

  final String? notes;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (notes != null) {
      json['notes'] = notes;
    }
    return json;
  }
}

/// Immutable representation of a complaint history entry.
@immutable
class ComplaintHistoryEntry {
  const ComplaintHistoryEntry({
    required this.historyId,
    required this.complaintId,
    required this.status,
    required this.updatedAt,
    this.notes,
    this.userId,
    this.userName,
  });

  final int historyId;
  final int complaintId;
  final ComplaintStatus status;
  final String updatedAt;
  final String? notes;
  final int? userId;
  final String? userName;

  /// Build an instance from the backend payload.
  factory ComplaintHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ComplaintHistoryEntry(
      historyId: (json['history_id'] as int?) ?? (json['id'] as int?) ?? 0,
      complaintId: json['complaint_id'] as int? ?? 0,
      // API returns 'new_status' not 'status'
      status: parseComplaintStatus(
        (json['new_status'] as String?) ?? (json['status'] as String?),
      ),
      // API returns 'updated_at' not 'created_at'
      updatedAt: (json['updated_at'] as String?) ??
          (json['created_at'] as String?) ??
          '',
      notes: json['notes'] as String?,
      // API returns 'changed_by_user_id' not 'user_id'
      userId: (json['changed_by_user_id'] as num?)?.toInt() ??
          (json['user_id'] as num?)?.toInt(),
      userName: json['user_name'] as String?,
    );
  }
}

