import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AnimatedVideoPage extends StatefulWidget {
  final List<double> peaks;
  final double duration;
  final VoidCallback onFinished;

  const AnimatedVideoPage({
    required this.peaks,
    required this.duration,
    required this.onFinished,
  });

  @override
  _AnimatedVideoPageState createState() => _AnimatedVideoPageState();
}

class _AnimatedVideoPageState extends State<AnimatedVideoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _player = AudioPlayer();
  Set<int> _playedPeaks = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward();
    _startPeakMonitor();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tickTimer?.cancel();
        widget.onFinished();
      }
    });
  }

  void _startPeakMonitor() {
    _tickTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      double currentTime = _controller.value * widget.duration;

      for (int i = 0; i < widget.peaks.length; i++) {
        if (!_playedPeaks.contains(i) &&
            (currentTime - widget.peaks[i]).abs() < 0.02) {
          _playedPeaks.add(i);
          _player.play(AssetSource('beep.mp3'), volume: 1.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Playing Animation", style: TextStyle(color: Colors.green)),
      ),
      body: CustomPaint(
        painter: ECGPainter(
          peaks: widget.peaks,
          elapsedTime: _controller.value * widget.duration,
          totalDuration: widget.duration,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> peaks;
  final double elapsedTime;
  final double totalDuration;

  // How many seconds are visible on screen at once
  static const double visibleWindowSeconds = 4.0;

  ECGPainter({
    required this.peaks,
    required this.elapsedTime,
    required this.totalDuration,
  });

  // Draws a realistic ECG waveform shape centered at x=0, t=0
  // Returns the y offset (normalized -1..1) for a given time offset from peak
  double _ecgShape(double dt) {
    // P wave: small bump ~0.2s before QRS
    double p = 0.08 * math.exp(-math.pow((dt + 0.2) / 0.045, 2));

    // Q dip: small negative just before R
    double q = -0.15 * math.exp(-math.pow((dt + 0.03) / 0.015, 2));

    // R spike: tall sharp peak at dt=0
    double r = 1.0 * math.exp(-math.pow(dt / 0.018, 2));

    // S dip: negative just after R
    double s = -0.25 * math.exp(-math.pow((dt - 0.04) / 0.018, 2));

    // T wave: broad positive hump ~0.25s after QRS
    double t = 0.25 * math.exp(-math.pow((dt - 0.28) / 0.07, 2));

    return p + q + r + s + t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines (faint, like a real monitor)
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.12)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      double y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i < 8; i++) {
      double x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final amplitude = size.height * 0.35;

    // pixelsPerSecond: how fast the line scrolls
    final pixelsPerSecond = size.width / visibleWindowSeconds;

    // The "cursor" is at a fixed X position (right side of screen)
    // Everything to the left of cursor is the drawn trace
    // We draw from left to right: leftmost pixel = elapsedTime - visibleWindowSeconds

    final windowStart = elapsedTime - visibleWindowSeconds;

    // Build the signal buffer pixel by pixel
    // For each x pixel, compute the time it represents
    // Then sum ECG contributions from all peaks near that time

    Offset? prev;

    // Only draw up to the current time (cursor position = right edge)
    // Points after elapsedTime haven't "happened" yet — leave them black
    // But we scroll: so we show [windowStart .. elapsedTime]

    final totalPixels = size.width.toInt();

    for (int px = 0; px < totalPixels; px++) {
      // Time this pixel represents
      double t = windowStart + (px / size.width) * visibleWindowSeconds;

      // Don't draw future time
      if (t > elapsedTime) break;

      // Don't draw before session started
      double signal = 0.0;
      if (t >= 0) {
        for (double peakTime in peaks) {
          double dt = t - peakTime;
          // Only consider peaks within ±0.6s (ECG shape window)
          if (dt >= -0.35 && dt <= 0.65) {
            signal += _ecgShape(dt);
          }
        }
      }

      double y = centerY - signal * amplitude;
      Offset current = Offset(px.toDouble(), y);

      if (prev != null) {
        canvas.drawLine(prev, current, linePaint);
      }
      prev = current;
    }

    // Draw the cursor: a bright vertical line at the leading edge
    final cursorX = math.min(
      size.width,
      ((elapsedTime - windowStart) / visibleWindowSeconds) * size.width,
    );

    final cursorPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      cursorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) =>
      oldDelegate.elapsedTime != elapsedTime;
}