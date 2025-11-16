import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/company.dart';
import '../../data/repositories/company_repository.dart';
import 'user_profile_provider.dart';

// Async notifier that derives the user's company profile.
class CompanyProfileNotifier extends AsyncNotifier<Company?> {
  @override
  Future<Company?> build() async {
    final AppUser? user = await ref.watch(userProfileProvider.future);

    if (user == null || user.companyId == null) {
      return null;
    }

    return _loadCompany(user.companyId!);
  }

  Future<void> refreshCompany() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final AppUser? user = await ref.watch(userProfileProvider.future);
      if (user == null || user.companyId == null) {
        return null;
      }
      return _loadCompany(user.companyId!, forceRefresh: true);
    });
  }

  Future<Company> _loadCompany(int companyId, {bool forceRefresh = false}) async {
    final repository = ref.read(companyRepositoryProvider);
    log('CompanyProfileNotifier -> fetching company $companyId');
    return repository.getCompany(
      companyId: companyId,
      forceRefresh: forceRefresh,
    );
  }
}

// Provider that exposes the company profile state.
final companyProfileProvider =
    AsyncNotifierProvider<CompanyProfileNotifier, Company?>(
      CompanyProfileNotifier.new,
    );

