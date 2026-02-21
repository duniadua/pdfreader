# Security Guidelines

This file contains security best practices for the Flutter PDF reader app.

---

## Core Security Principles

1. **Local-only design** - No backend API means no server vulnerabilities
2. **Data protection** - Secure local storage and file handling
3. **Input validation** - Validate all user inputs and file data
4. **Least privilege** - Request only necessary permissions

---

## Permissions

### Request permissions minimally

```yaml
# android/app/src/main/AndroidManifest.xml
<manifest>
    <!-- ✅ GOOD - only necessary permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <!-- ❌ BAD - don't request unused permissions -->
    <!-- <uses-permission android:name="android.permission.INTERNET"/> -->
    <!-- <uses-permission android:name="android.permission.CAMERA"/> -->
</manifest>
```

### Request permissions at runtime

```dart
// ✅ GOOD - request when needed
Future<bool> _requestStoragePermission() async {
  final status = await Permission.storage.request();
  return status.isGranted;
}

// Usage
if (await _requestStoragePermission()) {
  // Proceed with file operation
} else {
  // Show permission denied message
}
```

### Handle permission denial

```dart
// ✅ GOOD - handle denied/permanently denied
if (await status.isDenied) {
  // Show explanation
  _showPermissionRationale();
} else if (await status.isPermanentlyDenied) {
  // Redirect to app settings
  await openAppSettings();
}
```

---

## File Security

### Validate file types

```dart
// ✅ GOOD - validate PDF files
bool isValidPdfFile(String path) {
  // Check extension
  if (!path.toLowerCase().endsWith('.pdf')) {
    return false;
  }

  // Check file signature (magic number)
  final file = File(path);
  final header = file.openSync(0, 4).readSync(4);
  const pdfMagic = [0x25, 0x50, 0x44, 0x46]; // %PDF
  return header[0] == pdfMagic[0] &&
         header[1] == pdfMagic[1] &&
         header[2] == pdfMagic[2] &&
         header[3] == pdfMagic[3];
}

// Usage
if (!isValidPdfFile(filePath)) {
  throw InvalidFileTypeException('Only PDF files are supported');
}
```

### Sanitize file names

```dart
// ✅ GOOD - sanitize user input
String sanitizeFileName(String name) {
  // Remove path traversal characters
  final sanitized = name
      .replaceAll('..', '')
      .replaceAll('/', '')
      .replaceAll('\\', '')
      .replaceAll('\0', '');

  // Limit length
  if (sanitized.length > 255) {
    return sanitized.substring(0, 255);
  }

  return sanitized.isEmpty ? 'unnamed' : sanitized;
}
```

### Limit file sizes

```dart
// ✅ GOOD - enforce size limits
const maxFileSize = 100 * 1024 * 1024; // 100MB

Future<File?> importPdf(String sourcePath) async {
  final file = File(sourcePath);
  final size = await file.length();

  if (size > maxFileSize) {
    throw FileTooLargeException('PDF files must be under 100MB');
  }

  // Proceed with import
}
```

---

## Data Storage Security

### Use secure storage for sensitive data

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

```dart
// ✅ GOOD - secure storage for sensitive data
final secureStorage = const FlutterSecureStorage();

// Save API keys or tokens (if ever needed)
await secureStorage.write(key: 'user_token', value: token);

// Clear on logout
await secureStorage.delete(key: 'user_token');
```

### Hive encryption for sensitive data

```dart
// ✅ GOOD - encrypt Hive boxes
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';

// Generate encryption key
final key = Hive.generateSecureKey();

// Open encrypted box
final box = await Hive.openBox(
  'secureData',
  encryptionCipher: HiveAesCipher(key),
);

// ⚠️ CAUTION - Never hardcode keys!
// Store encryption key in secure storage
```

### Don't store sensitive data in plain text

```dart
// ❌ BAD - plain text preferences
await prefs.setString('password', password);

// ✅ GOOD - don't store passwords, use tokens
await secureStorage.write(key: 'auth_token', value: token);
```

---

## Input Validation

### Validate all user inputs

```dart
// ✅ GOOD - validate text input
class SearchInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(labelText: 'Search'),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F]')), // Control chars
        LengthLimitingTextInputFormatter(100), // Max length
      ],
    );
  }
}

// Validate in notifier
void search(String query) {
  if (query.isEmpty) {
    // Handle empty
    return;
  }

  // Sanitize query
  final sanitized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
  _performSearch(sanitized);
}
```

### Validate file paths

```dart
// ✅ GOOD - validate paths
bool isValidPath(String path) {
  try {
    final file = File(path);
    final resolved = file.resolveSymbolicLinksSync();

    // Ensure path is within allowed directory
    final allowedDir = '/data/user/0/com.app.app/files/';
    return resolved.startsWith(allowedDir);
  } catch (e) {
    return false;
  }
}
```

---

## Error Handling

### Don't expose sensitive information in errors

```dart
// ❌ BAD - exposes file system structure
catch (e) {
  showError('Error accessing /data/user/0/com.app.app/files/pdf/$id');
}

// ✅ GOOD - generic error message
catch (e) {
  AppLogger.e('Failed to load PDF', e, stackTrace);
  showError('Unable to open PDF file');
}
```

### Use structured logging

```dart
// ✅ GOOD - structured logging without sensitive data
AppLogger.e(
  'PDF load failed',
  error,
  stackTrace,
  // Don't log file paths, user data, etc.
);

// For debugging (only in debug mode)
if (kDebugMode) {
  print('Debug: Failed to load PDF at $sanitizedPath');
}
```

---

## Network Security (if network is ever added)

### Certificate pinning (for future API calls)

```dart
// ✅ GOOD - certificate pinning for API calls
import 'package:http/io_client.dart';

SecurityContext getSecureContext() {
  final context = SecurityContext(withTrustedRoots: false);
  // Load pinned certificate
  context.setTrustedCertificatesBytes(pinnedCertBytes);
  return context;
}

final client = IOClient(HttpClient(context: getSecureContext()));
```

### Don't allow insecure HTTP

```dart
// ❌ BAD - allows insecure connections
// <application android:usesCleartextTraffic="true">

// ✅ GOOD - HTTPS only
// Android manifest - default is secure
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

```xml
<!-- res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

---

## Code Security

### Don't hardcode secrets

```dart
// ❌ BAD - hardcoded secrets
const apiKey = 'sk-1234567890abcdef';
const dbPassword = 'password123';

// ✅ GOOD - use environment variables or secure storage
final apiKey = const String.fromEnvironment('API_KEY');

// Or fetch from secure storage
final apiKey = await secureStorage.read(key: 'api_key');
```

### Obfuscate release builds

```bash
# Obfuscate release builds
flutter build apk --obfuscate --split-debug-info=./symbols/

# Use split-debug-info to deobfuscate crash logs
```

### Disable debug mode in production

```dart
// ✅ GOOD - check debug mode
if (kDebugMode) {
  // Debug-only code
  print('Debug info');
}

// ✅ GOOD - use logger that respects build mode
AppLogger.d('This only logs in debug mode');
```

---

## Third-Party Security

### Audit dependencies

```bash
# Check for vulnerabilities
flutter pub deps

# Check outdated packages
flutter pub outdated

# Run security audit (if available)
dart pub publish --dry-run
```

### Pin dependency versions

```yaml
# pubspec.yaml
dependencies:
  # ✅ GOOD - pinned versions
  syncfusion_flutter_pdfviewer: ^27.1.51

  # ❌ BAD - unspecified version
  some_package: any
```

### Review permissions of dependencies

```bash
# Check Android manifest merge
./gradlew :app:processDebugManifest

# Review merged permissions in build output
```

---

## WebView Security (if ever added)

```dart
// ✅ GOOD - secure WebView configuration
WebViewWidget(
  controller: WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled) // Disable JS if not needed
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          // Only allow specific URLs
          if (!url.startsWith('https://trusted-domain.com')) {
            // Block navigation
          }
        },
      ),
    ),
)
```

---

## Security Checklist

Before releasing:

- [ ] All permissions are necessary and justified
- [ ] File uploads validate type and size
- [ ] User input is sanitized and validated
- [ ] Paths are validated (no traversal)
- [ ] Error messages don't expose sensitive info
- [ ] No hardcoded secrets in code
- [ ] Debug features disabled in production
- [ ] Logging doesn't include sensitive data
- [ ] Dependencies are audited and updated
- [ ] Release builds are obfuscated
- [ ] Secure storage used for sensitive data
- [ ] Certificate pinning if using network

---

## Security Testing

### Test file security

```dart
testWidgets('should reject invalid PDF files', (tester) async {
  // Test with non-PDF file
  final result = await pdfValidator.validate('fake.pdf');
  expect(result.isValid, false);
});

testWidgets('should sanitize file names', (tester) async {
  final sanitized = sanitizeFileName('../../../etc/passwd');
  expect(sanitized, isNot(contains('..')));
  expect(sanitized, isNot(contains('/')));
});
```

### Test permission handling

```dart
test('should handle permission denied', () async {
  when(mockPermission.request()).thenAnswer((_) async => false);

  await expectLater(
    () => repository.importPdf('/path/to/file.pdf'),
    throwsA(isA<PermissionDeniedException>()),
  );
});
```

---

## Security Incident Response

If a security issue is discovered:

1. **Don't commit to public repo** - Report privately first
2. **Assess impact** - Determine user data exposure
3. **Create fix** - Develop and test patch
4. **Release update** - Deploy fix to users
5. **Disclose** - Inform users if data was affected

---

## Security Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security/overview)
- [Android Security Guidelines](https://developer.android.com/topic/security/best-practices)
- [iOS Security Guidelines](https://developer.apple.com/documentation/security)
