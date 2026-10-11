# Testing checklist

## Build and static checks

From the project root, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

This environment did not have Flutter/Android SDK tooling, so a real build and device test could not be executed here.

## Startup

- Confirm the app shows the sign-in UI (not a blank screen).
- If Firebase initialization fails, confirm an on-screen configuration error appears rather than an empty launch screen.

## Authentication

- Create an account using Email/Password.
- Sign out and sign back in.
- Try an invalid password.
- Send a password reset email.
- Sign in with Google and verify that the Android SHA-1 is registered.
- Verify the app switches between login and task list when auth state changes.

## Firestore task features

- Create a task and verify it under `users/{uid}/tasks/{taskId}`.
- Edit title, description, priority, due date, course bucket, and completion state.
- Mark a task completed and pending.
- Confirm All/Pending/Completed filters and priority filtering.
- Search by title or description.
- Delete a task after the custom confirmation dialog.
- Close/reopen the app and verify saved tasks remain.
- Verify another signed-in user cannot read the current user's tasks.

## UI review

- Compare Splash, Login, Task List, Add Task, Edit Task, and Delete Confirmation with the supplied reference screenshots.
- Check short and long task titles/descriptions, keyboard visibility, date selection, and scrolling on a 390 × 848 dp device.

## FCM and local notifications

- Accept notification permission on Android 13+.
- Copy the FCM token printed in the debug console.
- Send a Firebase test notification while the app is in the background.
- Send a notification while the app is open and confirm a local notification appears.
- Add `taskId` as custom data and tap the notification to open that task.
- Test terminated-state notification interaction separately; manual force-stop behavior may be restricted by Android.
