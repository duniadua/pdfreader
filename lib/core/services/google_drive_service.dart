import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Google Drive service for file operations using existing Google Sign-In.
///
/// This service uses the access token from the existing Google Sign-In flow.
/// No separate authentication is required.
class GoogleDriveService {
  GoogleDriveService._();

  static final GoogleDriveService instance = GoogleDriveService._();

  // OAuth scopes - read-only access
  static const List<String> scopes = <String>[
    drive.DriveApi.driveReadonlyScope,
  ];

  // Storage keys
  static const String _accessTokenKey = 'google_drive_access_token';

  String? _accessToken;
  DateTime? _tokenExpiry;
  drive.DriveApi? _driveApi;
  String? _currentUserEmail;

  /// Check if user is signed in (has valid access token)
  bool get isSignedIn => _accessToken != null && _driveApi != null;

  /// Get the current authenticated user's email
  String? get currentUserEmail => _currentUserEmail;

  /// Get the Drive API instance
  drive.DriveApi? get driveApi => _driveApi;

  Completer<void>? _initCompleter;

  /// Initialize the service with an access token from Google Sign-In
  Future<void> initialize({String? accessToken}) async {
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    if (accessToken != null) {
      await _setAccessToken(accessToken);
      await _fetchUserInfo();
      AppLogger.i('Google Drive initialized with existing sign-in');
    }

    _initCompleter!.complete();
    _initCompleter = null;
  }

  /// Set the access token from Google Sign-In
  Future<void> _setAccessToken(String token) async {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);

    // Create Drive API with authenticated client
    _createDriveApiClient();
  }

  /// Create the Drive API client with current access token
  void _createDriveApiClient() {
    if (_accessToken == null) return;

    // Create a simple HTTP client that adds the Bearer token
    final client = _AuthenticatedClient(
      accessToken: _accessToken!,
      baseClient: http.Client(),
    );

    _driveApi = drive.DriveApi(client);
  }

  /// Refresh the access token by getting a fresh one from existing sign-in
  Future<bool> refreshToken(String newAccessToken) async {
    try {
      await _setAccessToken(newAccessToken);
      AppLogger.i('Google Drive access token refreshed');
      return true;
    } catch (e) {
      AppLogger.e('Failed to refresh Drive token', e);
      return false;
    }
  }

  /// Check if the current token is expired
  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Fetch user information to get email
  Future<void> _fetchUserInfo() async {
    try {
      if (_driveApi == null) return;

      final about = await _driveApi!.about.get(
        $fields: 'user(emailAddress,displayName)',
      );

      _currentUserEmail = about.user?.emailAddress;
      AppLogger.i('Google Drive user: $_currentUserEmail');
    } catch (e) {
      AppLogger.w('Could not fetch user info: $e');
    }
  }

  /// List all PDF files from Google Drive
  Future<List<DriveFile>> listPdfs() async {
    if (_driveApi == null || isTokenExpired) {
      AppLogger.w('Drive API not initialized or token expired');
      return [];
    }

    try {
      AppLogger.i('Fetching PDF files from Google Drive...');

      final response = await _driveApi!.files.list(
        q: "mimeType='application/pdf'",
        $fields: 'files(id,name,size,createdTime,thumbnailLink,webViewLink)',
        pageSize: 100,
      );

      final files = response.files ?? [];
      AppLogger.i('Found ${files.length} PDF files in Drive');

      return files.map((file) => DriveFile(
        id: file.id ?? '',
        name: file.name ?? 'Unknown',
        size: int.tryParse(file.size ?? '0') ?? 0,
        createdTime: file.createdTime ?? DateTime.now(),
        thumbnailLink: file.thumbnailLink,
        webViewLink: file.webViewLink,
      )).toList();
    } catch (e, st) {
      AppLogger.e('Failed to list Drive files', e, st);
      return [];
    }
  }

  /// Download a PDF file from Google Drive
  ///
  /// Returns the local path where the file was saved, or null if failed.
  Future<String?> downloadPdf(String fileId, String fileName) async {
    if (_driveApi == null || isTokenExpired) {
      AppLogger.w('Drive API not initialized or token expired');
      return null;
    }

    try {
      AppLogger.i('Downloading PDF from Drive: $fileName');

      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Download file media
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      // Write the downloaded bytes to file
      final file = File(filePath);
      final sink = file.openWrite();

      if (media is drive.Media) {
        await media.stream.pipe(sink);
      }

      await sink.close();

      AppLogger.i('PDF downloaded to: $filePath');
      return filePath;
    } catch (e, st) {
      AppLogger.e('Failed to download PDF from Drive', e, st);
      return null;
    }
  }

  /// Get file content as bytes (for sharing or direct viewing)
  Future<Uint8List?> downloadPdfBytes(String fileId) async {
    if (_driveApi == null || isTokenExpired) {
      AppLogger.w('Drive API not initialized or token expired');
      return null;
    }

    try {
      AppLogger.i('Downloading PDF bytes from Drive: $fileId');

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (media is drive.Media) {
        final bytes = await media.stream.toList();
        final flatBytes = Uint8List.fromList(bytes.expand((e) => e).toList());
        AppLogger.i('Downloaded ${flatBytes.length} bytes');
        return flatBytes;
      }

      return null;
    } catch (e, st) {
      AppLogger.e('Failed to download PDF bytes', e, st);
      return null;
    }
  }

  /// Sign out and clear credentials
  Future<void> signOut() async {
    _accessToken = null;
    _tokenExpiry = null;
    _driveApi = null;
    _currentUserEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);

    AppLogger.i('Signed out from Google Drive');
  }

  /// Get current access token
  String? getAccessToken() => _accessToken;
}

/// Simple HTTP client that adds Bearer authentication
class _AuthenticatedClient extends http.BaseClient {
  final String accessToken;
  final http.Client baseClient;

  _AuthenticatedClient({
    required this.accessToken,
    required this.baseClient,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add Authorization header
    request.headers['Authorization'] = 'Bearer $accessToken';
    return baseClient.send(request);
  }

  @override
  void close() {
    baseClient.close();
  }
}

/// Simple representation of a Google Drive file
class DriveFile {
  final String id;
  final String name;
  final int size;
  final DateTime createdTime;
  final String? thumbnailLink;
  final String? webViewLink;

  const DriveFile({
    required this.id,
    required this.name,
    required this.size,
    required this.createdTime,
    this.thumbnailLink,
    this.webViewLink,
  });

  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file has a valid PDF extension or name
  bool get isPdf {
    return name.toLowerCase().endsWith('.pdf') ||
        name.toLowerCase().contains('.pdf');
  }

  /// Get display name (without .pdf extension if present)
  String get displayName {
    if (name.toLowerCase().endsWith('.pdf')) {
      return name.substring(0, name.length - 4);
    }
    return name;
  }

  DriveFile copyWith({
    String? id,
    String? name,
    int? size,
    DateTime? createdTime,
    String? thumbnailLink,
    String? webViewLink,
  }) {
    return DriveFile(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      createdTime: createdTime ?? this.createdTime,
      thumbnailLink: thumbnailLink ?? this.thumbnailLink,
      webViewLink: webViewLink ?? this.webViewLink,
    );
  }

  @override
  String toString() {
    return 'DriveFile(id: $id, name: $name, size: $formattedSize)';
  }
}
