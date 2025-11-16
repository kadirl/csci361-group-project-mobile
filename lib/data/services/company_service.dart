import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/company.dart';

// Service responsible for retrieving company details.
class CompanyService {
  CompanyService({required this.config, Dio? dioClient})
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

  static const String _companyPath = 'company/get-company';

  Future<Company> fetchCompany({required int companyId}) async {
    log('CompanyService -> GET $_companyPath?company_id=$companyId');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _companyPath,
        queryParameters: <String, dynamic>{'company_id': companyId},
      );

      final dynamic payload = response.data;
      if (payload is Map<String, dynamic>) {
        return Company.fromJson(payload);
      }
      if (payload is Map<dynamic, dynamic>) {
        return Company.fromJson(Map<String, dynamic>.from(payload));
      }

      throw const FormatException('Unexpected company payload format.');
    } on DioException catch (error, stackTrace) {
      log(
        'CompanyService DioException: ${error.type} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        Exception(error.message ?? 'Network error while loading company'),
        stackTrace,
      );
    }
  }
}

