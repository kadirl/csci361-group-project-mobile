import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/linking.dart';

/// Service handling CRUD operations for linkings.
class LinkingService {
  LinkingService({required this.config, Dio? dioClient})
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

  static const String _linkingsPath = 'linkings/';

  /// Create a new linking request.
  Future<Linking> createLinking({
    required int companyId,
    required LinkingRequest request,
  }) async {
    log('LinkingService -> POST $_linkingsPath?company_id=$companyId');

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _linkingsPath,
        data: request.toJson(),
        queryParameters: <String, dynamic>{
          'company_id': companyId,
        },
      );
      return _parseLinkingResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get all linkings for a company (as supplier or consumer).
  Future<List<Linking>> getLinkingsByCompany({required int companyId}) async {
    log('LinkingService -> GET $_linkingsPath?company_id=$companyId');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _linkingsPath,
        queryParameters: <String, dynamic>{'company_id': companyId},
      );
      final dynamic body = response.data;

      // API returns: { "linkings": [ { ...linking... }, ... ] } or [ { ...linking... }, ... ]
      if (body is Map) {
        final dynamic linkingsNode = body['linkings'];
        if (linkingsNode is List) {
          return linkingsNode
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(Linking.fromJson)
              .toList();
        }
      }
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Linking.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected linkings list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Update a linking's response (accept/reject/unlink).
  Future<Linking> updateLinkingResponse({
    required int linkingId,
    required LinkingResponseRequest request,
  }) async {
    final String path = '${_linkingsPath}supplier_response/$linkingId';
    log('LinkingService -> PATCH $path');

    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        path,
        data: request.toJson(),
      );
      return _parseLinkingResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Convert backend response to a Linking instance.
  Linking _parseLinkingResponse(Response<dynamic> response) {
    final dynamic body = response.data;

    // Accept either a direct linking map or a wrapped { "linking": { ... } }.
    if (body is Map && body['linking'] is Map) {
      final Map<String, dynamic> wrapped =
          Map<String, dynamic>.from(body['linking'] as Map);
      return Linking.fromJson(wrapped);
    }
    if (body is Map<String, dynamic>) {
      return Linking.fromJson(body);
    }
    if (body is Map<dynamic, dynamic>) {
      return Linking.fromJson(Map<String, dynamic>.from(body));
    }

    throw const FormatException('Unexpected linking payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'LinkingService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while processing linking'),
      stackTrace,
    );
  }
}

