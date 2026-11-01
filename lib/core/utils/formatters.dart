String formatNumber(Object value) {
  final n = value is BigInt ? value : BigInt.tryParse(value.toString()) ?? BigInt.zero;
  final raw = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return n.isNegative ? '-$buffer' : buffer.toString();
}

String formatIqd(Object value) => '${formatNumber(value)} د.ع';

String formatDuration(int seconds) {
  if (seconds < 60) return '$secondsث';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$mد' : '$mد $sث';
}
