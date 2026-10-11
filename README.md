# Firebase Task Manager — Flutter Assignment

A Flutter Task Manager assignment app using Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging (FCM), and foreground local notifications.

## Implemented features

- Email/password sign up, sign in, and password reset
- Google Sign-In
- Firestore task CRUD scoped to the signed-in user's `users/{uid}/tasks/{taskId}` path
- Task completion, priority, due date, created date, course bucket, search, and All/Pending/Completed filters
- Delete confirmation dialog
- FCM token logging and token-refresh handling
- Foreground FCM messages displayed through `flutter_local_notifications`
- Background notification display handled by Firebase/Android
- Notification tap handling for background and terminated states
- Optional `taskId` routing to a task detail screen
- Graceful Firebase startup error screen; notification setup no longer blocks the first app frame

## Firebase configuration

The project includes `android/app/google-services.json` and an Android `DefaultFirebaseOptions` configuration in `lib/firebase_options.dart`. Both refer to the Android Firebase app registered for package `com.example.firebase_assignment` in project `fir-assignment-6bb31`.

If you change Firebase projects or add platforms (iOS, web, desktop), run `flutterfire configure` from the project root and use the generated platform configuration. Do not put a Firebase service-account private key in a client app.

## Run on Android

From the project root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

If `android/local.properties` is missing, Flutter tooling should regenerate the local SDK paths on your computer. Ensure the Android SDK and a compatible Flutter SDK are installed.

## FCM assignment test

1. Install and open the app, then sign in.
2. Copy the FCM token printed in the debug console.
3. In Firebase Console, send a test message to that device token.
4. For exact task routing, include custom data `taskId` with the Firestore task document ID.
5. Test foreground, background, and terminated notification-tap flows separately.

## Verification note

The source was reviewed and updated in this environment, but Flutter/Android SDK tooling was not available here to execute a real Android build or device test. Run the commands above on the development computer; use any resulting build/runtime log to finish device-specific verification.
