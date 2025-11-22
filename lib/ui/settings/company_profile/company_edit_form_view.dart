import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';

import '../../../core/providers/company_profile_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/company.dart';
import '../../../data/models/company_update.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/uploads_repository.dart';
import '../../shared/product_images_picker.dart';

class CompanyEditFormView extends ConsumerStatefulWidget {
  const CompanyEditFormView({required this.company, super.key});

  final Company company;

  @override
  ConsumerState<CompanyEditFormView> createState() => _CompanyEditFormViewState();
}

class _CompanyEditFormViewState extends ConsumerState<CompanyEditFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _locationCtrl;

  // Track original logo URL for deletion tracking
  String? _originalLogoUrl;
  
  // Track current logo URL (can be kept existing or newly uploaded)
  String? _currentLogoUrl;

  // Dio client for direct upload to S3 using presigned URLs
  final Dio _uploadDio = Dio();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with current company data
    _nameCtrl = TextEditingController(text: widget.company.name);
    _descriptionCtrl = TextEditingController(text: widget.company.description ?? '');
    _locationCtrl = TextEditingController(text: widget.company.location);
    
    // Initialize logo URL tracking
    _originalLogoUrl = widget.company.logoUrl;
    _currentLogoUrl = widget.company.logoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyProfileTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.companyName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '${l10n.companyName} is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.companyLocation,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '${l10n.companyLocation} is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.companyDescription,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Logo image picker section
                if (_currentLogoUrl != null) ...<Widget>[
                  Text(
                    'Company Logo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 96,
                          height: 96,
                          color: Colors.grey.shade200,
                          child: Image.network(
                            _currentLogoUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentLogoUrl = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Logo image picker (only show if no logo is set)
                if (_currentLogoUrl == null)
                  ProductImagesPicker(
                    maxImages: 1,
                    labelText: 'Company Logo',
                    placeholderText: 'Select company logo',
                    uploadImage: _uploadLogoImageToS3,
                    onImagesChanged: _handleLogoImageChanged,
                    isEnabled: true,
                  ),
                const SizedBox(height: 12),
                // Company type field - read-only
                TextFormField(
                  initialValue: widget.company.companyType == CompanyType.supplier
                      ? l10n.companyTypeSupplier
                      : l10n.companyTypeConsumer,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.companyType,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : () => _submit(l10n),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.commonSubmit),
                  style: FilledButton.styleFrom(
                    minimumSize: ButtonSizes.mdFill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Upload a single logo image to S3 using the presigned POST from UploadsRepository
  Future<String> _uploadLogoImageToS3(
    Uint8List imageBytes,
    String fileExtension,
  ) async {
    try {
      log(
        'CompanyEditFormView -> Starting logo upload (ext: $fileExtension, '
        'size: ${imageBytes.length} bytes)',
      );

      // Get repository from Riverpod
      final UploadsRepository uploadsRepository =
          ref.read(uploadsRepositoryProvider);

      // Ask backend for presigned POST response for this extension
      log(
        'CompanyEditFormView -> Requesting presigned POST for extension: '
        '$fileExtension',
      );
      final presignedResponse =
          await uploadsRepository.getUploadUrl(ext: fileExtension);
      log(
        'CompanyEditFormView -> Received presigned POST: url=${presignedResponse.uploadUrl}, '
        'finalUrl=${presignedResponse.finalUrl}',
      );

      // Build form data with all required fields plus the file
      final FormData formData = FormData.fromMap(<String, dynamic>{
        ...presignedResponse.fields,
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'logo.$fileExtension',
        ),
      });

      // Upload to S3 using POST with form data
      log('CompanyEditFormView -> Uploading logo to S3 via POST...');
      final Response<dynamic> uploadResponse = await _uploadDio.post<dynamic>(
        presignedResponse.uploadUrl,
        data: formData,
        options: Options(
          validateStatus: (int? status) {
            // S3 returns 204 No Content or 200 OK on successful upload
            return status != null && status >= 200 && status < 300;
          },
        ),
      );

      log(
        'CompanyEditFormView -> S3 upload response: status=${uploadResponse.statusCode}, '
        'headers=${uploadResponse.headers}',
      );

      if (uploadResponse.statusCode != null &&
          uploadResponse.statusCode! >= 200 &&
          uploadResponse.statusCode! < 300) {
        log(
          'CompanyEditFormView -> Successfully uploaded logo to S3: '
          '${presignedResponse.finalUrl}',
        );
      } else {
        throw Exception(
          'S3 upload failed with status ${uploadResponse.statusCode}',
        );
      }

      // Return the final public URL where the file is accessible
      return presignedResponse.finalUrl;
    } catch (error, stackTrace) {
      log(
        'CompanyEditFormView -> Failed to upload logo to S3: $error',
        error: error,
        stackTrace: stackTrace,
      );

      // Re-throw the error so the widget can handle it
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // Update local state when the image picker reports new URL
  void _handleLogoImageChanged(List<String> urls) {
    setState(() {
      _currentLogoUrl = urls.isNotEmpty ? urls.first : null;
    });
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get company ID from company or fallback to user's companyId
    final int? companyId = widget.company.id ?? 
        ref.read(userProfileProvider).asData?.value?.companyId;

    if (companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company ID is missing'),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Delete old logo if it was removed
      if (_originalLogoUrl != null && _currentLogoUrl == null) {
        log('CompanyEditFormView -> Deleting removed logo...');
        final UploadsRepository uploadsRepository =
            ref.read(uploadsRepositoryProvider);
        try {
          await uploadsRepository.deleteFile(fileUrl: _originalLogoUrl!);
          log('CompanyEditFormView -> Deleted logo: $_originalLogoUrl');
        } catch (error) {
          log(
            'CompanyEditFormView -> Failed to delete logo $_originalLogoUrl: $error',
          );
          // Continue with update even if deletion fails
        }
      }

      // Only include fields that have changed or are required
      final CompanyUpdateRequest request = CompanyUpdateRequest(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty 
            ? null 
            : _descriptionCtrl.text.trim(),
        logoUrl: _currentLogoUrl,
      );

      final repo = ref.read(companyRepositoryProvider);
      await repo.updateCompany(
        companyId: companyId,
        request: request,
      );

      // Refresh the company profile
      ref.read(companyProfileProvider.notifier).refreshCompany();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile updated successfully'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.errorLoadingCompany),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

