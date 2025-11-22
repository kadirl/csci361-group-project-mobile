import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/company.dart';
import '../models/company_update.dart';
import '../services/company_service.dart';

// Repository responsible for retrieving company details with light caching.
class CompanyRepository {
  CompanyRepository(this._companyService);

  final CompanyService _companyService;

  Company? _cachedCompany;
  int? _cachedCompanyId;

  Future<Company> getCompany({
    required int companyId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedCompany != null &&
        _cachedCompanyId == companyId) {
      return _cachedCompany!;
    }

    final Company company = await _companyService.fetchCompany(
      companyId: companyId,
    );
    _cachedCompany = company;
    _cachedCompanyId = companyId;
    return company;
  }

  /// Get all companies from the API (no caching).
  Future<List<Company>> getAllCompanies() async {
    return _companyService.getAllCompanies();
  }

  /// Update a company by id (protected, owner only).
  Future<void> updateCompany({
    required int companyId,
    required CompanyUpdateRequest request,
  }) async {
    await _companyService.updateCompany(
      companyId: companyId,
      request: request,
    );
    
    // Clear cache after update to force refresh on next fetch
    clearCache();
  }

  void clearCache() {
    _cachedCompany = null;
    _cachedCompanyId = null;
  }
}

// Provider that wires the company service with the authorized Dio instance.
final companyServiceProvider = Provider<CompanyService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return CompanyService(config: config, dioClient: dio);
});

// Provider that exposes CompanyRepository to the rest of the app.
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final CompanyService service = ref.watch(companyServiceProvider);

  return CompanyRepository(service);
});

