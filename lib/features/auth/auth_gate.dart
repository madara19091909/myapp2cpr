import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../game/state/game_state.dart';
import '../home/home_screen.dart';
import 'screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const FarmSplash();
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _GameLoader(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _GameLoader extends StatefulWidget {
  const _GameLoader({super.key, required this.user});

  final User user;

  @override
  State<_GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<_GameLoader> {
  late final Future<void> _future;
  String? _name;

  @override
  void initState() {
    super.initState();
    _name = widget.user.displayName;
    _future = context.read<GameState>().loadForUser(widget.user.uid);
  }

  @override
  void didUpdateWidget(covariant _GameLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final n = widget.user.displayName;
    if (n != null && n.isNotEmpty && n != _name) {
      _name = n;
      context.read<GameState>().setPlayerName(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) =>
          snap.connectionState == ConnectionState.done ? const HomeScreen() : const FarmSplash(),
    );
  }
}

class FarmSplash extends StatelessWidget {
  const FarmSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sky, AppColors.grass],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚜', style: TextStyle(fontSize: 72)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
