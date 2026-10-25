import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/firebase/firebase_options.dart';
import 'features/game/state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      firebaseReady = true;
    } catch (_) {
      firebaseReady = false;
    }
  }

  runApp(
    ChangeNotifierProvider<GameState>(
      create: (_) => GameState(),
      child: FarmApp(firebaseReady: firebaseReady),
    ),
  );
}
