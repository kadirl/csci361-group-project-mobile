import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';

// Shared Dio instance that injects auth headers and refreshes tokens on 401s.
// Flow overview:
// 1. Every outgoing request gets the latest access token from authProvider.
// 2. If a response comes back as 401 (except auth/login/refresh), we pause it.
// 3. We run refreshSession() once (shared for all concurrent 401s).
// 4. If refresh succeeded we replay the original request with the new token.
// 5. If refresh failed, the user is signed out and the original error bubbles up.
final authorizedDioProvider = Provider<Dio>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = Dio(
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

  // Track the current refresh request so multiple 401s share the same call.
  Future<void>? refreshInFlight;

  // Attempt to refresh the access token and return whether a valid token exists.
  Future<bool> attemptRefresh() async {
    final Future<void> refreshFuture =
        refreshInFlight ??= ref.read(authProvider.notifier).refreshSession();

    try {
      await refreshFuture;
    } catch (error, stackTrace) {
      log(
        'authorizedDio -> refreshSession threw: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      if (identical(refreshInFlight, refreshFuture)) {
        refreshInFlight = null;
      }
    }

    final String? updatedToken = ref.read(authProvider).accessToken;
    return updatedToken != null && updatedToken.isNotEmpty;
  }

  // Install an interceptor that injects tokens and retries failed requests.
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        // Step 1: inject the freshest access token before request leaves device.
        final String? accessToken = ref.read(authProvider).accessToken;

        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        } else {
          options.headers.remove('Authorization');
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Step 2: only handle 401s for protected endpoints.
        if (!_shouldAttemptRefresh(error)) {
          handler.next(error);
          return;
        }

        final RequestOptions failedRequest = error.requestOptions;
        final bool alreadyRetried = failedRequest.extra['retried'] == true;

        // Step 3: prevent infinite loops. Only retry once per request.
        if (alreadyRetried) {
          handler.next(error);
          return;
        }

        // 401 from protected endpoint; refresh tokens before retrying.
        final bool refreshed = await attemptRefresh();

        // Step 4a: refresh failed -> sign out and bubble the original error.
        if (!refreshed) {
          await ref.read(authProvider.notifier).signOut();
          handler.next(error);
          return;
        }

        failedRequest.extra['retried'] = true;

        final String? newAccessToken = ref.read(authProvider).accessToken;

        // Step 4b: refresh succeeded but state lacks token - treat as failure.
        if (newAccessToken == null || newAccessToken.isEmpty) {
          handler.next(error);
          return;
        }

        failedRequest.headers['Authorization'] = 'Bearer $newAccessToken';

        try {
          // Step 5: replay the original HTTP call with updated headers.
          final Response<dynamic> retryResponse = await dio.fetch(failedRequest);
          handler.resolve(retryResponse);
        } on DioException catch (retryError, stackTrace) {
          log(
            'authorizedDio retry failed: ${retryError.message}',
            error: retryError,
            stackTrace: stackTrace,
          );
          handler.next(retryError);
        }
      },
    ),
  );

  ref.onDispose(dio.close);

  return dio;
});

bool _shouldAttemptRefresh(DioException error) {
  final int? statusCode = error.response?.statusCode;
  if (statusCode != 401) {
    return false;
  }

  final String path = error.requestOptions.path;
  return !path.contains('auth/refresh') && !path.contains('auth/login');
}

