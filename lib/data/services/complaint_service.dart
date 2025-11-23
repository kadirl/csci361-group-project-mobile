import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/complaint.dart';

/// Service handling CRUD operations for complaints.
class ComplaintService {
  ComplaintService({required this.config, Dio? dioClient})
      : _dio = dioClient ??
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

  static const String _complaintsPath = 'complaints/';

  /// Get complaint by order ID.
  Future<Complaint?> getComplaintByOrderId({required int orderId}) async {
    final String path = '${_complaintsPath}order/$orderId';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      log('ComplaintService -> Response status: ${response.statusCode}');
      log('ComplaintService -> Response data: ${response.data}');
      final Complaint? complaint = _parseComplaintResponse(response);
      log('ComplaintService -> Parsed complaint: ${complaint?.complaintId}');
      return complaint;
    } on DioException catch (error, stackTrace) {
      // 404 means no complaint exists for this order - return null
      if (error.response?.statusCode == 404) {
        log('ComplaintService -> No complaint found for order $orderId (404)');
        return null;
      }
      log('ComplaintService -> Error getting complaint: ${error.message}, status: ${error.response?.statusCode}');
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Check if a complaint exists for an order.
  Future<bool> checkComplaintExists({required int orderId}) async {
    final String path = '${_complaintsPath}order/$orderId/exists';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      if (body is Map) {
        // Handle both JSON boolean (true/false) and Python boolean (True/False)
        final dynamic exists = body['exists'];
        if (exists is bool) {
          return exists;
        }
        if (exists == true || exists == 'true' || exists == 'True') {
          return true;
        }
        return false;
      }

      return false;
    } on DioException catch (error, stackTrace) {
      // 404 means no complaint exists - return false
      if (error.response?.statusCode == 404) {
        log('ComplaintService -> No complaint exists for order $orderId');
        return false;
      }
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Create a complaint for an order.
  Future<Complaint> createComplaintForOrder({
    required int orderId,
    required CreateComplaintRequest request,
  }) async {
    final String path = '${_complaintsPath}order/$orderId';
    log('ComplaintService -> POST $path');

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: request.toJson(),
      );
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get all complaints created by the current user.
  Future<List<Complaint>> getMyComplaints() async {
    final String path = '${_complaintsPath}my-complaints';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of complaints
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Complaint.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaints list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get complaints assigned to the current salesman.
  Future<List<Complaint>> getAssignedComplaints() async {
    final String path = '${_complaintsPath}assigned-to-me';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of complaints
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Complaint.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaints list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get escalated complaints (Manager Pool).
  Future<List<Complaint>> getEscalatedComplaints() async {
    final String path = '${_complaintsPath}escalated';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of complaints
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Complaint.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaints list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get complaints managed by the current manager.
  Future<List<Complaint>> getMyManagedComplaints() async {
    final String path = '${_complaintsPath}my-managed-complaints';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of complaints
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Complaint.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaints list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get all complaints related to the user's company.
  Future<List<Complaint>> getCompanyComplaints() async {
    final String path = '${_complaintsPath}company';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of complaints
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Complaint.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaints list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get details of a specific complaint.
  Future<Complaint> getComplaintDetails({required int complaintId}) async {
    final String path = '$_complaintsPath$complaintId';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get the history of a complaint.
  Future<List<ComplaintHistoryEntry>> getComplaintHistory({
    required int complaintId,
  }) async {
    final String path = '$_complaintsPath$complaintId/history';
    log('ComplaintService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      log('ComplaintService -> History response: $body');

      // API returns object with complaint_id and history array
      if (body is Map) {
        final dynamic historyList = body['history'];
        if (historyList is List) {
          return historyList
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(ComplaintHistoryEntry.fromJson)
              .toList();
        }
      }

      // Fallback: if body is directly a list
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(ComplaintHistoryEntry.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected complaint history payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Escalate a complaint to a manager.
  Future<Complaint> escalateComplaint({
    required int complaintId,
    UpdateComplaintStatusRequest? request,
  }) async {
    final String path = '$_complaintsPath$complaintId/escalate';
    log('ComplaintService -> PUT $path');

    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        path,
        data: request?.toJson() ?? <String, dynamic>{},
      );
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Claim an escalated complaint.
  Future<Complaint> claimComplaint({required int complaintId}) async {
    final String path = '$_complaintsPath$complaintId/claim';
    log('ComplaintService -> PUT $path');

    try {
      final Response<dynamic> response = await _dio.put<dynamic>(path);
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Resolve a complaint.
  Future<Complaint> resolveComplaint({
    required int complaintId,
    required ResolveComplaintRequest request,
  }) async {
    final String path = '$_complaintsPath$complaintId/resolve';
    log('ComplaintService -> PUT $path');

    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        path,
        data: request.toJson(),
      );
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Close (reject) a complaint.
  Future<Complaint> closeComplaint({
    required int complaintId,
    required ResolveComplaintRequest request,
  }) async {
    final String path = '$_complaintsPath$complaintId/close';
    log('ComplaintService -> PUT $path');

    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        path,
        data: request.toJson(),
      );
      return _parseComplaintResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Convert backend response to a Complaint instance.
  Complaint _parseComplaintResponse(Response<dynamic> response) {
    final dynamic body = response.data;

    log('ComplaintService -> Parsing complaint response: $body');

    // Accept either a direct complaint map or a wrapped { "complaint": { ... } }.
    if (body is Map && body['complaint'] is Map) {
      final Map<String, dynamic> wrapped =
          Map<String, dynamic>.from(body['complaint'] as Map);
      log('ComplaintService -> Found wrapped complaint: $wrapped');
      return Complaint.fromJson(wrapped);
    }
    if (body is Map<String, dynamic>) {
      log('ComplaintService -> Parsing direct complaint map');
      log('ComplaintService -> assigned_salesman_id: ${body['assigned_salesman_id']}');
      log('ComplaintService -> assigned_manager_id: ${body['assigned_manager_id']}');
      return Complaint.fromJson(body);
    }
    if (body is Map<dynamic, dynamic>) {
      log('ComplaintService -> Parsing dynamic complaint map');
      final Map<String, dynamic> converted = Map<String, dynamic>.from(body);
      log('ComplaintService -> assigned_salesman_id: ${converted['assigned_salesman_id']}');
      log('ComplaintService -> assigned_manager_id: ${converted['assigned_manager_id']}');
      return Complaint.fromJson(converted);
    }

    throw const FormatException('Unexpected complaint payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'ComplaintService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while processing complaint'),
      stackTrace,
    );
  }
}

