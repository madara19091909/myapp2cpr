String formatNumber(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

String formatIqd(int n) => '${formatNumber(n)} د.ع';

String formatDuration(int seconds) {
  if (seconds < 60) return '$secondsث';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$mد' : '$mد $sث';
}
