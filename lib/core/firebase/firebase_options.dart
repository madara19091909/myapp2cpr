import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDXuoHyNdFmCQSZQolaxDKUfovJ3KuOLOc',
  );
  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:85946596713:android:b7f07660019553453991f8',
  );
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '85946596713',
  );
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'myapp2-62246',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'myapp2-62246.firebasestorage.app',
  );

  static bool get isConfigured =>
      [apiKey, appId, messagingSenderId, projectId].every((v) => v.isNotEmpty && !v.startsWith('PUT_'));

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      );
}