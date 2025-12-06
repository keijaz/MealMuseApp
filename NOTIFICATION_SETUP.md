# Notification Setup Instructions

## Dependencies Installed

The following packages have been added to `pubspec.yaml`:
- `firebase_messaging: ^14.7.9` - For Firebase Cloud Messaging
- `flutter_local_notifications: ^16.3.0` - For local notifications
- `timezone: ^0.9.2` - For timezone support

## Installation Steps

### 1. Install Dependencies

Run the following command to install the new packages:

```bash
flutter pub get
```

### 2. Android Configuration

#### Update `android/app/build.gradle`

Make sure your `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        // ... other config
    }
}
```

#### Add permissions to `android/app/src/main/AndroidManifest.xml`

Add these permissions inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

Add this inside the `<application>` tag:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### 3. iOS Configuration

#### Update `ios/Runner/Info.plist`

Add these keys to enable notifications:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### Enable Push Notifications capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and enable "Remote notifications"

### 4. Firebase Configuration

Make sure you have already configured Firebase for your project with:
- `google-services.json` in `android/app/`
- `GoogleService-Info.plist` in `ios/Runner/`

If not configured yet, follow the Firebase setup guide:
https://firebase.google.com/docs/flutter/setup

## How It Works

### User Flow

1. User goes to Settings screen
2. Toggles the Notifications switch to ON
3. A popup appears asking "How many days before item expiry would you like us to send you a notification?"
4. User can use +/- buttons or type a number (minimum 1 day)
5. User clicks "Done"
6. The preference is saved to both SharedPreferences and Firestore
7. The app checks inventory items daily and sends notifications when items match the expiry threshold

### Notification Trigger

When an item in the user's inventory has exactly the number of days until expiry that matches the user's preference, a notification is sent with:
- **Title**: "Item Expiring Soon!"
- **Body**: "Your [item name] is expiring in [X] days."
- **Action**: Tapping the notification navigates to the Expiring Items screen

### Technical Implementation

- **NotificationService**: Singleton service managing all notification logic
- **SharedPreferences**: Stores user's notification preferences locally
- **Firestore**: Syncs notification preferences to cloud
- **Daily Check**: App checks expiring items when opened (can be extended with background tasks)
- **Local Notifications**: Uses flutter_local_notifications for cross-platform notification display

## Testing

### Test the notifications:

1. Enable notifications in Settings and set to 3 days
2. Add an item to inventory with an expiry date 3 days from today
3. The notification should appear immediately (for testing)
4. Tap the notification - it should navigate to the Expiring screen

### Debug mode:

Check the console for debug messages:
- `'User granted permission'` - Notification permission granted
- `'Error checking expiring items: ...'` - If there's an error in checking

## Extending Functionality

### For production, you may want to add:

1. **Background Task Runner**: Use `workmanager` package to check expiring items even when app is closed
2. **Time-specific notifications**: Schedule notifications at a specific time (e.g., 9 AM daily)
3. **Multiple notification thresholds**: Allow users to set multiple day thresholds
4. **Notification customization**: Let users customize notification sound, vibration pattern
5. **Rich notifications**: Add action buttons like "View" and "Dismiss"

## Troubleshooting

### Notifications not appearing:

1. Check app permissions in device settings
2. Verify Firebase is properly configured
3. Check if notification preferences are saved (debug SharedPreferences)
4. Ensure items have valid expiry dates in Firestore

### iOS specific issues:

- Make sure you're testing on a real device (not simulator)
- Verify Push Notifications capability is enabled in Xcode
- Check that APNs certificates are configured in Firebase Console

### Android specific issues:

- Check that minSdkVersion is at least 21
- Verify all permissions are added to AndroidManifest.xml
- For Android 13+, ensure POST_NOTIFICATIONS permission is granted

## Files Modified/Created

### New Files:
- `lib/services/notification_service.dart` - Core notification service

### Modified Files:
- `pubspec.yaml` - Added notification dependencies
- `lib/main.dart` - Initialize notification service and add routing
- `lib/screens/settings.dart` - Added notification dialog and toggle logic

### Configuration Files to Update:
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle`
- `ios/Runner/Info.plist`
- Xcode capabilities (manual in Xcode)
