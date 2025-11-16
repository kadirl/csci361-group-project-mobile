import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/presigned_upload_response.dart';
import '../services/uploads_service.dart';

// Repository wrapping UploadsService.
class UploadsRepository {
  UploadsRepository(this._service);

  final UploadsService _service;

  Future<PresignedUploadResponse> getUploadUrl({required String ext}) {
    return _service.getUploadUrl(ext: ext);
  }

  Future<void> storeCompanyPhoto({
    required int companyId,
    required String fileUrl,
  }) {
    return _service.storeCompanyPhoto(companyId: companyId, fileUrl: fileUrl);
  }

  Future<void> deleteFile({required String fileUrl}) {
    return _service.deleteFile(fileUrl: fileUrl);
  }
}

// Provider wiring UploadsService with authorized Dio interceptor.
final uploadsServiceProvider = Provider<UploadsService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return UploadsService(config: config, dioClient: dio);
});

// Provider exposing UploadsRepository.
final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  final UploadsService service = ref.watch(uploadsServiceProvider);

  return UploadsRepository(service);
});


