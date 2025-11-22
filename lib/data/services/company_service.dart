import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/company.dart';
import '../models/company_update.dart';

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
  static const String _companiesPath = 'company/';

  /// Fetch all companies from the API.
  Future<List<Company>> getAllCompanies() async {
    log('CompanyService -> GET $_companiesPath');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _companiesPath,
      );

      final dynamic payload = response.data;
      
      // Handle wrapped response: {"companies": [...]}
      List<dynamic> companiesList;
      if (payload is Map<String, dynamic>) {
        final dynamic companiesNode = payload['companies'];
        if (companiesNode is List) {
          companiesList = companiesNode;
        } else {
          throw const FormatException('Expected "companies" array in response');
        }
      } else if (payload is Map<dynamic, dynamic>) {
        final Map<String, dynamic> payloadMap = Map<String, dynamic>.from(payload);
        final dynamic companiesNode = payloadMap['companies'];
        if (companiesNode is List) {
          companiesList = companiesNode;
        } else {
          throw const FormatException('Expected "companies" array in response');
        }
      } else if (payload is List) {
        // Handle direct array response (for robustness)
        companiesList = payload;
      } else {
        throw const FormatException('Unexpected companies list payload format.');
      }

      // Map company_id to id for each company before parsing
      return companiesList
          .whereType<Map<dynamic, dynamic>>()
          .map((e) {
            final Map<String, dynamic> companyMap = Map<String, dynamic>.from(e);
            // Map company_id to id for Company.fromJson
            if (companyMap.containsKey('company_id') && !companyMap.containsKey('id')) {
              companyMap['id'] = companyMap['company_id'];
            }
            return Company.fromJson(companyMap);
          })
          .toList();
    } on DioException catch (error, stackTrace) {
      log(
        'CompanyService DioException: ${error.type} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        Exception(error.message ?? 'Network error while loading companies'),
        stackTrace,
      );
    }
  }

  Future<Company> fetchCompany({required int companyId}) async {
    log('CompanyService -> GET $_companyPath?company_id=$companyId');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _companyPath,
        queryParameters: <String, dynamic>{'company_id': companyId},
      );

      final dynamic payload = response.data;
      
      // Log the raw payload to debug ID field
      if (payload is Map) {
        log('CompanyService -> Raw payload keys: ${payload.keys.toList()}');
        log('CompanyService -> Payload contains id: ${payload.containsKey('id')}, value: ${payload['id']}');
        log('CompanyService -> Payload contains company_id: ${payload.containsKey('company_id')}, value: ${payload['company_id']}');
      } else {
        log('CompanyService -> Payload is not a map: ${payload.runtimeType}');
      }
      
      Map<String, dynamic> companyMap;
      if (payload is Map<String, dynamic>) {
        companyMap = payload;
      } else if (payload is Map<dynamic, dynamic>) {
        companyMap = Map<String, dynamic>.from(payload);
      } else {
        throw const FormatException('Unexpected company payload format.');
      }
      
      // Map company_id to id if needed (similar to getAllCompanies)
      if (companyMap.containsKey('company_id') && !companyMap.containsKey('id')) {
        companyMap['id'] = companyMap['company_id'];
        log('CompanyService -> Mapped company_id (${companyMap['company_id']}) to id');
      }
      
      // CRITICAL FIX: The API response schema (CompanySchema) might NOT include the ID.
      // Since we requested a specific companyId, we can inject it if missing.
      if (!companyMap.containsKey('id') && !companyMap.containsKey('company_id')) {
        log('CompanyService -> API response missing ID. Injecting requested companyId: $companyId');
        companyMap['id'] = companyId;
      }
      
      return Company.fromJson(companyMap);
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

  /// Update a company by id (protected, owner only).
  Future<void> updateCompany({
    required int companyId,
    required CompanyUpdateRequest request,
  }) async {
    log('CompanyService -> PUT company/$companyId');

    try {
      await _dio.put<dynamic>(
        'company/$companyId',
        data: request.toJson(),
      );
    } on DioException catch (error, stackTrace) {
      log(
        'CompanyService DioException: ${error.type} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        Exception(error.message ?? 'Network error while updating company'),
        stackTrace,
      );
    }
  }
}

