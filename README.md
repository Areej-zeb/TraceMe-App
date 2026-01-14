# TraceMe - Cross-Platform Lost Phone Tracker

TraceMe is a powerful, lightweight Flutter application designed for on-demand device tracking. Unlike other apps, it doesn't track you continuously. Tracking only activates when you mark a device as **LOST**.

## 🚀 Features

- **Live Location Tracking**: View the real-time location of your lost device on a map.
- **Remote Ringing**: Trigger a loud alarm on your lost device even if it's in the background.
- **Lost Mode**: Remotely activate location broadcasting to save battery until needed.
- **Free Tier Compatible**: Uses Firestore listeners instead of paid FCM limits, making it perfect for personal use on the Firebase Spark (Free) Plan.

## 🛠️ Setup Instructions

### 1. Firebase Configuration
TraceMe requires a Firebase project to function.
1.  **Create a Firebase Project** at [console.firebase.google.com](https://console.firebase.google.com/).
2.  **Enable Authentication**: Use Email/Password provider.
3.  **Enable Firestore**:
    - Start in "Test Mode".
    - Deploy the rules provided in `firestore.rules` using:
      ```bash
      firebase deploy --only firestore:rules
      ```
4.  **Register Apps**:
    - Add an **Android App** (use package name `com.traceme.traceme`).
    - Download `google-services.json` and place it in `android/app/`.

### 2. Google Maps Setup
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  Enable the **Maps SDK for Android**.
3.  Create an **API Key**.
4.  Open `android/app/src/main/AndroidManifest.xml` and replace the placeholder with your key:
    ```xml
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_REAL_API_KEY_HERE" />
    ```

### 3. Run the App
```bash
flutter pub get
flutter run
```

## 🏗️ Architecture

TraceMe uses a **Feature-first** modular architecture with **Riverpod** for state management:
- `lib/features/auth`: User session and login logic.
- `lib/features/devices`: Device pairing and control panel.
- `lib/features/map_tracking`: Real-time map visualization.
- `lib/services`: Low-level services for Firebase, Audio, and Background Tracking.

## 🔒 Security
- **Security Rules**: Only the device owner can read/write location data and commands.
- **Zero Secrets**: No API keys or service accounts should be committed to version control. Reference the `.gitignore` for protected files.

---
Built with ❤️ by the TraceMe Team.
