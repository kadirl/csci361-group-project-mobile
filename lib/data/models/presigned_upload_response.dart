// Model representing the presigned POST upload response from the backend.
class PresignedUploadResponse {
  const PresignedUploadResponse({
    required this.uploadUrl,
    required this.fields,
    required this.finalUrl,
  });

  // The base URL to POST to (from put_url.url).
  final String uploadUrl;

  // Form fields to include in the POST request (from put_url.fields).
  final Map<String, String> fields;

  // The final public URL where the file will be accessible (from finalurl).
  final String finalUrl;

  // Parse from JSON response.
  factory PresignedUploadResponse.fromJson(Map<String, dynamic> json) {
    final dynamic putUrlData = json['put_url'];
    final String finalUrl = json['finalurl'] as String? ?? '';

    if (putUrlData is! Map<String, dynamic>) {
      throw FormatException(
        'Expected put_url to be a Map, got ${putUrlData.runtimeType}',
      );
    }

    final String uploadUrl = putUrlData['url'] as String? ?? '';
    final dynamic fieldsData = putUrlData['fields'];

    if (fieldsData is! Map<String, dynamic>) {
      throw FormatException(
        'Expected fields to be a Map, got ${fieldsData.runtimeType}',
      );
    }

    // Convert all field values to strings.
    final Map<String, String> fields = <String, String>{};
    for (final MapEntry<String, dynamic> entry in fieldsData.entries) {
      fields[entry.key] = entry.value.toString();
    }

    return PresignedUploadResponse(
      uploadUrl: uploadUrl,
      fields: fields,
      finalUrl: finalUrl,
    );
  }
}

