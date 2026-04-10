import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/drive_file.dart';

/// Cache service for Google Drive file listings
/// Uses SharedPreferences for persistent storage
class DriveFileCache {
  DriveFileCache(this._prefs);

  final SharedPreferences _prefs;

  static const String _filesKey = 'drive_files';
  static const String _timestampKey = 'drive_files_timestamp';
  static const Duration _maxAge = Duration(hours: 1);

  /// Create cache instance from SharedPreferences
  static Future<DriveFileCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DriveFileCache(prefs);
  }

  /// Get cached files if available and not expired
  Future<List<DriveFile>?> get() async {
    final timestampStr = _prefs.getString(_timestampKey);
    if (timestampStr == null) return null;

    final timestamp = DateTime.parse(timestampStr);
    final age = DateTime.now().difference(timestamp);

    if (age > _maxAge) {
      // Cache expired, clear it
      await clear();
      return null;
    }

    final filesJson = _prefs.getString(_filesKey);
    if (filesJson == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(filesJson) as List;
      return jsonList
          .map((json) => DriveFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Invalid cache data, clear it
      await clear();
      return null;
    }
  }

  /// Save files to cache
  Future<void> set(List<DriveFile> files) async {
    final filesJson = json.encode(files.map((f) => f.toJson()).toList());
    await _prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    await _prefs.setString(_filesKey, filesJson);
  }

  /// Clear cache
  Future<void> clear() async {
    await _prefs.remove(_timestampKey);
    await _prefs.remove(_filesKey);
  }

  /// Check if cache exists and is valid
  Future<bool> isValid() async {
    final timestampStr = _prefs.getString(_timestampKey);
    if (timestampStr == null) return false;

    final timestamp = DateTime.parse(timestampStr);
    final age = DateTime.now().difference(timestamp);
    return age <= _maxAge;
  }

  /// Get age of cached data
  Duration? get age {
    final timestampStr = _prefs.getString(_timestampKey);
    if (timestampStr == null) return null;

    final timestamp = DateTime.parse(timestampStr);
    return DateTime.now().difference(timestamp);
  }
}
