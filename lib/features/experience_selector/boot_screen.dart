import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Experiment: paint the Mario sky behind the whole retro half of the home screen (true), or keep the
/// cream graph-paper background with the sky only inside the runner strip (false).
const _fullSkyBackdrop = true;

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  int _activeSide = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
            ),
            child: Column(
              children: [
                _buildBrowserBar(),
                Expanded(
                  child: isMobile ? _buildMobileLayout() : _buildDesktopSplitLayout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowserBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
        color: Color(0xFFF4EFE6),
      ),
      child: Row(
        children: [
          _buildBrowserDot(const Color(0xFFFF5F56)),
          const SizedBox(width: 8),
          _buildBrowserDot(const Color(0xFFFFBD2E)),
          const SizedBox(width: 8),
          _buildBrowserDot(const Color(0xFF27C93F)),
          const SizedBox(width: 24),
          const Expanded(
            child: Text(
              "HELLO, I'M SAKSHAM BIR SINGH",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E05E),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ),
            child: const Text("* SELECT UI *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSplitLayout() {
    return Stack(
      children: [
        Row(
          children: <Widget>[
            Expanded(
              flex: _activeSide == -1 ? 55 : (_activeSide == 1 ? 45 : 50),
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.opaque,
                onEnter: (_) => setState(() => _activeSide = -1),
                onExit: (_) => setState(() => _activeSide = 0),
                child: const _RetroBrutalistSide(),
              ),
            ),
            Expanded(
              flex: _activeSide == 1 ? 55 : (_activeSide == -1 ? 45 : 50),
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.opaque,
                onEnter: (_) => setState(() => _activeSide = 1),
                onExit: (_) => setState(() => _activeSide = 0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(left: BorderSide(color: Colors.black, width: 4)),
                  ),
                  child: const _SpatialRoomSide(),
                ),
              ),
            ),
          ],
        ),
        AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: _activeSide == -1 ? const Alignment(0.1, 0) : _activeSide == 1 ? const Alignment(-0.1, 0) : Alignment.center,
          child: IgnorePointer(
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: const Center(child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Expanded(child: _RetroBrutalistSide()),
        Container(height: 4, color: Colors.black),
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF0F172A)),
            child: _SpatialRoomSide(),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserDot(Color color) {
    return Container(width: 16, height: 16, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 2)));
  }
}

// ==========================================
// LEFT SIDE: RETRO BENTO BOX
// ==========================================
class _RetroBrutalistSide extends StatelessWidget {
  const _RetroBrutalistSide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _fullSkyBackdrop
              ? const _SkyBackdrop()
              : Container(
                  color: const Color(0xFFF4EFE6),
                  child: CustomPaint(painter: _RetroGraphPaperPainter()),
                ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NeoBrutalistCard(
                      // light blue would vanish against the sky, so the title card goes cream in that mode
                      color: _fullSkyBackdrop ? const Color(0xFFF4EFE6) : const Color(0xFF90CDF4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('MODE 01', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'RETRO OS',
                            style: TextStyle(
                              fontSize: 48, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
                              shadows: [
                                const Shadow(color: Colors.white, offset: Offset(3, 3)),
                                const Shadow(color: Colors.black, offset: Offset(4, 4)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Interactive 1995 desktop with draggable windows and taskbar.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _NeoBrutalistCard(color: const Color(0xFFFFB6B9), child: const Center(child: Text('DRAGGABLE\nUI', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))))),
                        const SizedBox(width: 24),
                        Expanded(child: _NeoBrutalistCard(color: const Color(0xFF68D391), child: const Center(child: Text('STATE\nMANAGED', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _NeoBrutalistButton(text: 'BOOT RETRO OS ▶', color: const Color(0xFFF6E05E), textColor: Colors.black, onTap: () => context.go('/retro')),
                  ],
                ),
              ),
            ),

            // 🚀 FIXED HEIGHT ENDLESS RUNNER (No more layout collapsing)
            const SizedBox(
              height: 180,
              width: double.infinity,
              child: _AutoRunner(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mario-style sky with slow drifting clouds, behind the whole retro half (see [_fullSkyBackdrop]).
/// Same colours as the runner's own sky, so the runner strip blends into it.
class _SkyBackdrop extends StatefulWidget {
  const _SkyBackdrop();

  @override
  State<_SkyBackdrop> createState() => _SkyBackdropState();
}

class _SkyBackdropState extends State<_SkyBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF5C94FC), Color(0xFFA8D8FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: _CloudsPainter(_c.value), size: Size.infinite),
        ),
      ),
    );
  }
}

class _CloudsPainter extends CustomPainter {
  _CloudsPainter(this.t);
  final double t; // 0..1 over one full loop

  // (x, y as fractions of the area, scale, laps per loop)
  static const _clouds = [
    (0.10, 0.08, 1.0, 1),
    (0.55, 0.20, 1.3, 2),
    (0.86, 0.05, 0.8, 1),
    (0.30, 0.40, 1.1, 3),
    (0.72, 0.52, 0.9, 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final span = size.width + 320;
    final narrow = size.width < 500; // phones: fewer, smaller clouds so the small area doesn't get crowded
    for (final (fx, fy, scale, laps) in narrow ? _clouds.take(3) : _clouds) {
      final x = ((fx * size.width + t * laps * span) % span) - 160;
      _cloud(canvas, Offset(x, fy * size.height), narrow ? scale * 0.75 : scale);
    }
  }

  void _cloud(Canvas canvas, Offset o, double s) {
    final r = 16 * s;
    Path shape(double dy) => Path()
      ..addOval(Rect.fromCircle(center: o.translate(0, dy), radius: r))
      ..addOval(Rect.fromCircle(center: o.translate(r * 1.4, dy - r * 0.55), radius: r * 1.35))
      ..addOval(Rect.fromCircle(center: o.translate(r * 2.9, dy), radius: r))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(o.dx - r, o.dy + dy - 0.05 * r, o.dx + r * 3.9, o.dy + dy + r), Radius.circular(r * 0.9)));
    canvas.drawPath(shape(3), Paint()..color = const Color(0xFFCFE3FF)); // soft underside
    canvas.drawPath(shape(0), Paint()..color = Colors.white.withValues(alpha: 0.96));
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => old.t != t;
}

// ==========================================
// 🚀 THE PURE FLUTTER ENDLESS RUNNER ENGINE
// ==========================================
class _AutoRunner extends StatefulWidget {
  const _AutoRunner();

  @override
  State<_AutoRunner> createState() => _AutoRunnerState();
}

class _AutoRunnerState extends State<_AutoRunner> with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  double _lastTime = 0.0;
  double _scrollOffset = 0.0;
  double _prevWorldOffset = 0.0;
  double _globalTime = 0.0;

  int _hitStopFrames = 0;

  bool _mushroomHit = false;
  double _mushroomY = 0.0;
  double _punchTimer = 0.0;

  // Turtle (Koopa) State Machine
  bool _turtleStomped = false;
  bool _shellKicked = false;
  double _shellX = 0.0;
  bool _shellFalling = false;
  double _shellFallY = 0.0;
  bool _shellGone = false;

  // Goomba State Machine
  bool _goombaSquished = false;
  double _goombaSquishTimer = 0.0;

  double _plantY = 0.0;

  static const double loopSize = 6000.0;
  static const double goombaX = 800.0;
  static const double turtleStompX = 2050.0;
  static const List<List<double>> _gapRanges = [
    [480.0, 540.0],
    [2780.0, 2840.0],
    [4180.0, 4240.0],
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;

      setState(() {
        double currentTime = elapsed.inMilliseconds / 1000.0;
        double dt = (currentTime - _lastTime).clamp(0.0, 0.05);
        _lastTime = currentTime;
        _globalTime = currentTime;

        // Hit-Stop Freeze Effect
        if (_hitStopFrames > 0) {
          _hitStopFrames--;
          return;
        }

        if (_punchTimer > 0) _punchTimer = (_punchTimer - dt).clamp(0.0, 1.0);
        if (_goombaSquished) _goombaSquishTimer += dt;

        // Perfect infinite loop — keep scrollOffset bounded, never accumulate.
        _scrollOffset = (_scrollOffset + 120.0 * dt) % loopSize;
        double worldOffset = _scrollOffset;
        double marioWorldX = (worldOffset + 60.0) % loopSize;

        // Reset all per-lap obstacle state exactly once when the world wraps.
        if (worldOffset < _prevWorldOffset - 1000) {
          _mushroomHit = false;
          _mushroomY = 0.0;
          _punchTimer = 0.0;
          _turtleStomped = false;
          _shellKicked = false;
          _shellX = 0.0;
          _shellFalling = false;
          _shellFallY = 0.0;
          _shellGone = false;
          _goombaSquished = false;
          _goombaSquishTimer = 0.0;
        }

        // 1. Goomba Stomp
        if (!_goombaSquished && marioWorldX >= goombaX - 6 && marioWorldX <= goombaX + 6) {
          _goombaSquished = true;
          _hitStopFrames = 4;
          _goombaSquishTimer = 0.0;
        }

        // 2. Block Punch Logic
        if (!_mushroomHit && marioWorldX >= 1195 && marioWorldX < 1210) {
          _mushroomHit = true;
          _hitStopFrames = 6;
          _punchTimer = 0.3;
        }
        if (_mushroomHit && _mushroomY < 32.0) {
          _mushroomY += 2.0;
        }

        // 3. Stomp turns the Koopa into a shell in place, then a second hop
        // landing back on that same spot kicks it off.
        if (!_turtleStomped && marioWorldX >= turtleStompX - 5 && marioWorldX <= turtleStompX + 5) {
          _turtleStomped = true;
          _hitStopFrames = 15; // Major freeze on impact
          _shellX = turtleStompX; // Shell stays exactly where the Koopa was
        }

        if (_turtleStomped && !_shellKicked && marioWorldX >= turtleStompX + 30 && marioWorldX <= turtleStompX + 42) {
          _shellKicked = true;
          _hitStopFrames = 8; // Freeze on kick
        }

        if (_shellKicked && !_shellGone) {
          if (!_shellFalling) {
            _shellX += 450.0 * dt; // Shell blasts away along the ground
            for (final g in _gapRanges) {
              if (_shellX >= g[0] + 8 && _shellX <= g[1]) {
                _shellFalling = true; // It reached a pit — drop into it
                break;
              }
            }
          } else {
            _shellFallY += 260.0 * dt;
            if (_shellFallY > 50) _shellGone = true;
          }
        }

        // 4. Piranha Plant Hiding Logic
        double targetPlantY = 0.0;
        if (marioWorldX > 3250 && marioWorldX < 3800) {
          targetPlantY = 40.0; // Hide deep in pipe
        } else {
          targetPlantY = -10.0 + (math.sin(_globalTime * 3) * 15); // Bob up and down
        }
        _plantY += (targetPlantY - _plantY) * 0.15;

        _prevWorldOffset = worldOffset;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: _fullSkyBackdrop ? null : const Border(top: BorderSide(color: Colors.black, width: 4)), // Divider perfectly locked
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: _RunnerPainter(
            paintSky: !_fullSkyBackdrop,
            scrollOffset: _scrollOffset,
            globalTime: _globalTime,
            mushroomHit: _mushroomHit,
            mushroomY: _mushroomY,
            isPunching: _punchTimer > 0,
            turtleStomped: _turtleStomped,
            shellKicked: _shellKicked,
            shellX: _shellX,
            shellFallY: _shellFallY,
            shellGone: _shellGone,
            plantY: _plantY,
            goombaSquished: _goombaSquished,
            goombaSquishTimer: _goombaSquishTimer,
          ),
        ),
      ),
    );
  }
}

class _RunnerPainter extends CustomPainter {
  final bool paintSky; // false when the sky is painted behind the whole retro half
  final double scrollOffset;
  final double globalTime;
  final bool mushroomHit;
  final double mushroomY;
  final bool isPunching;
  final bool turtleStomped;
  final bool shellKicked;
  final double shellX;
  final double shellFallY;
  final bool shellGone;
  final double plantY;
  final bool goombaSquished;
  final double goombaSquishTimer;

  _RunnerPainter({
    this.paintSky = true,
    required this.scrollOffset,
    required this.globalTime,
    required this.mushroomHit,
    required this.mushroomY,
    required this.isPunching,
    required this.turtleStomped,
    required this.shellKicked,
    required this.shellX,
    required this.shellFallY,
    required this.shellGone,
    required this.plantY,
    required this.goombaSquished,
    required this.goombaSquishTimer,
  });

  static Map<Color, Path>? _r1, _r2, _r3, _jump, _punch, _mush, _tWalk1, _tWalk2, _shell, _plantOpen, _plantClosed, _cloud, _gWalk1, _gWalk2, _gSquish;
  static const double loopSize = 6000.0;
  static const double tileSize = 20.0;
  static const double goombaX = 800.0;
  static const double turtleStompX = 2050.0;

  // Any scrolling world position wraps to the "shortest path" from the
  // camera so it slides fully off-screen instead of popping out at x=0.
  static double _wrap(double worldX, double offset) {
    double sx = (worldX - offset) % loopSize;
    if (sx > loopSize / 2) sx -= loopSize;
    return sx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double groundY = size.height - tileSize;
    final double offset = scrollOffset % loopSize;

    // Compile Sprites once
    _r1 ??= _compileSprite(_pixelArtRun1);
    _r2 ??= _compileSprite(_pixelArtRun2);
    _r3 ??= _compileSprite(_pixelArtRun3);
    _jump ??= _compileSprite(_pixelArtJump);
    _punch ??= _compileSprite(_pixelArtPunch);
    _mush ??= _compileSprite(_pixelArtMushroom);
    _tWalk1 ??= _compileSprite(_pixelArtTurtle1);
    _tWalk2 ??= _compileSprite(_pixelArtTurtle2);
    _shell ??= _compileSprite(_pixelArtShell);
    _plantOpen ??= _compileSprite(_pixelArtPlantOpen);
    _plantClosed ??= _compileSprite(_pixelArtPlantClosed);
    _cloud ??= _compileSprite(_pixelArtCloud);
    _gWalk1 ??= _compileSprite(_pixelArtGoomba1);
    _gWalk2 ??= _compileSprite(_pixelArtGoomba2);
    _gSquish ??= _compileSprite(_pixelArtGoombaSquish);

    if (paintSky) _drawSky(canvas, size);
    _drawHills(canvas, size, offset);
    _drawClouds(canvas, size, offset);
    _drawBushes(canvas, size, groundY, offset);
    _drawPlant(canvas, size, groundY, offset); // Behind pipe
    _drawFloor(canvas, size, groundY, offset);
    _drawStaticObjects(canvas, size, groundY, offset);
    _drawEntities(canvas, size, groundY, offset);

    const double charScreenX = 60.0;
    final double charWorldX = (offset + charScreenX) % loopSize;

    double charY = groundY;
    bool isJumping = false;
    bool isOnPipe = false;

    // 🚀 Exact Physics Arcs
    if (charWorldX >= 420 && charWorldX <= 580) {
      isJumping = true;
      charY -= math.sin((charWorldX - 420) / 160 * math.pi) * 35;
    }
    else if (charWorldX >= 760 && charWorldX <= 840) {
      isJumping = true;
      charY -= math.sin((charWorldX - 760) / 80 * math.pi) * 32; // Stomp on the Goomba at 800
    }
    else if (charWorldX >= 1140 && charWorldX <= 1260) {
      isJumping = true;
      charY -= math.sin((charWorldX - 1140) / 120 * math.pi) * 30; // Perfect apex at 1200
    }
    // Small Pipe Platforming
    else if (charWorldX >= 1570 && charWorldX <= 1730) {
      if (charWorldX < 1650) {
        isJumping = true;
        charY -= math.sin((charWorldX - 1570) / 80 * (math.pi / 2)) * 40;
      } else if (charWorldX <= 1690) {
        charY -= 40; // Flat on top
        isOnPipe = true;
      } else {
        isJumping = true;
        charY -= math.cos((charWorldX - 1690) / 40 * (math.pi / 2)) * 40;
      }
    }
    // Stomp jump — lands exactly on the Koopa, turning it into a shell.
    else if (charWorldX >= turtleStompX - 100 && charWorldX <= turtleStompX) {
      isJumping = true;
      charY -= math.sin((charWorldX - (turtleStompX - 100)) / 100 * math.pi) * 40;
    }
    // Second, tighter hop landing back on the same spot — kicks the shell off.
    else if (charWorldX > turtleStompX && charWorldX <= turtleStompX + 36) {
      isJumping = true;
      charY -= math.sin((charWorldX - turtleStompX) / 36 * math.pi) * 26;
    }
    else if (charWorldX >= 2720 && charWorldX <= 2880) {
      isJumping = true;
      charY -= math.sin((charWorldX - 2720) / 160 * math.pi) * 35;
    }
    // Tall Pipe Platforming
    else if (charWorldX >= 3450 && charWorldX <= 3650) {
      if (charWorldX < 3550) {
        isJumping = true;
        charY -= math.sin((charWorldX - 3450) / 100 * (math.pi / 2)) * 60;
      } else if (charWorldX <= 3590) {
        charY -= 60;
        isOnPipe = true;
      } else {
        isJumping = true;
        charY -= math.cos((charWorldX - 3590) / 60 * (math.pi / 2)) * 60;
      }
    }
    else if (charWorldX >= 4120 && charWorldX <= 4280) {
      isJumping = true;
      charY -= math.sin((charWorldX - 4120) / 160 * math.pi) * 35;
    }

    // 🚀 True Animation Engine — run / jump / punch
    Map<Color, Path> currentSprite;
    if (isPunching) {
      currentSprite = _punch!;
    } else if (isJumping && !isOnPipe) {
      currentSprite = _jump!;
    } else {
      int runFrame = ((charWorldX % 60) / 20).floor();
      if (runFrame == 0) {
        currentSprite = _r1!;
      } else if (runFrame == 1) {
        currentSprite = _r2!;
      } else {
        currentSprite = _r3!;
      }
    }

    _drawSprite(canvas, currentSprite, charScreenX, charY);
  }

  void _drawSky(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5C94FC), Color(0xFFA8D8FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, paint);
  }

  Path _hillPath(double cx, double baseY, double width, double height, double canvasBottom) {
    final path = Path();
    // A rectangular skirt down to the bottom of the strip so a floor gap
    // behind the hill never shows bare sky underneath it.
    path.moveTo(cx - width / 2, canvasBottom);
    path.lineTo(cx - width / 2, baseY);
    path.quadraticBezierTo(cx, baseY - height * 2, cx + width / 2, baseY);
    path.lineTo(cx + width / 2, canvasBottom);
    path.close();
    return path;
  }

  void _drawHills(Canvas canvas, Size size, double offset) {
    final farPaint = Paint()..color = const Color(0xFF6FCF6F);
    final nearPaint = Paint()..color = const Color(0xFF4CAF50);
    final stroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double groundY = size.height - tileSize;

    for (final hx in const [100.0, 900.0, 1700.0, 2500.0, 3300.0, 4100.0, 4900.0, 5700.0]) {
      double sx = _wrap(hx, offset * 0.15);
      if (sx > -160 && sx < size.width + 100) {
        final path = _hillPath(sx, groundY, 150, 42, size.height);
        canvas.drawPath(path, farPaint);
        canvas.drawPath(path, stroke);
      }
    }
    for (final hx in const [450.0, 1650.0, 2950.0, 4150.0, 5350.0]) {
      double sx = _wrap(hx, offset * 0.3);
      if (sx > -120 && sx < size.width + 100) {
        final path = _hillPath(sx, groundY, 100, 30, size.height);
        canvas.drawPath(path, nearPaint);
        canvas.drawPath(path, stroke);
      }
    }
  }

  void _drawBushes(Canvas canvas, Size size, double groundY, double offset) {
    final paint = Paint()..color = const Color(0xFF3E9142);
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final bx in const [280.0, 1020.0, 1480.0, 2380.0, 3150.0, 3980.0, 4750.0, 5150.0]) {
      double sx = _wrap(bx, offset);
      if (sx > -90 && sx < size.width + 50) {
        for (int i = 0; i < 3; i++) {
          final c = Offset(sx + i * 13.0, groundY - 7);
          canvas.drawCircle(c, 11, paint);
          canvas.drawCircle(c, 11, stroke);
        }
      }
    }
  }

  void _drawClouds(Canvas canvas, Size size, double offset) {
    List<double> clouds = [150, 900, 1800, 2700, 3600, 4500, 5400];
    for (var cx in clouds) {
      double screenX = _wrap(cx, offset * 0.2);
      if (screenX > -150 && screenX < size.width + 100) {
        double yPos = 10.0 + ((cx * 7) % 30);
        _drawSprite(canvas, _cloud!, screenX, yPos, isCloud: true);
      }
    }
  }

  void _drawFloor(Canvas canvas, Size size, double groundY, double offset) {
    final Paint paint = Paint()..color = const Color(0xFFD97746)..style = PaintingStyle.fill;
    final Paint mortarPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint strokePaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2;

    for (double i = 0; i <= size.width + tileSize; i += tileSize) {
      double screenX = i - (offset % tileSize);
      double absoluteWorldX = offset + screenX;
      double loopedWorldX = absoluteWorldX % loopSize;

      bool isGap = (loopedWorldX >= 480 && loopedWorldX <= 540) ||
          (loopedWorldX >= 2780 && loopedWorldX <= 2840) ||
          (loopedWorldX >= 4180 && loopedWorldX <= 4240);

      if (!isGap) {
        final rect = Rect.fromLTWH(screenX, groundY, tileSize, tileSize);
        canvas.drawRect(rect, paint);
        canvas.drawLine(Offset(screenX, groundY + tileSize * 0.5), Offset(screenX + tileSize, groundY + tileSize * 0.5), mortarPaint);
        canvas.drawLine(Offset(screenX + tileSize * 0.5, groundY), Offset(screenX + tileSize * 0.5, groundY + tileSize * 0.5), mortarPaint);
        canvas.drawRect(rect, strokePaint);
      }
    }
  }

  void _drawPlant(Canvas canvas, Size size, double groundY, double offset) {
    double screenX = _wrap(3550.0, offset);
    if (screenX > -50 && screenX < size.width) {
      // Toggle mouth open/close every 0.3 seconds
      bool isMouthOpen = (globalTime % 0.6) > 0.3;
      _drawSprite(canvas, isMouthOpen ? _plantOpen! : _plantClosed!, screenX + 20, groundY - 60 + plantY);
    }
  }

  void _drawStaticObjects(Canvas canvas, Size size, double groundY, double offset) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2;
    final Paint mortarPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final blocks = <Map<String, Object>>[
      {'x': 1176.0, 'type': 'brick'},
      {'x': 1200.0, 'type': 'question', 'interactive': true},
      {'x': 1224.0, 'type': 'brick'},
      {'x': 2420.0, 'type': 'question'},
      {'x': 4980.0, 'type': 'brick'},
      {'x': 5004.0, 'type': 'brick'},
      {'x': 5028.0, 'type': 'question'},
    ];

    for (final b in blocks) {
      double bx = b['x'] as double;
      double screenX = _wrap(bx, offset);
      if (screenX > -50 && screenX < size.width) {
        final rect = Rect.fromLTWH(screenX, groundY - 90, 24, 24);
        bool isInteractive = b['interactive'] == true;
        bool isHit = isInteractive && mushroomHit;
        bool isBrick = b['type'] == 'brick';

        if (isBrick) {
          paint.color = const Color(0xFFB5651D);
          canvas.drawRect(rect, paint);
          canvas.drawLine(Offset(screenX, groundY - 78), Offset(screenX + 24, groundY - 78), mortarPaint);
          canvas.drawLine(Offset(screenX + 12, groundY - 90), Offset(screenX + 12, groundY - 78), mortarPaint);
          canvas.drawLine(Offset(screenX + 6, groundY - 78), Offset(screenX + 6, groundY - 66), mortarPaint);
          canvas.drawLine(Offset(screenX + 18, groundY - 78), Offset(screenX + 18, groundY - 66), mortarPaint);
        } else {
          paint.color = isHit ? const Color(0xFF8B5CF6) : const Color(0xFFFFBD2E);
          canvas.drawRect(rect, paint);
          if (!isHit) {
            canvas.drawLine(
              Offset(screenX + 2, groundY - 88),
              Offset(screenX + 22, groundY - 88),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.5)
                ..strokeWidth = 2,
            );
            final tp = TextPainter(text: const TextSpan(text: '?', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)), textDirection: TextDirection.ltr)..layout();
            tp.paint(canvas, Offset(screenX + 6, groundY - 88));
          }
        }
        canvas.drawRect(rect, strokePaint);
      }
    }

    final pipes = <Map<String, Object>>[
      {'x': 1650.0, 'tall': false},
      {'x': 3550.0, 'tall': true},
    ];

    for (final p in pipes) {
      double px = p['x'] as double;
      bool isTall = p['tall'] as bool;
      double screenX = _wrap(px, offset);
      if (screenX > -50 && screenX < size.width) {
        double pHeight = isTall ? 60.0 : 40.0;
        paint.color = const Color(0xFF27C93F);

        canvas.drawRect(Rect.fromLTWH(screenX + 4, groundY - pHeight + 16, 32, pHeight - 16), paint);
        canvas.drawRect(Rect.fromLTWH(screenX + 4, groundY - pHeight + 16, 32, pHeight - 16), strokePaint);
        canvas.drawRect(Rect.fromLTWH(screenX, groundY - pHeight, 40, 16), paint);
        canvas.drawRect(Rect.fromLTWH(screenX, groundY - pHeight, 40, 16), strokePaint);

        canvas.drawRect(
          Rect.fromLTWH(screenX + 6, groundY - pHeight + 18, 4, pHeight - 20),
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
      }
    }
  }

  void _drawEntities(Canvas canvas, Size size, double groundY, double offset) {
    if (mushroomHit) {
      double mx = _wrap(1200.0, offset);
      if (mx > -50 && mx < size.width) {
        _drawSprite(canvas, _mush!, mx + 12, groundY - 90 - mushroomY);
      }
    }

    // Goomba
    if (!goombaSquished || goombaSquishTimer < 0.35) {
      double gx = _wrap(goombaX, offset);
      if (gx > -50 && gx < size.width) {
        if (!goombaSquished) {
          bool frameAlt = (globalTime % 0.3) > 0.15;
          _drawSprite(canvas, frameAlt ? _gWalk1! : _gWalk2!, gx + 14, groundY);
        } else {
          _drawSprite(canvas, _gSquish!, gx + 14, groundY - 4);
        }
      }
    }

    // Koopa / shell — stays put once stomped, only moves once kicked, and
    // drops out of view if it slides into a floor gap instead of running
    // off the edge of the world forever.
    if (!turtleStomped) {
      double tx = _wrap(turtleStompX, offset);
      if (tx > -50 && tx < size.width) {
        bool frameAlt = (globalTime % 0.4) > 0.2;
        _drawSprite(canvas, frameAlt ? _tWalk1! : _tWalk2!, tx + 16, groundY);
      }
    } else if (!shellGone) {
      double tx = _wrap(shellX, offset);
      if (tx > -50 && tx < size.width) {
        _drawSprite(canvas, _shell!, tx + 16, groundY + shellFallY);
      }
    }
  }

  void _drawSprite(Canvas canvas, Map<Color, Path> sprite, double x, double y, {bool isCloud = false}) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    canvas.save();
    if (isCloud) {
      canvas.translate(x, y);
      canvas.scale(2.5, 2.5);
    } else {
      canvas.translate(x - 16, y - 32);
      canvas.scale(2.0, 2.0);
    }

    sprite.forEach((color, path) {
      paint.color = color;
      canvas.drawPath(path, paint);
    });
    canvas.restore();
  }

  Map<Color, Path> _compileSprite(List<String> art) {
    Map<Color, Path> paths = {};
    final colors = {
      'R': const Color(0xFFE52521), // Mario Red
      'B': const Color(0xFF0058F8), // Overalls Blue
      'Y': const Color(0xFFF83800), // Brown Mustache
      'S': const Color(0xFFFCD088), // Peach Skin
      'K': const Color(0xFF000000), // Black
      'W': const Color(0xFFFFFFFF), // White
      'G': const Color(0xFF00A800), // Green
      'L': const Color(0xFF80D010), // Light Green (Plant lips)
      'N': const Color(0xFF6B3E1A), // Shoes / Goomba brown
    };

    for (int row = 0; row < art.length; row++) {
      for (int col = 0; col < art[row].length; col++) {
        String pixel = art[row][col];
        if (pixel == '.') continue;
        Color c = colors[pixel] ?? Colors.black;
        paths[c] ??= Path();
        paths[c]!.addRect(Rect.fromLTWH(col.toDouble(), row.toDouble(), 1.0, 1.0));
      }
    }
    return paths;
  }

  static const List<String> _pixelArtCloud = [
    ".........KKKKK...........",
    ".......KKWWWWWKK.........",
    "......KWWWWWWWWWK........",
    ".....KWWWWWWWWWWWK.KKK...",
    "....KKWWWWWWWWWWWKKWWWK..",
    "...KWWWWWWWWWWWWWWWWWWWK.",
    "..KWWWWWWWWWWWWWWWWWWWWWK",
    ".KWWWWWWWWWWWWWWWWWWWWWWK",
    ".KWWWWWWWWWWWWWWWWWWWWWWK",
    "..KKKKKKKKKKKKKKKKKKKKKK."
  ];

  static const List<String> _pixelArtRun1 = [
    ".....RRRRR......",
    "....RRRRRRRRR...",
    "....YYSSKSY.....",
    "...SSSYSSSSY....",
    "...SSSYSSYYY....",
    ".....SSSS.......",
    ".....BBBBB......",
    "....BBBRBBB.....",
    "...BBBBRBBBB...",
    "...WWWRWWWW.....",
    "...WWWRRWWWW....",
    "....RRRRRR......",
    "......BBBB......",
    ".....NN.NN......",
    "....NNN.NNN....."
  ];

  static const List<String> _pixelArtRun2 = [
    ".....RRRRR......",
    "....RRRRRRRRR...",
    "....YYSSKSY.....",
    "...SSSYSSSSY....",
    "...SSSYSSYYY....",
    ".....SSSS.......",
    ".....BBBBB......",
    "....BBBRBBB.....",
    "...BBBBRBBBB...",
    "...WWWRWWWW.....",
    "...WWWRRWWWW....",
    "....RRRRRR......",
    "......BBBB......",
    ".....NN.NN......",
    "....NNN..NNN...."
  ];

  static const List<String> _pixelArtRun3 = [
    ".....RRRRR......",
    "....RRRRRRRRR...",
    "....YYSSKSY.....",
    "...SSSYSSSSY....",
    "...SSSYSSYYY....",
    ".....SSSS.......",
    ".....BBBBB......",
    "....BBBRBBB.....",
    "...BBBBRBBBB...",
    "...WWWRWWWW.....",
    "...WWWRRWWWW....",
    "....RRRRRR......",
    "......BBBB......",
    ".......NN.......",
    "......NNNN......"
  ];

  static const List<String> _pixelArtJump = [
    ".....RRRRR......",
    "....RRRRRRRRR...",
    "....YYSSKSY.....",
    "...SSSYSSSSY....",
    "...SSSYSSYYY....",
    ".....SSSS.......",
    ".....BBBBB...WW.",
    "....BBBRBBB..WW.",
    "...BBBBRBBBBWW..",
    "...WWWRWWWW.....",
    "...WWWRRWWWW....",
    "....RRRRRR......",
    "......BBBB......",
    ".....NN.NN......"
  ];

  static const List<String> _pixelArtPunch = [
    "......WW........",
    ".....RRRRR......",
    "....RRRRRRRRR...",
    "....YYSSKSY.....",
    "...SSSYSSSSY....",
    "...SSSYSSYYY....",
    ".....SSSS.......",
    ".....BBBBB......",
    "....BBBRBBB.....",
    "...BBBBRBBBB...",
    "...WWWRWWWW.....",
    "...WWWRRWWWW....",
    "....RRRRRR......",
    "......BBBB......",
    ".....NN.NN......"
  ];

  static const List<String> _pixelArtMushroom = [
    "................",
    ".....RRRRRR.....",
    "...RRWWWWWRR....",
    "..RRRWWWWWRRR...",
    ".RRRRRWWWRRRRR..",
    ".RWWWRRRRRWWWR..",
    ".RWWWRRRRRWWWR..",
    ".RRRRRRRRRRRRR..",
    "..RRRRRRRRRRR...",
    "....WWWWWWW.....",
    "....WKKKKKW.....",
    "....WWWWWWW.....",
    "................",
    "................"
  ];

  static const List<String> _pixelArtGoomba1 = [
    "................",
    "......NNNN......",
    "....NNNNNNNN....",
    "...NNNNNNNNNN...",
    "..NNNNNNNNNNNN..",
    ".NNKKNNNNKKNN...",
    ".NNNNNNNNNNNNNN.",
    "..SSSSSSSSSSSS..",
    "..SSKSSSSSKSS...",
    "...SSSSSSSSSS...",
    "....KK....KK....",
    "...KKK....KKK...",
    "................"
  ];

  static const List<String> _pixelArtGoomba2 = [
    "................",
    "......NNNN......",
    "....NNNNNNNN....",
    "...NNNNNNNNNN...",
    "..NNNNNNNNNNNN..",
    ".NNKKNNNNKKNN...",
    ".NNNNNNNNNNNNNN.",
    "..SSSSSSSSSSSS..",
    "..SSKSSSSSKSS...",
    "...SSSSSSSSSS...",
    "...KK......KK...",
    "..KKK......KKK..",
    "................"
  ];

  static const List<String> _pixelArtGoombaSquish = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "..NNNNNNNNNNNN..",
    ".NNNNNNNNNNNNNN.",
    "NNKKNNNNNNKKNNNN",
    ".KKKK......KKKK.",
    "................",
    "................",
    "................"
  ];

  static const List<String> _pixelArtTurtle1 = [
    "................",
    "......GGGG......",
    "....GGGGGGGG....",
    "...GGSSSSSSGG...",
    "...GGSSKKSSGG...",
    "..GGGGSSSSSSGG..",
    "..GWWGGGGGGG....",
    ".GWWWWGGGGG.....",
    "..GWWGGGG.......",
    "....YY..YY......",
    "....Y....Y......",
    "................"
  ];

  static const List<String> _pixelArtTurtle2 = [
    "................",
    "......GGGG......",
    "....GGGGGGGG....",
    "...GGSSSSSSGG...",
    "...GGSSKKSSGG...",
    "..GGGGSSSSSSGG..",
    "..GWWGGGGGGG....",
    ".GWWWWGGGGG.....",
    "..GWWGGGG.......",
    ".....YY.YY......",
    "......Y..Y......",
    "................"
  ];

  static const List<String> _pixelArtShell = [
    "................",
    "................",
    "......GGGG......",
    "....GGGGGGGG....",
    "...GGGGGGGGGG...",
    "..GGGGGGGGGGGG..",
    "..GGGGGGGGGGGG..",
    "...WWWWWWWWWW...",
    "................",
    "................",
    "................"
  ];

  static const List<String> _pixelArtPlantClosed = [
    "......WWWW......",
    "....WWRRRRWW....",
    "...WRRRRRRRRW...",
    "..WRRWWRRRRWWR..",
    "..WRWWWRRRWWWR..",
    "..WRRRRRRRRRWR..",
    "...WRRRRRRRRW...",
    "....WWRRRRWW....",
    "......WWWW......",
    ".......GG.......",
    "......GGGG......",
    ".....GGGGGG.....",
    ".......GG.......",
    ".......GG......."
  ];

  static const List<String> _pixelArtPlantOpen = [
    "...W........W...",
    "..WWR......RWW..",
    "..WRRWW..WWRRW..",
    "..WRRRWWWWRRRW..",
    "...WRRRRRRRRW...",
    "...WWRRRRRRWW...",
    "....WWRRRRWW....",
    "......WWWW......",
    ".......GG.......",
    "......GGGG......",
    ".....GGGGGG.....",
    ".......GG.......",
    ".......GG.......",
    ".......GG......."
  ];

  @override
  bool shouldRepaint(covariant _RunnerPainter oldDelegate) => true;
}

// ==========================================
// RIGHT SIDE: 3D SPATIAL ROOM
// ==========================================
class _SpatialRoomSide extends StatefulWidget {
  const _SpatialRoomSide();

  @override
  State<_SpatialRoomSide> createState() => _SpatialRoomSideState();
}

class _SpatialRoomSideState extends State<_SpatialRoomSide> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final ValueNotifier<double> _timeNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Offset> _mouseNotifier = ValueNotifier<Offset>(Offset.zero);

  double _rawTime = 0.0;
  double _targetSpeed = 1.0;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      _currentSpeed += (_targetSpeed - _currentSpeed) * 0.08;
      _rawTime += 0.012 * _currentSpeed;
      _timeNotifier.value = _rawTime;
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timeNotifier.dispose();
    _mouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return MouseRegion(
            hitTestBehavior: HitTestBehavior.opaque,
            onHover: (e) {
              _mouseNotifier.value = Offset(
                (e.localPosition.dx / constraints.maxWidth) * 2 - 1,
                (e.localPosition.dy / constraints.maxHeight) * 2 - 1,
              );
              _targetSpeed = 3.0;
            },
            onExit: (_) {
              _mouseNotifier.value = Offset.zero;
              _targetSpeed = 1.0;
            },
            child: ValueListenableBuilder<Offset>(
              valueListenable: _mouseNotifier,
              builder: (context, mouseOffset, staticRoomChild) {
                return TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(begin: Offset.zero, end: mouseOffset),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCirc,
                  builder: (context, currentOffset, child) {
                    final matrix = Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(-currentOffset.dy * 0.15)
                      ..rotateY(currentOffset.dx * 0.25);

                    return Container(
                      color: const Color(0xFF070A10),
                      child: Center(
                        child: Transform(
                          transform: matrix,
                          alignment: Alignment.center,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildFloor(),
                      _buildBackWall(),
                      ValueListenableBuilder<double>(
                        valueListenable: _timeNotifier,
                        builder: (context, time, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildWarpBeams(time),
                              _buildDepthSortedCarousel(time),
                            ],
                          );
                        },
                      ),
                      _buildForegroundButton(),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloor() {
    return Transform(
      transform: Matrix4.identity()..translateByDouble(0.0, 250.0, -100.0, 1.0)..rotateX(math.pi / 2.2),
      alignment: Alignment.center,
      child: Container(
        width: 1000,
        height: 1000,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.cyanAccent.withAlpha(25), Colors.transparent],
            stops: const [0.1, 0.8],
          ),
        ),
        child: CustomPaint(painter: _PerspectiveGridPainter(Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildBackWall() {
    return Transform(
      transform: Matrix4.identity()..translateByDouble(0.0, -40.0, -250.0, 1.0),
      alignment: Alignment.center,
      child: Container(
        width: 800,
        height: 500,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withAlpha(150),
          border: Border.all(color: Colors.cyanAccent.withAlpha(30), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(painter: _PerspectiveGridPainter(Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildWarpBeams(double time) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(painter: _WarpSpeedPainter(time)),
    );
  }

  Widget _buildDepthSortedCarousel(double time) {
    const double radius = 175.0;
    final cards = [
      _CarouselItemData(badge: 'EXPERIENCE', title: '2.5 YRS APP DEV', icon: Icons.code, color: Colors.cyanAccent),
      _CarouselItemData(badge: 'TECH_STACK', title: 'FLUTTER / FLASK / SQL', icon: Icons.layers, color: Colors.purpleAccent),
      _CarouselItemData(badge: 'STATUS', title: 'OPEN TO RELOCATE', icon: Icons.flight_takeoff, color: Colors.greenAccent),
    ];

    final renderedCards = List.generate(cards.length, (i) {
      final double baseAngle = (i / cards.length) * 2 * math.pi;
      final double currentAngle = (baseAngle + time * 0.8) % (2 * math.pi);
      final double x = math.sin(currentAngle) * radius;
      final double z = math.cos(currentAngle) * radius;
      return _PositionedCard(data: cards[i], x: x, z: z, angle: currentAngle);
    })..sort((a, b) => b.z.compareTo(a.z));

    return Stack(
      alignment: Alignment.center,
      children: renderedCards.map((card) {
        final double normalizedZ = (radius - card.z) / (2 * radius);
        final double scale = 0.75 + (0.25 * normalizedZ);
        final double opacity = (0.40 + (0.60 * normalizedZ)).clamp(0.0, 1.0);

        return Transform(
          key: ValueKey(card.data.title),
          transform: Matrix4.identity()..translateByDouble(card.x, -40.0, card.z, 1.0)..scaleByDouble(scale, scale, scale, 1.0),
          alignment: Alignment.center,
          child: _buildCardContent(card.data, opacity),
        );
      }).toList(),
    );
  }

  Widget _buildCardContent(_CarouselItemData data, double opacity) {
    return Container(
      width: 190,
      height: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha((235 * opacity).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withAlpha((120 * opacity).toInt()), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.badge, style: TextStyle(color: Colors.white54.withValues(alpha: opacity * 0.54), fontSize: 9, fontFamily: 'monospace')),
              Icon(data.icon, size: 15, color: data.color.withValues(alpha: opacity)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.title, style: TextStyle(color: Colors.white.withValues(alpha: opacity), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 6),
          Container(height: 2, width: 36, decoration: BoxDecoration(gradient: LinearGradient(colors: [data.color.withValues(alpha: opacity), Colors.transparent]))),
        ],
      ),
    );
  }

  Widget _buildForegroundButton() {
    return Transform(
      transform: Matrix4.identity()..translateByDouble(0.0, 115.0, 120.0, 1.0),
      alignment: Alignment.center,
      child: _Cyber3DButton(
        text: 'ENTER 2D ROOM ▶',
        onTap: () => context.go('/isometric'),
      ),
    );
  }
}

class _CarouselItemData {
  final String badge;
  final String title;
  final IconData icon;
  final Color color;
  _CarouselItemData({required this.badge, required this.title, required this.icon, required this.color});
}

class _PositionedCard {
  final _CarouselItemData data;
  final double x;
  final double z;
  final double angle;
  _PositionedCard({required this.data, required this.x, required this.z, required this.angle});
}

class _RetroGraphPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF000000).withAlpha(15)..strokeWidth = 1.0;
    const double step = 32.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WarpSpeedPainter extends CustomPainter {
  final double time;
  _WarpSpeedPainter(this.time);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2.0;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 36; i++) {
      double rx = math.sin(i * 345.2) * 1100;
      double ry = math.cos(i * 832.1) * 1100;
      double initialZ = (math.sin(i * 123.4) * 0.5 + 0.5) * 1000;
      double z = 1000 - ((initialZ + time * 1100) % 1000);
      if (z < 10) continue;
      double scale = 300 / z;
      double px = center.dx + rx * scale;
      double py = center.dy + ry * scale;
      double zBack = z + 140;
      double scaleBack = 300 / zBack;
      double pxBack = center.dx + rx * scaleBack;
      double pyBack = center.dy + ry * scaleBack;
      paint.color = Colors.cyanAccent.withAlpha((255 * (1 - (z / 1000))).clamp(0, 255).toInt());
      canvas.drawLine(Offset(pxBack, pyBack), Offset(px, py), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _WarpSpeedPainter oldDelegate) => true;
}

class _PerspectiveGridPainter extends CustomPainter {
  final Color gridColor;
  _PerspectiveGridPainter(this.gridColor);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = gridColor.withAlpha(30)..strokeWidth = 2.0;
    const double step = 50.0;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Cyber3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _Cyber3DButton({required this.text, required this.onTap});
  @override
  State<_Cyber3DButton> createState() => _Cyber3DButtonState();
}

class _Cyber3DButtonState extends State<_Cyber3DButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    final double depth = _isPressed ? 0 : (_isHovered ? 6 : 12);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: SizedBox(
          width: 240,
          height: 60 + 12,
          child: Stack(
            children: [
              Positioned(
                bottom: 0, left: 0, right: 0, height: 60,
                child: Container(decoration: BoxDecoration(color: const Color(0xFF008080), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.cyanAccent.withAlpha(100), width: 2))),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                bottom: depth, left: 0, right: 0, height: 60,
                child: Container(
                  decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.cyanAccent.withAlpha(80), blurRadius: 15)]),
                  child: Center(child: Text(widget.text, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoBrutalistCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _NeoBrutalistCard({required this.child, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: child,
    );
  }
}

class _NeoBrutalistButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _NeoBrutalistButton({required this.text, required this.color, required this.textColor, required this.onTap});
  @override
  State<_NeoBrutalistButton> createState() => _NeoBrutalistButtonState();
}

class _NeoBrutalistButtonState extends State<_NeoBrutalistButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    final double offset = _isPressed ? 0 : (_isHovered ? 4 : 8);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) { setState(() => _isPressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(_isPressed ? 8 : (_isHovered ? 4 : 0), _isPressed ? 8 : (_isHovered ? 4 : 0), 0),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: widget.color, border: Border.all(color: Colors.black, width: 4), boxShadow: [BoxShadow(color: Colors.black, offset: Offset(offset, offset))]),
          child: Center(child: Text(widget.text, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5))),
        ),
      ),
    );
  }
}