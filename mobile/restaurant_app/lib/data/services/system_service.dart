import 'package:flutter/foundation.dart';
import '../../core/constants/constants.dart';
import 'api_service.dart';

class SystemService {
  final ApiService _apiService = ApiService();

  /// Check for app updates
  Future<AppVersionInfo?> checkUpdate(String currentVersion, String platform) async {
    // In a real app, you would have an endpoint for this
    // For now, let's simulate a call
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/system/check-version',
        queryParams: {
          'version': currentVersion,
          'platform': platform,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        return AppVersionInfo.fromJson(response.data!);
      }
    } catch (e) {
      if (kDebugMode) print('Error checking update: $e');
    }
    return null;
  }
}

class AppVersionInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String? updateUrl;
  final String? releaseNotesAr;
  final String? releaseNotesEn;

  AppVersionInfo({
    required this.latestVersion,
    required this.forceUpdate,
    this.updateUrl,
    this.releaseNotesAr,
    this.releaseNotesEn,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latestVersion'] ?? '1.0.0',
      forceUpdate: json['forceUpdate'] ?? false,
      updateUrl: json['updateUrl'],
      releaseNotesAr: json['releaseNotesAr'],
      releaseNotesEn: json['releaseNotesEn'],
    );
  }

  String getReleaseNotes(bool isArabic) => 
      isArabic ? (releaseNotesAr ?? '') : (releaseNotesEn ?? '');
}
