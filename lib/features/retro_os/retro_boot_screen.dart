import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class RetroBootScreen extends StatefulWidget {
  final VoidCallback onBootComplete;

  const RetroBootScreen({super.key, required this.onBootComplete});

  @override
  State<RetroBootScreen> createState() => _RetroBootScreenState();
}

class _RetroBootScreenState extends State<RetroBootScreen> {
  int _progress = 0;
  String _status = "POWERING ON...";
  Timer? _timer;

  final List<String> _statuses = [
    "MOUNTING MEMORY.SYS...",
    "LOADING KATAMARI_PHYSICS.DLL...",
    "WARMING UP THE CRT DISPLAY...",
    "INITIALIZING WORK_STUFF🤫...",
    "WELCOME TO SAKSHAM's PROTFOLIO."
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() {
    // Random stuttering progress to mimic an old hard drive loading
    _timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (_progress < 100) {
        setState(() {
          // Jump forward by random chunks
          _progress += math.Random().nextInt(12) + 4;
          if (_progress > 100) _progress = 100;

          // Sync the text to the progress
          if (_progress < 20) {
            _status = _statuses[0];
          } else if (_progress < 45) {
            _status = _statuses[1];
          } else if (_progress < 75) {
            _status = _statuses[2];
          } else if (_progress < 95) {
            _status = _statuses[3];
          } else {
            _status = _statuses[4];
          }
        });
      } else {
        timer.cancel();
        // Pause for half a second on 100% so they can read "WELCOME"
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onBootComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE6), // Matches your OS background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background dot grid so it seamlessly transitions to the desktop
          CustomPaint(
            painter: _StaticGridPainter(),
            size: Size.infinite,
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 6),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(12, 12))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Giant retro computer icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF90CDF4), // Brutalist Blue
                        border: Border.all(color: Colors.black, width: 4),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                      ),
                      child: const Icon(Icons.computer, size: 64, color: Colors.black),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      "SAKSHAM OS",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "SYSTEM VERSION 1.0",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brutalist Progress Bar Box
                    Container(
                      height: 24,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      // The actual filling bar
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress / 100,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF68D391), // Brutalist Green
                            border: Border(right: BorderSide(color: Colors.black, width: 3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading Status Text
                    SizedBox(
                      height: 20,
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reused grid painter so the background matches the OS perfectly
class _StaticGridPainter extends CustomPainter {
  final Paint dotPaint = Paint()
    ..color = const Color(0xFF000000).withAlpha(15)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    const double dotSpacing = 24.0;
    for (double i = 0; i < size.width; i += dotSpacing) {
      for (double j = 0; j < size.height; j += dotSpacing) {
        canvas.drawPoints(PointMode.points, [Offset(i, j)], dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}