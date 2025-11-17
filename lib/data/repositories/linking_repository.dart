import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/linking.dart';
import '../services/linking_service.dart';

/// Repository that exposes linking operations to the app.
class LinkingRepository {
  LinkingRepository(this._service);

  final LinkingService _service;

  /// Create a new linking request.
  Future<Linking> createLinking({
    required int companyId,
    required LinkingRequest request,
  }) {
    return _service.createLinking(
      companyId: companyId,
      request: request,
    );
  }

  /// Get all linkings for a company.
  Future<List<Linking>> getLinkingsByCompany({required int companyId}) {
    return _service.getLinkingsByCompany(companyId: companyId);
  }

  /// Update a linking's response (accept/reject/unlink).
  Future<Linking?> updateLinkingResponse({
    required int linkingId,
    required LinkingResponseRequest request,
  }) {
    return _service.updateLinkingResponse(
      linkingId: linkingId,
      request: request,
    );
  }

  /// Accept a linking request.
  Future<Linking?> acceptLinking({required int linkingId}) {
    return _service.updateLinkingResponse(
      linkingId: linkingId,
      request: const LinkingResponseRequest(status: LinkingStatus.accepted),
    );
  }

  /// Reject a linking request.
  Future<Linking?> rejectLinking({required int linkingId}) {
    return _service.updateLinkingResponse(
      linkingId: linkingId,
      request: const LinkingResponseRequest(status: LinkingStatus.rejected),
    );
  }

  /// Unlink companies.
  Future<Linking?> unlinkLinking({required int linkingId}) {
    return _service.updateLinkingResponse(
      linkingId: linkingId,
      request: const LinkingResponseRequest(status: LinkingStatus.unlinked),
    );
  }
}

/// Provider wiring LinkingService with authorized Dio instance.
final linkingServiceProvider = Provider<LinkingService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return LinkingService(config: config, dioClient: dio);
});

/// Provider that exposes LinkingRepository.
final linkingRepositoryProvider = Provider<LinkingRepository>((ref) {
  final LinkingService service = ref.watch(linkingServiceProvider);
  return LinkingRepository(service);
});

