import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parallel_Video.dart';

/// Forest trail progress screen — shown between training sessions.
/// [currentSession]: 0 = before first session, 10 = after last session
class ForestTrailScreen extends StatelessWidget {
  final int currentSession; // 0–10
  final VoidCallback onContinue;
  final int totalSessions;

  const ForestTrailScreen({
    Key? key,
    required this.currentSession,
    required this.onContinue,
    this.totalSessions = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isFinished = currentSession >= totalSessions;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isFinished),
            Expanded(
              child: _TrailScrollView(
                currentSession: currentSession,
                totalSessions: totalSessions,
              ),
            ),
            _buildFooter(context, isFinished),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFinished) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinished ? 'You reached the end!' : 'Your Journey',
            style: const TextStyle(
              color: Color(0xFFD4E8B0),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFinished
                ? 'All $totalSessions sessions completed'
                : 'Session ${currentSession + 1} of $totalSessions',
            style: const TextStyle(
              color: Color(0xFF7BA05B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isFinished) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C9E3A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            isFinished ? 'Finish' : 'Continue to session ${currentSession + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated scrollable trail
// ─────────────────────────────────────────────

class _TrailScrollView extends StatefulWidget {
  final int currentSession;
  final int totalSessions;

  const _TrailScrollView({
    required this.currentSession,
    required this.totalSessions,
  });

  @override
  State<_TrailScrollView> createState() => _TrailScrollViewState();
}

class _TrailScrollViewState extends State<_TrailScrollView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fireflyController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fireflyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalNodes = widget.totalSessions + 2;
    const double segmentHeight = 110.0;
    final double totalHeight = segmentHeight * (totalNodes - 1) + 160;

    return SingleChildScrollView(
      reverse: true,
      padding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _fireflyController]),
        builder: (context, _) {
          return SizedBox(
            height: totalHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ForestBackgroundPainter(),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(
                      totalNodes: totalNodes,
                      currentSession: widget.currentSession,
                      segmentHeight: segmentHeight,
                      totalHeight: totalHeight,
                      pulseValue: _pulseController.value,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FireflyPainter(
                      phase: _fireflyController.value,
                      totalHeight: totalHeight,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Forest background — static, painted once
// ─────────────────────────────────────────────

class _ForestBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient: near-black at top → deep forest green at bottom
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040C04),
          Color(0xFF091509),
          Color(0xFF0F2010),
          Color(0xFF1A2E1A),
        ],
        stops: [0.0, 0.25, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final rng = math.Random(42);

    // Layer 1 — far trees: tiny, very dark, spaced across full height
    for (int i = 0; i < 22; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.20
          : size.width * 0.80 + rng.nextDouble() * size.width * 0.20;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.30 + rng.nextDouble() * 0.20, const Color(0xFF0C1A0C), rng);
    }

    // Layer 2 — mid trees: medium size, slightly brighter
    for (int i = 0; i < 22; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.23
          : size.width * 0.77 + rng.nextDouble() * size.width * 0.23;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.48 + rng.nextDouble() * 0.30, const Color(0xFF183214), rng);
    }

    // Layer 3 — close trees: large, hugging the edges
    for (int i = 0; i < 14; i++) {
      final double x = rng.nextBool()
          ? rng.nextDouble() * size.width * 0.14
          : size.width * 0.86 + rng.nextDouble() * size.width * 0.14;
      final double y = rng.nextDouble() * size.height;
      _drawTree(canvas, x, y, 0.85 + rng.nextDouble() * 0.55, const Color(0xFF233D19), rng);
    }

    // Mist bands — soft horizontal glow at a few depths
    _drawMist(canvas, size, 0.20);
    _drawMist(canvas, size, 0.48);
    _drawMist(canvas, size, 0.73);
    _drawMist(canvas, size, 0.91);

    // Forest floor — dark gradient at the very bottom
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF060F06).withOpacity(0.95),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height - 90, size.width, 90));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 90, size.width, 90), floorPaint);
  }

  void _drawMist(Canvas canvas, Size size, double yFrac) {
    final double y = size.height * yFrac;
    final mistPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF7BA05B).withOpacity(0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 28, size.width, 56));
    canvas.drawRect(Rect.fromLTWH(0, y - 28, size.width, 56), mistPaint);
  }

  void _drawTree(Canvas canvas, double x, double y, double scale,
      Color baseColor, math.Random rng) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(x, y + 6 * scale), width: 4 * scale, height: 14 * scale),
      Paint()
        ..color = const Color(0xFF120A04)
        ..style = PaintingStyle.fill,
    );

    final double h = 44 * scale;
    final double w = 26 * scale;
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Three layered canopy triangles (bottom to top)
    for (int layer = 0; layer < 3; layer++) {
      final double layerY = y - layer * h * 0.25;
      final double lw = w * (1.0 - layer * 0.10);
      final path = Path()
        ..moveTo(x, layerY - h * (0.38 + layer * 0.06))
        ..lineTo(x - lw * 0.5, layerY + h * 0.13)
        ..lineTo(x + lw * 0.5, layerY + h * 0.13)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Trail path and nodes
// ─────────────────────────────────────────────

class _TrailPainter extends CustomPainter {
  final int totalNodes;
  final int currentSession;
  final double segmentHeight;
  final double totalHeight;
  final double pulseValue; // 0.0–1.0 for current-node pulse animation

  _TrailPainter({
    required this.totalNodes,
    required this.currentSession,
    required this.segmentHeight,
    required this.totalHeight,
    required this.pulseValue,
  });

  double _nodeX(int index, double width) {
    const double center = 0.5;
    const double offset = 0.10;
    final double shift = (index % 2 == 0) ? -offset : offset;
    return width * (center + shift);
  }

  double _nodeY(int index) => 80 + index * segmentHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Glow pass for completed segments ──
    final glowPaint = Paint()
      ..color = const Color(0xFF5CB83A).withOpacity(0.35)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    for (int i = 0; i < totalNodes - 1; i++) {
      final int fromSession = totalNodes - 1 - i;
      final int toSession = totalNodes - 1 - (i + 1);
      if (fromSession <= currentSession && toSession <= currentSession) {
        canvas.drawLine(
          Offset(_nodeX(i, size.width), _nodeY(i)),
          Offset(_nodeX(i + 1, size.width), _nodeY(i + 1)),
          glowPaint,
        );
      }
    }

    // ── Dashed path (completed brighter, future dim) ──
    final completedPathPaint = Paint()
      ..color = const Color(0xFF7BBF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final futurePathPaint = Paint()
      ..color = const Color(0xFF2E4220)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalNodes - 1; i++) {
      final int fromSession = totalNodes - 1 - i;
      final bool completed = fromSession <= currentSession;
      _drawDashedLine(
        canvas,
        completed ? completedPathPaint : futurePathPaint,
        Offset(_nodeX(i, size.width), _nodeY(i)),
        Offset(_nodeX(i + 1, size.width), _nodeY(i + 1)),
      );
    }

    // ── Nodes ──
    for (int i = 0; i < totalNodes; i++) {
      final Offset pos = Offset(_nodeX(i, size.width), _nodeY(i));
      final int nodeSessionIndex = totalNodes - 1 - i;
      final bool isCompleted = nodeSessionIndex <= currentSession;
      final bool isCurrent = nodeSessionIndex == currentSession;
      final bool isStart = nodeSessionIndex == 0;
      final bool isEnd = nodeSessionIndex == totalNodes - 1;

      _drawNode(canvas, pos, isCompleted, isCurrent, isStart, isEnd, nodeSessionIndex);
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset from, Offset to) {
    const double dashLen = 8;
    const double gapLen = 5;
    final double dx = to.dx - from.dx;
    final double dy = to.dy - from.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double ux = dx / dist;
    final double uy = dy / dist;

    double traveled = 0;
    bool drawing = true;
    while (traveled < dist) {
      final double segEnd =
          math.min(traveled + (drawing ? dashLen : gapLen), dist);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + ux * traveled, from.dy + uy * traveled),
          Offset(from.dx + ux * segEnd, from.dy + uy * segEnd),
          paint,
        );
      }
      traveled = segEnd;
      drawing = !drawing;
    }
  }

  void _drawNode(Canvas canvas, Offset pos, bool isCompleted, bool isCurrent,
      bool isStart, bool isEnd, int sessionIndex) {
    final double radius = isCurrent ? 22 : (isStart || isEnd ? 18 : 14);

    // Animated pulse rings for current node
    if (isCurrent) {
      for (int ring = 0; ring < 2; ring++) {
        final double delay = ring * 0.4;
        final double t = ((pulseValue + delay) % 1.0);
        final double pulseRadius = radius + 6 + t * 20;
        final double opacity = (1 - t) * 0.45;
        canvas.drawCircle(
          pos,
          pulseRadius,
          Paint()
            ..color = const Color(0xFF5CB83A).withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Soft glow behind the current node
      canvas.drawCircle(
        pos,
        radius + 10,
        Paint()
          ..color = const Color(0xFF5CB83A).withOpacity(0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Drop shadow
    canvas.drawCircle(
      pos + const Offset(0, 3),
      radius,
      Paint()..color = Colors.black.withOpacity(isCurrent ? 0.45 : 0.25),
    );

    // Fill
    Color fillColor;
    if (isCurrent) {
      fillColor = const Color(0xFFEAF7C5);
    } else if (isCompleted) {
      fillColor = const Color(0xFF4E9030);
    } else {
      fillColor = const Color(0xFF243520);
    }
    canvas.drawCircle(pos, radius, Paint()..color = fillColor);

    // Border ring
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = isCurrent
            ? const Color(0xFF6CC840)
            : isCompleted
                ? const Color(0xFF7BBF50)
                : const Color(0xFF344F24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 3.0 : 1.5,
    );

    // Content
    if (isStart) {
      _drawEmoji(canvas, pos, '🌱', 18);
    } else if (isEnd) {
      _drawEmoji(canvas, pos, '🏆', 18);
    } else if (isCompleted && !isCurrent) {
      _drawCheckmark(canvas, pos, radius);
    } else if (isCurrent) {
      _drawText(canvas, pos, '$sessionIndex', const Color(0xFF1A2E1A), 14, FontWeight.w700);
    } else {
      _drawText(canvas, pos, '$sessionIndex', const Color(0xFF4A6A35), 11, FontWeight.w500);
    }
  }

  void _drawCheckmark(Canvas canvas, Offset pos, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double r = radius * 0.45;
    final path = Path()
      ..moveTo(pos.dx - r * 0.9, pos.dy)
      ..lineTo(pos.dx - r * 0.15, pos.dy + r * 0.75)
      ..lineTo(pos.dx + r, pos.dy - r * 0.65);
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, Offset pos, String text, Color color,
      double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawEmoji(Canvas canvas, Offset pos, String emoji, double size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.currentSession != currentSession || old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────
// Fireflies — animated floating glowing dots
// ─────────────────────────────────────────────

class _FireflyPainter extends CustomPainter {
  final double phase; // 0.0–1.0, repeating
  final double totalHeight;

  _FireflyPainter({required this.phase, required this.totalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);

    for (int i = 0; i < 18; i++) {
      // Each firefly has a fixed base position and unique phase offset
      final double baseXFrac = 0.22 + rng.nextDouble() * 0.56;
      final double baseYFrac = rng.nextDouble();
      final double phaseOffset = rng.nextDouble() * 2 * math.pi;
      final double speedMult = 0.4 + rng.nextDouble() * 0.9;
      final double driftRadius = 10 + rng.nextDouble() * 16;

      final double t = phase * 2 * math.pi * speedMult + phaseOffset;
      final double x = size.width * baseXFrac + driftRadius * math.sin(t);
      final double y =
          size.height * baseYFrac + driftRadius * math.cos(t * 0.65 + 1.1);

      // Brightness pulses independently
      final double brightness =
          (math.sin(t * 1.4 + phaseOffset * 0.7) + 1) / 2;
      if (brightness < 0.08) continue;

      final double dotRadius = 1.2 + brightness * 2.0;
      final double opacity = 0.12 + brightness * 0.60;

      // Soft outer glow
      canvas.drawCircle(
        Offset(x, y),
        dotRadius + 4,
        Paint()
          ..color = const Color(0xFFCCFF66).withOpacity(opacity * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Bright core
      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        Paint()..color = const Color(0xFFEEFF99).withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────
// Home widget — persists progress across launches
// ─────────────────────────────────────────────

class ForestTrailHome extends StatefulWidget {
  const ForestTrailHome({Key? key}) : super(key: key);

  @override
  State<ForestTrailHome> createState() => _ForestTrailHomeState();
}

class _ForestTrailHomeState extends State<ForestTrailHome> {
  static const _prefKey = 'completed_sessions';
  static const int _totalSessions = 10;

  int _completed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completed = prefs.getInt(_prefKey) ?? 0;
      _loading = false;
    });
  }

  Future<void> _incrementSession() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (_completed + 1).clamp(0, _totalSessions);
    await prefs.setInt(_prefKey, next);
    if (mounted) setState(() => _completed = next);
  }

  Future<void> _resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, 0);
    setState(() => _completed = 0);
  }

  void _startSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiofeedbackScreen(
          onSessionComplete: () async {
            await _incrementSession();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E1A),
        title: const Text('Reset progress?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear all completed sessions and start from the beginning.',
          style: TextStyle(color: Color(0xFFD4E8B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7BA05B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetProgress();
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1A0A),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF5C9E3A))),
      );
    }

    final bool isFinished = _completed >= _totalSessions;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7BA05B)),
            tooltip: 'Reset progress',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(isFinished),
            Expanded(
              child: _TrailScrollView(
                currentSession: _completed,
                totalSessions: _totalSessions,
              ),
            ),
            _buildFooter(isFinished),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFinished) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinished ? 'You reached the end!' : 'Your Journey',
            style: const TextStyle(
              color: Color(0xFFD4E8B0),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFinished
                ? 'All $_totalSessions sessions completed'
                : '$_completed / $_totalSessions sessions done',
            style: const TextStyle(
              color: Color(0xFF7BA05B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isFinished) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isFinished ? null : _startSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C9E3A),
            disabledBackgroundColor: const Color(0xFF3A5228),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            isFinished
                ? 'All done!'
                : _completed == 0
                    ? 'Start session 1'
                    : 'Continue to session ${_completed + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
