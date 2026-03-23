import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';

/// Model for remote app version info
class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final String releasedAt;

  AppVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releasedAt,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] ?? '0.0.0',
      buildNumber: json['buildNumber'] ?? 1,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      releasedAt: json['releasedAt'] ?? '',
    );
  }
}

/// Compares two semantic version strings (e.g. "1.2.3" vs "1.3.0")
/// Returns true if remote is newer than local
bool _isNewerVersion(String remoteVersion, int remoteBuild, String localVersion, int localBuild) {
  final remoteParts = remoteVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final localParts = localVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  // Pad to 3 parts
  while (remoteParts.length < 3) remoteParts.add(0);
  while (localParts.length < 3) localParts.add(0);

  for (int i = 0; i < 3; i++) {
    if (remoteParts[i] > localParts[i]) return true;
    if (remoteParts[i] < localParts[i]) return false;
  }

  // Same version string — compare build number
  return remoteBuild > localBuild;
}

/// Provider that checks if an update is available
/// Returns AppVersionInfo if update available, null otherwise
final updateCheckProvider = FutureProvider<AppVersionInfo?>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiConstants.appVersion);

    if (response.data['success'] != true) return null;

    final remoteInfo = AppVersionInfo.fromJson(response.data['data']);
    final packageInfo = await PackageInfo.fromPlatform();

    final localVersion = packageInfo.version;
    final localBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

    if (_isNewerVersion(remoteInfo.version, remoteInfo.buildNumber, localVersion, localBuild)) {
      return remoteInfo;
    }

    return null;
  } catch (e) {
    // Silently fail — update check is non-critical
    return null;
  }
});

/// Downloads APK and triggers install
/// Returns a stream of download progress (0.0 to 1.0)
Future<void> downloadAndInstallUpdate(
  AppVersionInfo versionInfo, {
  required void Function(double progress) onProgress,
  required void Function(String error) onError,
  required void Function() onDownloadComplete,
}) async {
  try {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      onError('Could not access storage');
      return;
    }

    final filePath = '${dir.path}/app-update.apk';

    // Delete old APK if exists
    final oldFile = File(filePath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }

    // Download with progress
    final dio = Dio();
    await dio.download(
      versionInfo.downloadUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );

    onDownloadComplete();

    // Trigger APK install
    final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      onError('Could not open installer: ${result.message}');
    }
  } catch (e) {
    onError('Download failed: $e');
  }
}
