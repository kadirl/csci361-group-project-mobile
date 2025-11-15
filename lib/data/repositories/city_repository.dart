import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swe_mobile/core/config/app_config.dart';
import 'package:swe_mobile/data/models/city.dart';

import '../services/city_service.dart';

// Repository responsible for abstracting access to city data
class CityRepository {
  CityRepository(this._cityService);

  final CityService _cityService;

  List<City>? _cachedCities;

  // Fetch cities from the service with optional in-memory caching.
  Future<List<City>> getCities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCities != null) {
      return _cachedCities!;
    }

    final List<City> cities = await _cityService.fetchCities();

    _cachedCities = cities;

    return cities;
  }

  // Clear the cached list so the next fetch hits the API again.
  void clearCache() {
    _cachedCities = null;
  }
}

// Provider that exposes CityService
final cityServiceProvider = Provider<CityService>((ref) {
  final AppConfig appConfig = ref.watch(appConfigProvider);

  return CityService(config: appConfig);
});

// Provider that exposes CityRepository
final cityRepositoryProvider = Provider<CityRepository>((ref) {
  final cityService = ref.watch(cityServiceProvider);

  return CityRepository(cityService);
});

// Async notifier that manages loading/error state for the city list
class CityListNotifier extends AsyncNotifier<List<City>> {
  @override
  Future<List<City>> build() async {
    log('CityListNotifier build triggered');

    return _fetchCities();
  }

  Future<void> refreshCities() async {
    log('CityListNotifier refresh triggered');

    // Surface a loading state while the request is in-flight.
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _fetchCities(forceRefresh: true));
  }

  Future<List<City>> _fetchCities({bool forceRefresh = false}) async {
    final CityRepository repository = ref.watch(cityRepositoryProvider);

    log('CityListNotifier fetching cities - forceRefresh: $forceRefresh');

    // Delegate to the repository, allowing it to decide whether to hit cache.
    return repository.getCities(forceRefresh: forceRefresh);
  }
}

// Provider that exposes the city list notifier
final cityListProvider =
    AsyncNotifierProvider.autoDispose<CityListNotifier, List<City>>(
      CityListNotifier.new,
      retry: (_, __) => null,
    );
