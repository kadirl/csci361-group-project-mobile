import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/app_user.dart';

/// Service that communicates with user related endpoints.
class UserService {
  UserService({required this.config, Dio? dioClient})
    : _dio =
          dioClient ??
          Dio(
            BaseOptions(
              baseUrl: config.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: <String, Object?>{
                Headers.acceptHeader: 'application/json',
                Headers.contentTypeHeader: 'application/json',
              },
            ),
          );

  final AppConfig config;
  final Dio _dio;

  static const String _currentUserPath = 'user/me';
  static const String _userByIdPath = 'user/get-user';

  /// Load the profile of the authenticated user.
  Future<AppUser> fetchCurrentUser() async {
    log('UserService -> GET $_currentUserPath');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _currentUserPath,
      );

      return _parseUserResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Load a user profile by identifier.
  Future<AppUser> fetchUserById({required int userId}) async {
    log('UserService -> GET $_userByIdPath?user_id=$userId');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        _userByIdPath,
        queryParameters: <String, dynamic>{'user_id': userId},
      );

      return _parseUserResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Parse the backend response and convert it into an [AppUser].
  AppUser _parseUserResponse(Response<dynamic> response) {
    final dynamic body = response.data;

    if (body is Map<String, dynamic>) {
      return AppUser.fromJson(body);
    }

    if (body is Map<dynamic, dynamic>) {
      return AppUser.fromJson(Map<String, dynamic>.from(body));
    }

    throw const FormatException('Unexpected user payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'UserService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while loading user data'),
      stackTrace,
    );
  }
}

