import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'parallel_Video.dart';
import 'animated_video_page.dart';

class GuessingScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const GuessingScreen({required this.data});

  @override
  _GuessingScreenState createState() => _GuessingScreenState();
}

class _GuessingScreenState extends State<GuessingScreen> {
  final TextEditingController _guessController = TextEditingController();
  bool _submittedGuess = false;
  int? _userGuess;
  double _confidence = 50.0;
  bool _videoStage = false;
  bool _selectionMade = false;
  bool? _isCorrect;
  bool _showSignal = false;

  late List<double> realPeaks;
  late List<double> fakePeaks;
  late List<double> cleanSignal;
  late int peaksCount;
  late double duration;

  @override
  void initState() {
    super.initState();
    realPeaks = List<double>.from(widget.data["real_peaks"]);
    cleanSignal = List<double>.from(widget.data["clean_signal"]);
    peaksCount = widget.data["peaks_count"];
    duration = widget.data["duration"].toDouble();

    // Generate fake peaks from real peaks with a random speed factor
    final random = math.Random();
    // Randomly choose: faster (0.80–0.90) or slower (1.10–1.20)
    bool makeFaster = random.nextBool();
    double factor = makeFaster
        ? 0.80 + random.nextDouble() * 0.10  // 0.80 to 0.90
        : 1.10 + random.nextDouble() * 0.10; // 1.10 to 1.20

    fakePeaks = realPeaks.map((p) => p * factor).toList();
  }

  void _submitGuess() {
    if (_guessController.text.isEmpty) return;
    setState(() {
      _userGuess = int.tryParse(_guessController.text);
      _submittedGuess = true;
      _videoStage = true;
    });
  }

  void _playAndSelect(List<double> peaks, bool isReal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimatedVideoPage(
          peaks: peaks,
          duration: duration,
          onFinished: () {
            setState(() {
              _selectionMade = true;
              _isCorrect = isReal;
            });

            Future.delayed(Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BiofeedbackScreen()),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _videoButton({required String label, required List<double> peaks, required bool isReal}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimatedVideoPage(
                  peaks: peaks,
                  duration: duration,
                  onFinished: () {},
                ),
              ),
            );
          },
          child: Container(
            width: 160,
            height: 90,
            color: Colors.grey[800],
            child: Center(
              child: Text("Tap to play", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectionMade
              ? null
              : () {
                  setState(() {
                    _selectionMade = true;
                    _isCorrect = isReal;
                  });

                  Future.delayed(Duration(seconds: 2), () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => BiofeedbackScreen()),
                    );
                  });
                },
          child: Text("This is real"),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Guessing")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: !_submittedGuess
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "How many beats did you count?",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _guessController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: "Enter number",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  
                  // ========== ADD CONFIDENCE SLIDER SECTION ==========
                  SizedBox(height: 40),
                  Text(
                    "How confident are you?",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  
                  Slider(
                    value: _confidence,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_confidence.round()}%',
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    onChanged: (double value) {
                      setState(() {
                        _confidence = value;
                      });
                    },
                  ),
                  
                  // Display confidence percentage
                  Text(
                    '${_confidence.round()}%',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  
                  // Labels under slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Not confident',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Very confident',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // ========== END CONFIDENCE SLIDER SECTION ==========
                  
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitGuess,
                    child: Text("Submit"),
                  )
                ],
              )
              : !_videoStage
                  ? SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              "You guessed: $_userGuess\nActual: $peaksCount",
                              style: TextStyle(color: Colors.white, fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Your confidence: ${_confidence.round()}%",
                              style: TextStyle(color: Colors.blue, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _videoButton(label: "Option 1", peaks: realPeaks, isReal: true),
                            _videoButton(label: "Option 2", peaks: fakePeaks, isReal: false),
                          ],
                        ),
                        if (_selectionMade) ...[
                          SizedBox(height: 30),
                          Text(
                            _isCorrect == true ? "✅ Correct!" : "❌ Incorrect",
                            style: TextStyle(
                              color: _isCorrect == true ? Colors.green : Colors.red,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => setState(() => _showSignal = !_showSignal),
                          child: Text(_showSignal ? "Hide Signal" : "Show Signal"),
                        ),
                        if (_showSignal)
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: SignalPainter(cleanSignal),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class SignalPainter extends CustomPainter {
  final List<double> signal;

  SignalPainter(this.signal);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (signal.isEmpty) return;

    final maxVal = signal.reduce((a, b) => a > b ? a : b);
    final minVal = signal.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() + 1e-6;

    for (int i = 0; i < signal.length; i++) {
      double x = (i / (signal.length - 1)) * size.width;
      double y = size.height - ((signal[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}