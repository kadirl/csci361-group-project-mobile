import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:swe_mobile/core/config/app_config.dart';
import 'package:swe_mobile/data/models/city.dart';

// Service responsible for retrieving the list of available cities.
class CityService {
  CityService({required this.config, Dio? dioClient})
    : _dio =
          dioClient ??
          Dio(
            BaseOptions(
              baseUrl: config.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {Headers.acceptHeader: 'application/json'},
            ),
          );

  final AppConfig config;
  final Dio _dio;
  static const String _citiesPath = 'cities/get-all-cities';

  Future<List<City>> fetchCities() async {
    final Uri requestUri = _buildCitiesUri();
    log('fetchCities -> GET $requestUri');

    try {
      final Response<dynamic> response = await _dio.getUri(requestUri);
      log(
        'fetchCities response status: ${response.statusCode}, type: ${response.data.runtimeType}',
      );

      if (_isSuccessStatus(response.statusCode)) {
        final dynamic decoded = response.data;

        if (decoded is List) {
          return decoded
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> entry) =>
                    Map<String, dynamic>.from(entry),
              )
              .map(City.fromJson)
              .toList();
        }

        throw const FormatException('Unexpected city payload format.');
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Failed to fetch cities (status: ${response.statusCode ?? 'unknown'})',
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (error, stackTrace) {
      log(
        'fetchCities DioException: ${error.type} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        Exception(error.message ?? 'Network error while loading cities'),
        stackTrace,
      );
    }
  }

  bool _isSuccessStatus(int? statusCode) {
    if (statusCode == null) {
      return false;
    }

    return statusCode >= 200 && statusCode < 300;
  }

  Uri _buildCitiesUri() {
    final Uri baseUri = Uri.parse(config.apiRoot);
    return baseUri.resolve(_citiesPath);
  }
}
