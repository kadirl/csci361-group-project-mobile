import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService({required this.config, Dio? dioClient})
    : _dio =
          dioClient ??
          Dio(
            BaseOptions(
              baseUrl: config.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                Headers.acceptHeader: 'application/json',
                Headers.contentTypeHeader: 'application/json',
              },
            ),
          );

  final AppConfig config;
  final Dio _dio;

  static const String _registerPath = 'auth/register';
  static const String _loginPath = 'auth/login';
  static const String _refreshPath = 'auth/refresh';

  Future<SignUpResponse> registerCompany({
    required RegisterCompanyRequest request,
  }) async {
    log('AuthService -> POST $_registerPath');
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _registerPath,
        data: request.toJson(),
      );

      return SignUpResponse.fromJson(_decodeJsonObject(response.data));
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  Future<AuthTokens> login({required LoginRequest request}) async {
    log('AuthService -> POST $_loginPath');
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _loginPath,
        data: request.toJson(),
      );

      return AuthTokens.fromJson(_decodeJsonObject(response.data));
    } on DioException catch (error, stackTrace) {
      // Map 404 to a clear invalid credentials message.
      final int? statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        Error.throwWithStackTrace(
          Exception('Invalid login or password'),
          stackTrace,
        );
      }
      _logAndRethrow(error, stackTrace);
    }
  }

  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    log('AuthService -> POST $_refreshPath');
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _refreshPath,
        queryParameters: <String, dynamic>{'refresh_token': refreshToken},
      );

      return AuthTokens.fromJson(_decodeJsonObject(response.data));
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  Map<String, dynamic> _decodeJsonObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Unexpected auth payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'AuthService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while performing auth request'),
      stackTrace,
    );
  }
}
