# Firebase Remote Config Setup Guide

This guide will help you set up Firebase Remote Config to manage Qiscus App ID and Channel IDs dynamically.

## Prerequisites

1. A Firebase project
2. Flutter CLI installed
3. Firebase CLI installed

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name (e.g., `multichannel-flutter-sample`)
4. Enable Google Analytics (optional)
5. Create the project

## Step 2: Add Flutter App to Firebase

### For Android:
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.multichannel_flutter_sample`
3. Enter app nickname: `Multichannel Flutter Sample`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### For iOS:
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.multichannelFlutterSample`
3. Enter app nickname: `Multichannel Flutter Sample`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`

## Step 3: Configure Firebase Remote Config

1. In Firebase Console, go to "Remote Config"
2. Click "Create configuration"
3. Add the following parameters:

### Parameter 1: qiscus_app_id
- **Parameter key**: `qiscus_app_id`
- **Default value**: `YOUR_QISCUS_APP_ID`
- **Description**: Qiscus Multichannel App ID

### Parameter 2: konsultasi_channel_id
- **Parameter key**: `konsultasi_channel_id`
- **Default value**: `YOUR_KONSULTASI_CHANNEL_ID`
- **Description**: Channel ID for Konsultasi (General Consultation)

### Parameter 3: bantuan_channel_id
- **Parameter key**: `bantuan_channel_id`
- **Default value**: `YOUR_BANTUAN_CHANNEL_ID`
- **Description**: Channel ID for Bantuan (Technical Support)

4. Click "Publish changes"

## Step 4: Generate Firebase Options

Run the following command in your project root:

```bash
flutterfire configure
```

This will:
- Generate `lib/firebase_options.dart`
- Update platform-specific configuration files
- Replace the placeholder Firebase options with your actual project configuration

## Step 5: Update Remote Config Values

1. Go to Firebase Console → Remote Config
2. Update the parameter values with your actual Qiscus configuration:
   - `qiscus_app_id`: Your actual Qiscus App ID
   - `konsultasi_channel_id`: Your actual Konsultasi channel ID
   - `bantuan_channel_id`: Your actual Bantuan channel ID
3. Click "Publish changes"

## Step 6: Test the Integration

1. Run the app: `flutter run`
2. The app will:
   - Initialize Firebase
   - Fetch Remote Config values
   - Display channels with remote configuration
   - Show "Konfigurasi dari Firebase Remote Config" indicator when using remote values

## Remote Config Features

### Automatic Fallback
- If Firebase Remote Config fails to load, the app uses default values from `AppConfig`
- Graceful error handling ensures the app always works

### Real-time Updates
- Remote Config values are fetched on app start
- Minimum fetch interval: 1 hour (configurable)
- Fetch timeout: 1 minute

### Debug Information
- All Remote Config operations are logged
- Current values are displayed in debug logs
- Loading states are shown to users

## Troubleshooting

### Common Issues:

1. **Firebase not initialized**
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
   - Run `flutterfire configure` to regenerate configuration

2. **Remote Config not fetching**
   - Check internet connection
   - Verify Firebase project configuration
   - Check console logs for error messages

3. **Default values used instead of remote**
   - Remote Config has caching mechanism
   - Wait for minimum fetch interval or clear app data
   - Check if parameters exist in Firebase Console

### Debug Commands:

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run with verbose logging
flutter run --verbose

# Check Firebase configuration
flutterfire configure --info
```

## Production Considerations

1. **Security**: Remote Config values are public - don't store sensitive data
2. **Caching**: Consider appropriate fetch intervals for your use case
3. **Fallbacks**: Always provide default values for critical configuration
4. **Testing**: Test both online and offline scenarios

## Example Remote Config Values

```json
{
  "qiscus_app_id": "your-actual-qiscus-app-id",
  "konsultasi_channel_id": "12345",
  "bantuan_channel_id": "67890"
}
```

The app will automatically use these values once published in Firebase Remote Config.
