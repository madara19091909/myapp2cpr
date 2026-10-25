class Plot {
  String? cropId;
  DateTime? plantedAt;
  int growSeconds = 0;

  bool get isEmpty => cropId == null;

  DateTime? get readyAt => plantedAt?.add(Duration(seconds: growSeconds));

  bool isReady(DateTime now) {
    final end = readyAt;
    return end != null && !now.isBefore(end);
  }

  int remainingSeconds(DateTime now) {
    final end = readyAt;
    if (end == null) return 0;
    final ms = end.difference(now).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void clear() {
    cropId = null;
    plantedAt = null;
    growSeconds = 0;
  }
}
