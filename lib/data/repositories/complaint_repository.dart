import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

/// Repository that exposes complaint operations to the app.
class ComplaintRepository {
  ComplaintRepository(this._service);

  final ComplaintService _service;

  /// Create a complaint for an order.
  Future<Complaint> createComplaintForOrder({
    required int orderId,
    required CreateComplaintRequest request,
  }) {
    return _service.createComplaintForOrder(
      orderId: orderId,
      request: request,
    );
  }

  /// Get all complaints created by the current user.
  Future<List<Complaint>> getMyComplaints() {
    return _service.getMyComplaints();
  }

  /// Get complaints assigned to the current salesman.
  Future<List<Complaint>> getAssignedComplaints() {
    return _service.getAssignedComplaints();
  }

  /// Get escalated complaints (Manager Pool).
  Future<List<Complaint>> getEscalatedComplaints() {
    return _service.getEscalatedComplaints();
  }

  /// Get complaints managed by the current manager.
  Future<List<Complaint>> getMyManagedComplaints() {
    return _service.getMyManagedComplaints();
  }

  /// Get all complaints related to the user's company.
  Future<List<Complaint>> getCompanyComplaints() {
    return _service.getCompanyComplaints();
  }

  /// Get details of a specific complaint.
  Future<Complaint> getComplaintDetails({required int complaintId}) {
    return _service.getComplaintDetails(complaintId: complaintId);
  }

  /// Get the history of a complaint.
  Future<List<ComplaintHistoryEntry>> getComplaintHistory({
    required int complaintId,
  }) {
    return _service.getComplaintHistory(complaintId: complaintId);
  }

  /// Escalate a complaint to a manager.
  Future<Complaint> escalateComplaint({
    required int complaintId,
    UpdateComplaintStatusRequest? request,
  }) {
    return _service.escalateComplaint(
      complaintId: complaintId,
      request: request,
    );
  }

  /// Claim an escalated complaint.
  Future<Complaint> claimComplaint({required int complaintId}) {
    return _service.claimComplaint(complaintId: complaintId);
  }

  /// Resolve a complaint.
  Future<Complaint> resolveComplaint({
    required int complaintId,
    required ResolveComplaintRequest request,
  }) {
    return _service.resolveComplaint(
      complaintId: complaintId,
      request: request,
    );
  }

  /// Close (reject) a complaint.
  Future<Complaint> closeComplaint({
    required int complaintId,
    required ResolveComplaintRequest request,
  }) {
    return _service.closeComplaint(
      complaintId: complaintId,
      request: request,
    );
  }
}

/// Provider wiring ComplaintService with authorized Dio instance.
final complaintServiceProvider = Provider<ComplaintService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return ComplaintService(config: config, dioClient: dio);
});

/// Provider that exposes ComplaintRepository.
final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  final ComplaintService service = ref.watch(complaintServiceProvider);
  return ComplaintRepository(service);
});

