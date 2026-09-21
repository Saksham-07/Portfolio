import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ==========================================
// 1. DATA MODEL
// ==========================================
class ShapeData {
  double x, y;
  double vx, vy;
  double angle;
  final double vAngle;
  final int type;
  final Color color;
  final double radius = 22.0;

  bool isDragged = false;
  bool isStuck = false;
  Offset stuckOffset = Offset.zero;

  ShapeData({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.vAngle,
    required this.type,
    required this.color,
  });
}

// ==========================================
// 2. PHYSICS ENGINE (KATAMARI + EXPLOSION)
// ==========================================
class PhysicsEngine extends ChangeNotifier {
  final List<ShapeData> shapes = [];
  Size _bounds = Size.zero;
  bool _isInitialized = false;

  ShapeData? rootDraggedShape;

  void initialize(Size size) {
    if (_isInitialized || size.isEmpty) return;
    _bounds = size;

    final rand = math.Random(1995);
    final colors = [
      const Color(0xFF90CDF4),
      const Color(0xFFFFB6B9),
      const Color(0xFF68D391),
      const Color(0xFFF6E05E),
    ];

    for (int i = 0; i < 25; i++) {
      shapes.add(
        ShapeData(
          x: rand.nextDouble() * (_bounds.width > 100 ? _bounds.width - 100 : 500) + 50,
          y: rand.nextDouble() * (_bounds.height > 100 ? _bounds.height - 100 : 500) + 50,
          vx: (rand.nextDouble() * 0.6 + 0.2) * (rand.nextBool() ? 1 : -1),
          vy: (rand.nextDouble() * 0.6 + 0.2) * (rand.nextBool() ? 1 : -1),
          angle: rand.nextDouble() * math.pi * 2,
          vAngle: (rand.nextDouble() * 0.015 + 0.005) * (rand.nextBool() ? 1 : -1),
          type: rand.nextInt(6),
          color: colors[rand.nextInt(colors.length)],
        ),
      );
    }
    _isInitialized = true;
  }

  void updateBounds(Size size) => _bounds = size;

  void startDrag(ShapeData s) {
    rootDraggedShape = s;
    s.isDragged = true;
    s.vx = 0;
    s.vy = 0;
  }

  void releaseDrag(double throwVx, double throwVy) {
    if (rootDraggedShape == null) return;

    final rootX = rootDraggedShape!.x;
    final rootY = rootDraggedShape!.y;

    // The outward burst velocity applied to every piece of the clump
    const double explosionForce = 18.0;

    for (var s in shapes) {
      if (s.isDragged || s.isStuck) {
        s.isDragged = false;
        s.isStuck = false;

        // Calculate outward direction from the center of the clump
        double dx = s.x - rootX;
        double dy = s.y - rootY;

        // If it's the center piece, give it a tiny random scatter so it doesn't just drop dead
        if (dx == 0 && dy == 0) {
          dx = (math.Random().nextDouble() - 0.5);
          dy = (math.Random().nextDouble() - 0.5);
        }

        // Normalize the vector
        final dist = math.sqrt(dx * dx + dy * dy);
        final nx = dx / dist;
        final ny = dy / dist;

        // Combine the user's throw velocity with the outward explosion burst
        s.vx = throwVx + (nx * explosionForce);
        s.vy = throwVy + (ny * explosionForce);
      }
    }

    rootDraggedShape = null;
    notifyListeners();
  }

  void tick() {
    if (!_isInitialized || _bounds.isEmpty) return;

    final width = _bounds.width;
    final height = _bounds.height;

    const double maxIdleSpeedSq = 1.0;
    const double friction = 0.97;

    for (int i = 0; i < shapes.length; i++) {
      final s = shapes[i];

      if (s.isStuck && rootDraggedShape != null) {
        s.x = rootDraggedShape!.x + s.stuckOffset.dx;
        s.y = rootDraggedShape!.y + s.stuckOffset.dy;
      }
      else if (!s.isDragged) {
        s.x += s.vx;
        s.y += s.vy;

        final currentSpeedSq = (s.vx * s.vx) + (s.vy * s.vy);
        if (currentSpeedSq > maxIdleSpeedSq) {
          s.vx *= friction;
          s.vy *= friction;
        }
      }

      s.angle += s.vAngle;

      if (!s.isDragged && !s.isStuck) {
        if (s.x - s.radius < 0) {
          s.x = s.radius;
          s.vx = s.vx.abs();
        } else if (s.x + s.radius > width) {
          s.x = width - s.radius;
          s.vx = -s.vx.abs();
        }

        if (s.y - s.radius < 0) {
          s.y = s.radius;
          s.vy = s.vy.abs();
        } else if (s.y + s.radius > height) {
          s.y = height - s.radius;
          s.vy = -s.vy.abs();
        }
      }
    }

    for (int i = 0; i < shapes.length; i++) {
      for (int j = i + 1; j < shapes.length; j++) {
        final s = shapes[i];
        final s2 = shapes[j];

        final dx = s2.x - s.x;
        final dy = s2.y - s.y;
        final distSq = (dx * dx) + (dy * dy);
        final minDist = s.radius + s2.radius;
        final minDistSq = minDist * minDist;

        if (distSq < minDistSq && distSq > 0) {
          bool s1Active = s.isDragged || s.isStuck;
          bool s2Active = s2.isDragged || s2.isStuck;

          if (s1Active && !s2Active && rootDraggedShape != null) {
            s2.isStuck = true;
            s2.stuckOffset = Offset(s2.x - rootDraggedShape!.x, s2.y - rootDraggedShape!.y);
            continue;
          } else if (s2Active && !s1Active && rootDraggedShape != null) {
            s.isStuck = true;
            s.stuckOffset = Offset(s.x - rootDraggedShape!.x, s.y - rootDraggedShape!.y);
            continue;
          }

          if (s1Active && s2Active) {
            continue;
          }

          final dist = math.sqrt(distSq);
          final overlap = minDist - dist;
          final nx = dx / dist;
          final ny = dy / dist;

          s.x -= nx * overlap * 0.5;
          s2.x += nx * overlap * 0.5;

          final kx = s.vx - s2.vx;
          final ky = s.vy - s2.vy;
          final p = (nx * kx + ny * ky);

          s.vx -= p * nx;
          s.vy -= p * ny;
          s2.vx += p * nx;
          s2.vy += p * ny;
        }
      }
    }
    notifyListeners();
  }
}

// ==========================================
// 3. WIDGET CONTROLLER
// ==========================================
class AnimatedMemphisBackground extends StatefulWidget {
  const AnimatedMemphisBackground({super.key});

  @override
  State<AnimatedMemphisBackground> createState() => _AnimatedMemphisBackgroundState();
}

class _AnimatedMemphisBackgroundState extends State<AnimatedMemphisBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final PhysicsEngine _engine = PhysicsEngine();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _engine.tick())..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _engine.initialize(constraints.biggest);
        _engine.updateBounds(constraints.biggest);

        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _StaticGridPainter(),
                size: Size.infinite,
              ),
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) {
                for (final s in _engine.shapes) {
                  final dx = s.x - details.localPosition.dx;
                  final dy = s.y - details.localPosition.dy;
                  if ((dx * dx + dy * dy) <= (s.radius * 2.5) * (s.radius * 2.5)) {
                    _engine.startDrag(s);
                    break;
                  }
                }
              },
              onPanUpdate: (details) {
                if (_engine.rootDraggedShape != null) {
                  _engine.rootDraggedShape!.x = details.localPosition.dx;
                  _engine.rootDraggedShape!.y = details.localPosition.dy;
                }
              },
              onPanEnd: (details) {
                if (_engine.rootDraggedShape != null) {
                  final vx = (details.velocity.pixelsPerSecond.dx / 60).clamp(-30.0, 30.0);
                  final vy = (details.velocity.pixelsPerSecond.dy / 60).clamp(-30.0, 30.0);
                  _engine.releaseDrag(vx, vy);
                }
              },
              onPanCancel: () {
                if (_engine.rootDraggedShape != null) {
                  _engine.releaseDrag(0, 0);
                }
              },
              child: AnimatedBuilder(
                animation: _engine,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DynamicShapesPainter(_engine.shapes),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// 4. BATCH GPU PAINTER (STATIC GRID)
// ==========================================
class _StaticGridPainter extends CustomPainter {
  List<Offset>? _cachedPoints;

  final Paint dotPaint = Paint()
    ..color = const Color(0xFF000000).withAlpha(15)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPoints == null) {
      _cachedPoints = [];
      const double dotSpacing = 24.0;
      for (double i = 0; i < size.width; i += dotSpacing) {
        for (double j = 0; j < size.height; j += dotSpacing) {
          _cachedPoints!.add(Offset(i, j));
        }
      }
    }
    canvas.drawPoints(PointMode.points, _cachedPoints!, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 5. CACHED SHAPES PAINTER (DYNAMIC LOOP)
// ==========================================
class _DynamicShapesPainter extends CustomPainter {
  final List<ShapeData> shapes;

  static final Paint strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeJoin = StrokeJoin.miter;

  static final Paint fillPaint = Paint()..style = PaintingStyle.fill;

  _DynamicShapesPainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      fillPaint.color = s.color;

      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.angle);

      if (s.isDragged || s.isStuck) {
        canvas.scale(1.15);
      }

      switch (s.type) {
        case 0:
          canvas.drawCircle(Offset.zero, 14, fillPaint);
          canvas.drawCircle(Offset.zero, 14, strokePaint);
          break;
        case 1:
          final rect = Rect.fromCenter(center: Offset.zero, width: 24, height: 24);
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, strokePaint);
          break;
        case 2:
          final path = Path()..moveTo(0, -16)..lineTo(16, 12)..lineTo(-16, 12)..close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
          break;
        case 3:
          strokePaint.strokeWidth = 6;
          canvas.drawLine(const Offset(-14, 0), const Offset(14, 0), strokePaint);
          canvas.drawLine(const Offset(0, -14), const Offset(0, 14), strokePaint);
          strokePaint.strokeWidth = 3.5;
          break;
        case 4:
          final path = Path()..moveTo(-20, -10)..lineTo(-10, 10)..lineTo(0, -10)..lineTo(10, 10)..lineTo(20, -10);
          strokePaint.strokeWidth = 4;
          canvas.drawPath(path, strokePaint);
          strokePaint.strokeWidth = 3.5;
          break;
        case 5:
          final path = Path()..moveTo(-12, -12)..lineTo(-20, 0)..lineTo(-12, 12)..moveTo(12, -12)..lineTo(20, 0)..lineTo(12, 12);
          strokePaint.strokeWidth = 4;
          canvas.drawPath(path, strokePaint);
          strokePaint.strokeWidth = 3.5;
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicShapesPainter oldDelegate) => true;
}