import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/audio/audio_manager.dart';
import 'features/game/state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>(create: (_) => GameState()),
        ChangeNotifierProvider<AudioManager>(create: (_) => AudioManager()..initialize()),
      ],
      child: const FarmApp(),
    ),
  );
}
