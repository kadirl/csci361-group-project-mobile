import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../data/repositories/uploads_repository.dart';

/// Utility class for uploading files to S3 using presigned POST URLs.
class S3UploadUtils {
  S3UploadUtils._();

  // Separate Dio client for direct S3 uploads (without auth interceptors).
  static final Dio _uploadDio = Dio();

  /// Uploads a file to S3 using a presigned POST URL.
  ///
  /// [uploadsRepository] - Repository to get presigned URLs from backend.
  /// [fileBytes] - The file content as bytes.
  /// [fileExtension] - File extension (e.g., 'jpg', 'png', 'pdf').
  /// [filename] - Optional filename. Defaults to 'file.$fileExtension'.
  ///
  /// Returns the final public URL where the file is accessible.
  ///
  /// Throws an exception if the upload fails.
  static Future<String> uploadToS3({
    required UploadsRepository uploadsRepository,
    required Uint8List fileBytes,
    required String fileExtension,
    String? filename,
  }) async {
    try {
      log(
        'S3UploadUtils -> Starting file upload (ext: $fileExtension, '
        'size: ${fileBytes.length} bytes)',
      );

      // Request presigned POST URL from backend.
      log(
        'S3UploadUtils -> Requesting presigned POST for extension: '
        '$fileExtension',
      );
      final presignedResponse =
          await uploadsRepository.getUploadUrl(ext: fileExtension);
      log(
        'S3UploadUtils -> Received presigned POST: url=${presignedResponse.uploadUrl}, '
        'finalUrl=${presignedResponse.finalUrl}',
      );

      // Build form data with all required fields plus the file.
      final FormData formData = FormData.fromMap(<String, dynamic>{
        ...presignedResponse.fields,
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename ?? 'file.$fileExtension',
        ),
      });

      // Upload to S3 using POST with form data.
      log('S3UploadUtils -> Uploading file to S3 via POST...');
      final Response<dynamic> uploadResponse = await _uploadDio.post<dynamic>(
        presignedResponse.uploadUrl,
        data: formData,
        options: Options(
          validateStatus: (int? status) {
            // S3 returns 204 No Content or 200 OK on successful upload.
            return status != null && status >= 200 && status < 300;
          },
        ),
      );

      log(
        'S3UploadUtils -> S3 upload response: status=${uploadResponse.statusCode}, '
        'headers=${uploadResponse.headers}',
      );

      if (uploadResponse.statusCode != null &&
          uploadResponse.statusCode! >= 200 &&
          uploadResponse.statusCode! < 300) {
        log(
          'S3UploadUtils -> Successfully uploaded file to S3: '
          '${presignedResponse.finalUrl}',
        );
      } else {
        throw Exception(
          'S3 upload failed with status ${uploadResponse.statusCode}',
        );
      }

      // Return the final public URL where the file is accessible.
      return presignedResponse.finalUrl;
    } catch (error, stackTrace) {
      log(
        'S3UploadUtils -> Failed to upload file to S3: $error',
        error: error,
        stackTrace: stackTrace,
      );

      // Re-throw the error so the caller can handle it.
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

