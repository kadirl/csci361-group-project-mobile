import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/complaint.dart';
import '../../data/repositories/complaint_repository.dart';

/// State for complaint operations.
class ComplaintState {
  const ComplaintState({
    this.complaint,
    this.isLoading = false,
    this.error,
  });

  final Complaint? complaint;
  final bool isLoading;
  final String? error;

  /// CopyWith method for immutability.
  ComplaintState copyWith({
    Complaint? complaint,
    bool? isLoading,
    String? error,
  }) {
    return ComplaintState(
      complaint: complaint ?? this.complaint,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing complaint state for a specific order.
class OrderComplaintNotifier extends Notifier<ComplaintState> {
  @override
  ComplaintState build() {
    return const ComplaintState();
  }

  /// Load complaint for a specific order.
  Future<void> loadComplaintForOrder({required int orderId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(complaintRepositoryProvider);

      // Use the new endpoint to get complaint by order ID
      final Complaint? complaint = await repository.getComplaintByOrderId(
        orderId: orderId,
      );

      state = state.copyWith(
        complaint: complaint,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      log(
        'OrderComplaintNotifier -> Error loading complaint: $e',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a complaint for an order.
  Future<void> createComplaint({
    required int orderId,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(complaintRepositoryProvider);

      final CreateComplaintRequest request = CreateComplaintRequest(
        description: description,
      );

      final Complaint createdComplaint = await repository.createComplaintForOrder(
        orderId: orderId,
        request: request,
      );

      state = state.copyWith(
        complaint: createdComplaint,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      log(
        'OrderComplaintNotifier -> Error creating complaint: $e',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Refresh the complaint for the current order.
  Future<void> refresh() async {
    final Complaint? currentComplaint = state.complaint;
    if (currentComplaint != null) {
      await loadComplaintForOrder(orderId: currentComplaint.orderId);
    }
  }
}

/// Provider for order complaint state.
/// Use this provider to manage complaint state for a specific order.
final orderComplaintProvider =
    NotifierProvider<OrderComplaintNotifier, ComplaintState>(
  OrderComplaintNotifier.new,
);

/// Provider for getting a complaint by order ID.
/// This provider automatically loads the complaint when the orderId changes.
/// Uses the new GET /complaints/order/{order_id} endpoint.
final complaintByOrderIdProvider =
    FutureProvider.family<Complaint?, int>((ref, orderId) async {
  final repository = ref.read(complaintRepositoryProvider);

  try {
    // Use the new endpoint to get complaint by order ID
    final Complaint? complaint = await repository.getComplaintByOrderId(
      orderId: orderId,
    );
    return complaint;
  } catch (e) {
    log('complaintByOrderIdProvider -> Error: $e');
    return null;
  }
});

