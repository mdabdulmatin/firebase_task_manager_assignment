# Firebase setup — Android

## Existing configuration

The project already contains an Android `google-services.json` for Firebase project `fir-assignment-6bb31` and an Android `FirebaseOptions` configuration in `lib/firebase_options.dart`. For the Android assignment target, you do not need to replace these files unless you switch Firebase projects.

The Android application ID is `com.example.firebase_assignment`. Keep it the same as the registered Firebase Android app.

## Authentication

Firebase Console → Authentication → Sign-in method:

- Enable Email/Password.
- Enable Google.
- Add the Android debug SHA-1 from `cd android` then `gradlew signingReport` (or `.\gradlew signingReport` in PowerShell) under Project settings → Your apps → Android app → SHA certificate fingerprints.

The included `google-services.json` contains a web OAuth client entry used by the Android Google Sign-In integration. If Google Sign-In reports a configuration error, re-download `google-services.json` from the same Firebase Android app after checking package ID and SHA-1.

## Cloud Firestore

Create Firestore Database if it does not already exist, then publish the rules in `firestore.rules`. The app's data path is:

```text
users/{uid}
  tasks/{taskId}
```

Each task stores `title`, `description`, `dueDate`, `priority`, `completed`, `createdAt`, and `userId`. The Edit Task design also stores an optional `courseBucket` (for example, `CS 421`). Publish the updated `firestore.rules` file from this project because earlier strict rules may reject that field.

## Cloud Messaging

The app requests notification permission and logs the FCM token in the debug console. On Android 13+, allow the runtime notification prompt.

For a test notification, use Firebase Console → Messaging and send a notification to the device's token. You can add custom data such as:

- `type`: `task`
- `taskId`: the Firestore task document ID

Foreground notifications are displayed through `flutter_local_notifications`. Background notifications with a notification payload are displayed by Android/Firebase; tapping a notification is handled by the app.

## Adding other platforms

The included Firebase options are configured for Android only. If you add iOS, web, macOS, Windows, or Linux support, run `flutterfire configure` and generate configuration for each platform you intend to run.

Do not add a Firebase service-account JSON/private key to a Flutter client app.
