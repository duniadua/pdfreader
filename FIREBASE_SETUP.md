# Firebase Setup Instructions

## Project Details
- **Firebase Project ID**: `pdfreader-8405a`
- **Android Package Name**: `com.pdfreader.pdf_reader_app`
- **iOS Bundle ID**: `com.pdfreader.pdfReaderApp`

## Step 1: Download Config Files from Firebase Console

### Android Config (google-services.json)
1. Go to: https://console.firebase.google.com/project/pdfreader-8405a/settings/general
2. Click "Add app" → Android icon
3. Enter package name: `com.pdfreader.pdf_reader_app`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### iOS Config (GoogleService-Info.plist)
1. In the same Firebase Console page
2. Click "Add app" → iOS icon
3. Enter bundle ID: `com.pdfreader.pdfReaderApp`
4. Download `GoogleService-Info.plist`
5. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 2: iOS Podfile (if needed)

If you haven't already, you may need to add Firebase to your iOS project. The simplest way is using the FlutterFire CLI:

```bash
flutterfire configure --project=pdfreader-8405a
```

This will:
- Create the Firebase apps in your project
- Download the config files
- Update your Podfile automatically

## Step 3: Install Pods (iOS only)

After adding the config files, run:

```bash
cd ios
pod install
cd ..
```

## Step 4: Test the Setup

Run the app to verify Firebase is initialized:

```bash
flutter run
```

Check the logs for "Firebase initialized" message.

## Firebase Features Available

The following Firebase services are ready to use:

- ✅ Firebase Core (installed)
- ❌ Authentication (add with: `flutter pub add firebase_auth`)
- ❌ Cloud Firestore (add with: `flutter pub add cloud_firestore`)
- ❌ Firebase Storage (add with: `flutter pub add firebase_storage`)
- ❌ Firebase Analytics (add with: `flutter pub add firebase_analytics`)
- ❌ Firebase Crashlytics (add with: `flutter pub add firebase_crashlytics`)
