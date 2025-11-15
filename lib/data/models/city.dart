import 'package:flutter/foundation.dart';

// Data model that stores city identifier and localized names.
@immutable
class City {
  const City({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.nameKz,
  });

  final int id;
  final String nameEn;
  final String nameRu;
  final String nameKz;

  factory City.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String sanitize(dynamic value) => value is String ? value.trim() : '';

    final int cityId = parseId(json['city_id']);
    final String nameEn = sanitize(json['city_name']);
    final String nameRu = sanitize(json['city_name_ru']);
    final String nameKz = sanitize(json['city_name_kz']);

    return City(
      id: cityId,
      nameEn: nameEn,
      nameRu: nameRu,
      nameKz: nameKz,
    );
  }

  // Resolve the display name for the requested locale with fallbacks.
  String localizedName({required String localeCode}) {
    final String normalized = localeCode.toLowerCase();

    if (normalized.startsWith('ru') && nameRu.isNotEmpty) {
      return nameRu;
    }

    if ((normalized.startsWith('kk') || normalized.startsWith('kz')) &&
        nameKz.isNotEmpty) {
      return nameKz;
    }

    if (normalized.startsWith('en') && nameEn.isNotEmpty) {
      return nameEn;
    }

    if (nameEn.isNotEmpty) {
      return nameEn;
    }

    if (nameRu.isNotEmpty) {
      return nameRu;
    }

    if (nameKz.isNotEmpty) {
      return nameKz;
    }

    return '';
  }
}
