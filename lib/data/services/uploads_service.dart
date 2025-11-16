import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/presigned_upload_response.dart';

// Service for S3-related upload endpoints (all protected).
class UploadsService {
  UploadsService({required this.config, Dio? dioClient})
    : _dio =
          dioClient ??
          Dio(
            BaseOptions(
              baseUrl: config.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const <String, Object?>{
                Headers.acceptHeader: 'application/json',
                Headers.contentTypeHeader: 'application/json',
              },
            ),
          );

  final AppConfig config;
  final Dio _dio;

  static const String _uploadUrlPath = 'uploads/upload-url';
  static const String _companyPhotoPath = 'uploads/companies';
  static const String _deleteFilePath = 'uploads/delete-file';

  // Get a pre-signed upload URL for the given extension.
  // Returns a PresignedUploadResponse containing the POST URL, form fields, and final URL.
  Future<PresignedUploadResponse> getUploadUrl({required String ext}) async {
    log('UploadsService -> GET $_uploadUrlPath?ext=$ext');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _uploadUrlPath,
        queryParameters: <String, dynamic>{'ext': ext},
      );

      final dynamic body = response.data;

      if (body is! Map<String, dynamic>) {
        throw FormatException(
          'Expected JSON object, got ${body.runtimeType}',
        );
      }

      return PresignedUploadResponse.fromJson(body);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Notify backend to store company photo by URL.
  Future<void> storeCompanyPhoto({
    required int companyId,
    required String fileUrl,
  }) async {
    final String path = '$_companyPhotoPath/$companyId/photo';
    log('UploadsService -> POST $path?file_url=$fileUrl');

    try {
      await _dio.post<dynamic>(
        path,
        queryParameters: <String, dynamic>{'file_url': fileUrl},
      );
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Delete a file by URL from storage.
  Future<void> deleteFile({required String fileUrl}) async {
    log('UploadsService -> DELETE $_deleteFilePath?file_url=$fileUrl');

    try {
      await _dio.delete<dynamic>(
        _deleteFilePath,
        queryParameters: <String, dynamic>{'file_url': fileUrl},
      );
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'UploadsService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while performing upload request'),
      stackTrace,
    );
  }
}


