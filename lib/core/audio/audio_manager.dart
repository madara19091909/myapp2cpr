import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps background music alive while the user moves between game tabs.
/// The selected track is copied into the app's private storage so it remains
/// available after the original file is moved or removed from the Downloads folder.
class AudioManager extends ChangeNotifier {
  static const String _musicPathKey = 'farm_party_music_path_v1';
  static const double musicVolume = 0.25;

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSubscription;

  String? _musicPath;
  String? _musicName;
  bool _isPlaying = false;
  bool _initializing = false;
  bool _disposed = false;
  String? lastError;

  String? get musicName => _musicName;
  bool get isPlaying => _isPlaying;
  bool get hasMusic => _musicPath != null;
  bool get isInitializing => _initializing;

  AudioManager() {
    _playerSubscription = _musicPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _notify();
    });
  }

  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;
    _notify();
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedPath = preferences.getString(_musicPathKey);
      if (savedPath != null && await File(savedPath).exists()) {
        _musicPath = savedPath;
        _musicName = _fileName(savedPath);
        await _startMusic();
      } else if (savedPath != null) {
        await preferences.remove(_musicPathKey);
      }
    } catch (error) {
      lastError = 'تعذر استعادة الموسيقى المحفوظة.';
      debugPrint('Background music restore failed: $error');
    } finally {
      _initializing = false;
      _notify();
    }
  }

  Future<String?> pickMusic() async {
    lastError = null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;

      final selected = result.files.single;
      final sourcePath = selected.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        return 'تعذر الوصول إلى الملف الصوتي الذي اخترته.';
      }

      final source = File(sourcePath);
      if (!await source.exists()) return 'الملف الصوتي غير متاح. اختره من الهاتف مرة ثانية.';
      final length = await source.length();
      if (length == 0) return 'الملف الصوتي فارغ.';
      if (length > 100 * 1024 * 1024) return 'حجم الأغنية أكبر من 100 ميغابايت.';

      final extension = selected.extension?.toLowerCase() ??
          (sourcePath.contains('.') ? sourcePath.split('.').last.toLowerCase() : 'mp3');
      const supported = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'};
      if (!supported.contains(extension)) {
        return 'الصيغة غير مدعومة. اختر MP3 أو M4A أو WAV أو AAC أو OGG.';
      }

      final appDirectory = await getApplicationDocumentsDirectory();
      final musicDirectory = Directory('${appDirectory.path}/farm_music');
      await musicDirectory.create(recursive: true);
      final destinationPath = '${musicDirectory.path}/selected_track.$extension';
      await _musicPlayer.stop();
      await source.copy(destinationPath);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_musicPathKey, destinationPath);
      _musicPath = destinationPath;
      _musicName = selected.name;
      await _startMusic();
      _notify();
      return null;
    } catch (error) {
      lastError = 'تعذر اختيار الأغنية أو تشغيلها.';
      debugPrint('Music selection failed: $error');
      _notify();
      return lastError;
    }
  }

  Future<void> _startMusic() async {
    final path = _musicPath;
    if (path == null || !await File(path).exists()) return;
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(musicVolume);
    await _musicPlayer.play(DeviceFileSource(path));
    _isPlaying = true;
    _notify();
  }

  Future<void> toggleMusic() async {
    lastError = null;
    try {
      if (_musicPath == null) {
        final message = await pickMusic();
        if (message != null) lastError = message;
        return;
      }
      if (_isPlaying) {
        await _musicPlayer.pause();
      } else {
        await _startMusic();
      }
    } catch (error) {
      lastError = 'تعذر التحكم بالموسيقى.';
      debugPrint('Music toggle failed: $error');
    }
    _notify();
  }

  Future<void> clearMusic() async {
    await _musicPlayer.stop();
    final oldPath = _musicPath;
    _musicPath = null;
    _musicName = null;
    _isPlaying = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_musicPathKey);
    if (oldPath != null) {
      try {
        final file = File(oldPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _notify();
  }

  /// Used by game buttons for a short local UI click, separate from music.
  Future<void> playClick() async {
    try {
      await _clickPlayer.play(
        AssetSource('audio/ui_click.wav'),
        volume: 0.58,
      );
    } catch (error) {
      debugPrint('UI click sound failed: $error');
    }
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _playerSubscription?.cancel();
    unawaited(_musicPlayer.dispose());
    unawaited(_clickPlayer.dispose());
    super.dispose();
  }
}
