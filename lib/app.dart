import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/game/state/game_state.dart';
import 'features/home/home_screen.dart';

class FarmApp extends StatelessWidget {
  const FarmApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزرعتي',
      theme: AppTheme.theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: firebaseReady ? const AuthGate() : const OfflineGameLoader(),
    );
  }
}


/// يفتح اللعبة مباشرةً بحفظ محلي عندما لا تكون إعدادات Firebase متوفرة.
class OfflineGameLoader extends StatefulWidget {
  const OfflineGameLoader({super.key});

  @override
  State<OfflineGameLoader> createState() => _OfflineGameLoaderState();
}

class _OfflineGameLoaderState extends State<OfflineGameLoader> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = context.read<GameState>().loadLocal();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
          ? const HomeScreen(firebaseReady: false)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
