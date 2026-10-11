import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_FirebaseStartupErrorApp(error: error.toString()));
    return;
  }

  //

  //

  /// A Google Sign-In setup issue should not stop the rest of the app from
  /// rendering. The sign-in screen will surface any error when Google is used.
  try {
    await GoogleSignIn.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Google Sign-In initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const TaskManagerApp());
  unawaited(_initializeNotificationsSafely());
}

Future<void> _initializeNotificationsSafely() async {
  try {
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class _FirebaseStartupErrorApp extends StatelessWidget {
  const _FirebaseStartupErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Setup Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BEA)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Color(0xFF5B5BEA),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Firebase could not start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Check the Firebase configuration and the terminal '
                      'error below. The app has not opened because Firebase '
                      'initialization failed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E5F0)),
                      ),
                      child: SelectableText(
                        error,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
