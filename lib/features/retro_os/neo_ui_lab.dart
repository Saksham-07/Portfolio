import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// UI_LAB.EXE — a small gallery of interactive widgets rebuilt from components
/// I shipped in PPMS (production garment-ERP app), restyled for this retro OS.
class NeoUiLab extends StatefulWidget {
  const NeoUiLab({super.key});

  @override
  State<NeoUiLab> createState() => _NeoUiLabState();
}

class _LabDemo {
  final String tab;
  final String title;
  final String blurb;
  final String caption;
  final Color color;
  final WidgetBuilder builder;

  const _LabDemo({
    required this.tab,
    required this.title,
    required this.blurb,
    required this.caption,
    required this.color,
    required this.builder,
  });
}

class _NeoUiLabState extends State<NeoUiLab> {
  int _selected = 0;

  static final List<_LabDemo> _demos = [
    _LabDemo(
      tab: 'KPI WHEEL',
      title: 'KPI WHEEL',
      blurb: 'Tap a segment to switch metrics',
      caption: 'A custom-painted rotary switcher from a real Budget vs Actual dashboard — no chart libraries, just '
          'Canvas.drawArc, atan2 touch mapping, and an elastic snap animation.',
      color: Color(0xFF90CDF4),
      builder: _buildKpiWheel,
    ),
    _LabDemo(
      tab: 'TILE BURST',
      title: 'TILE BURST',
      blurb: 'Tap a module tile to launch it',
      caption: 'The PPMS main-menu transition: the tapped tile inflates to fill the screen, holds the module title, '
          'then rips away in horizontal strips under a gravity curve to reveal the page underneath.',
      color: Color(0xFFB794F4),
      builder: _buildTileBurst,
    ),
    _LabDemo(
      tab: 'GLASS TILE',
      title: 'GLASS TILE',
      blurb: 'Press a tile — then hit REPLAY',
      caption: 'Frosted menu tiles built on BackdropFilter, with a staggered fade + slide + scale entrance and a '
          'press-down rebound. Used for the PPMS home grid over a photographic background.',
      color: Color(0xFF68D391),
      builder: _buildGlassTile,
    ),
    _LabDemo(
      tab: 'GLOW TRACE',
      title: 'GLOW TRACE',
      blurb: 'A light source running the letterforms',
      caption: 'The animated PPMS wordmark: letters are hand-built Bezier paths, and a glowing segment is extracted '
          'from each PathMetric every frame to chase the outline.',
      color: Color(0xFFF6E05E),
      builder: _buildGlowTrace,
    ),
    _LabDemo(
      tab: 'HANG TAG',
      title: 'HANG TAG',
      blurb: 'Tap a tag to swing it',
      caption: 'A menu concept themed after garment hang tags — chamfered corners via a custom clipper, dashed '
          'cut-lines, and a pendulum where a longer string genuinely swings slower.',
      color: Color(0xFFFFB6B9),
      builder: _buildHangTag,
    ),
  ];

  static Widget _buildKpiWheel(BuildContext c) => const _KpiWheelDemo();
  static Widget _buildTileBurst(BuildContext c) => const _TileBurstDemo();
  static Widget _buildGlassTile(BuildContext c) => const _GlassTileDemo();
  static Widget _buildGlowTrace(BuildContext c) => const _GlowTraceDemo();
  static Widget _buildHangTag(BuildContext c) => const _HangTagDemo();

  @override
  Widget build(BuildContext context) {
    final demo = _demos[_selected];

    return Container(
      color: const Color(0xFFF4EFE6),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(demo),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 20),
            Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
              ),
              child: ClipRect(child: demo.builder(context)),
            ),
            const SizedBox(height: 24),
            _buildCaption(demo.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_LabDemo demo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6E05E),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
              ),
              child: const Text('LIVE DEMO',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(color: Colors.black),
                child: const Text('REBUILT FROM PRODUCTION CODE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(demo.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(demo.blurb,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_demos.length, (i) {
          final bool active = i == _selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _demos[i].color : Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black, offset: active ? const Offset(4, 4) : const Offset(2, 2)),
                  ],
                ),
                child: Text(
                  _demos[i].tab,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'monospace', letterSpacing: 0.5),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCaption(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------
// 1. KPI WHEEL
// ---------------------------------------------------------
class _KpiWheelDemo extends StatefulWidget {
  const _KpiWheelDemo();

  @override
  State<_KpiWheelDemo> createState() => _KpiWheelDemoState();
}

class _KpiWheelDemoState extends State<_KpiWheelDemo> with SingleTickerProviderStateMixin {
  late AnimationController _wheelController;
  double _wheelRotation = -math.pi / 2 - (2 * (2 * math.pi / 3));
  int _selectedSegment = 2;

  final List<String> _segments = ['Booked\nMargin', 'Actual\nMargin', 'Net\nMargin'];
  final List<Color> _segColors = [const Color(0xFF90CDF4), const Color(0xFFFFB6B9), const Color(0xFF68D391)];
  final List<String> _segValues = ['₹213 L', '₹25 L', '₹12 L'];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _selectSegment(2);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  void _selectSegment(int index) {
    setState(() => _selectedSegment = index);
    const double segmentAngle = 2 * math.pi / 3;
    const double halfSegment = segmentAngle / 2;
    final double target = -math.pi / 2 - (index * segmentAngle) - halfSegment;

    final Animation<double> animation = Tween<double>(begin: _wheelRotation, end: target).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.elasticOut),
    );
    animation.addListener(() => setState(() => _wheelRotation = animation.value));
    _wheelController.reset();
    _wheelController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double s = math.min(constraints.maxWidth, constraints.maxHeight) * 0.78;
        s = s.clamp(150.0, 300.0);
        return Center(child: _buildInteractiveWheel(s));
      },
    );
  }

  Widget _buildInteractiveWheel(double s) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        final Offset local = details.localPosition;
        final double dx = local.dx - s / 2;
        final double dy = local.dy - s / 2;
        final double distance = math.sqrt(dx * dx + dy * dy);

        if (distance > s * 0.22 && distance < s * 0.52) {
          double angle = math.atan2(dy, dx);
          if (angle < 0) angle += 2 * math.pi;
          final double effective = (angle - _wheelRotation) % (2 * math.pi);
          final int tapped = (effective / (2 * math.pi / 3)).floor();
          _selectSegment(tapped);
        } else {
          _selectSegment(2);
        }
      },
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _wheelController,
              builder: (_, _) => CustomPaint(
                size: Size(s, s),
                painter: RoulettePainter(
                  rotation: _wheelRotation,
                  selected: _selectedSegment,
                  colors: _segColors,
                  labels: _segments,
                  values: _segValues,
                ),
              ),
            ),
            Center(
              child: Container(
                width: s * 0.38,
                height: s * 0.38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                ),
                child: Center(
                  child: Text(
                    _segValues[_selectedSegment],
                    style: TextStyle(fontSize: s * 0.09, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoulettePainter extends CustomPainter {
  final double rotation;
  final int selected;
  final List<Color> colors;
  final List<String> labels;
  final List<String> values;

  RoulettePainter(
      {required this.rotation,
      required this.selected,
      required this.colors,
      required this.labels,
      required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;
    const sweep = 2 * math.pi / 3;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      final startAngle = rotation + i * sweep;
      final isSelected = i == selected;
      final radius = isSelected ? baseRadius * 1.12 : baseRadius;
      final rect = Rect.fromCircle(center: center, radius: radius);

      final fillPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, fillPaint);
      canvas.drawArc(rect, startAngle, sweep, true, strokePaint);

      _drawCurvedText(canvas, labels[i].replaceAll('\n', ' '), center, radius * 0.84, startAngle, sweep,
          fontSize: radius * 0.16, isBold: true);
      _drawCurvedText(canvas, values[i], center, radius * 0.66, startAngle, sweep,
          fontSize: radius * 0.15, isBold: true);
    }
  }

  void _drawCurvedText(Canvas canvas, String text, Offset center, double radius, double startAngle, double sweepAngle,
      {required double fontSize, required bool isBold}) {
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    double currentAngle = startAngle + (sweepAngle / 2);
    double angleStep = 0.12;
    double startTextAngle = currentAngle - (text.length * angleStep) / 2;

    for (int i = 0; i < text.length; i++) {
      double charAngle = startTextAngle + (i * angleStep) + (angleStep / 2);
      textPainter.text = TextSpan(
          text: text[i],
          style: TextStyle(
              color: Colors.black, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal));
      textPainter.layout();

      double x = center.dx + radius * math.cos(charAngle);
      double y = center.dy + radius * math.sin(charAngle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(charAngle + math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RoulettePainter old) => true;
}

// ---------------------------------------------------------
// 2. TILE BURST
// ---------------------------------------------------------
class _BurstModule {
  final String title;
  final IconData icon;
  final Color color;
  const _BurstModule(this.title, this.icon, this.color);
}

class _TileBurstDemo extends StatefulWidget {
  const _TileBurstDemo();

  @override
  State<_TileBurstDemo> createState() => _TileBurstDemoState();
}

class _TileBurstDemoState extends State<_TileBurstDemo> with SingleTickerProviderStateMixin {
  static const List<_BurstModule> _modules = [
    _BurstModule('AUDIT', Icons.fact_check, Color(0xFFFFB6B9)),
    _BurstModule('GATE PASS', Icons.badge, Color(0xFF90CDF4)),
    _BurstModule('MARGIN', Icons.stacked_line_chart, Color(0xFF68D391)),
    _BurstModule('REPAIRS', Icons.build, Color(0xFFF6E05E)),
  ];

  late final AnimationController _controller;
  int? _active;
  Rect _originRect = Rect.zero;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _rectFor(int index, Size box) {
    const pad = 16.0;
    const gap = 12.0;
    final w = (box.width - pad * 2 - gap) / 2;
    final h = (box.height - pad * 2 - gap) / 2;
    final col = index % 2;
    final row = index ~/ 2;
    return Rect.fromLTWH(pad + col * (w + gap), pad + row * (h + gap), w, h);
  }

  void _launch(int index, Size box) {
    setState(() {
      _active = index;
      _originRect = _rectFor(index, box);
      _origin = _originRect.center;
    });
    _controller.forward(from: 0);
  }

  void _reset() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _active = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(child: _buildGrid(box)),
            if (_active != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => _buildBurst(box),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(Size box) {
    return Stack(
      children: List.generate(_modules.length, (i) {
        final r = _rectFor(i, box);
        final m = _modules[i];
        return Positioned.fromRect(
          rect: r,
          child: GestureDetector(
            onTap: () => _launch(i, box),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  color: m.color,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m.icon, size: 30, color: Colors.black),
                    const SizedBox(height: 8),
                    Text(m.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBurst(Size box) {
    final m = _modules[_active!];
    final t = _controller.value;

    // Phase 1 (0 → 0.25) inflate, Phase 2 (0.25 → 0.6) hold, Phase 3 (0.6 → 1) strips fall.
    final expand = Curves.easeInOutCubic.transform((t / 0.25).clamp(0.0, 1.0));
    final double textOpacity = ((t - 0.16) / 0.1).clamp(0.0, 1.0);

    Widget loadingScreen() => Container(
          color: m.color,
          width: box.width,
          height: box.height,
          child: Center(
            child: Opacity(
              opacity: textOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.icon, size: 44, color: Colors.black),
                  const SizedBox(height: 12),
                  Text(m.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        );

    const int stripCount = 14;

    return Stack(
      children: [
        // The "destination" revealed underneath.
        if (t > 0.25)
          Positioned.fill(
            child: GestureDetector(
              onTap: _reset,
              child: Container(
                color: const Color(0xFF1A1A1A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${m.title} MODULE',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: m.color,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Text('TAP TO GO BACK',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Phase 1: the tile inflating to fill the panel.
        if (t <= 0.25)
          Positioned(
            left: lerpDouble(_originRect.left, 0, expand)!,
            top: lerpDouble(_originRect.top, 0, expand)!,
            width: lerpDouble(_originRect.width, box.width, expand)!,
            height: lerpDouble(_originRect.height, box.height, expand)!,
            child: Container(
              decoration: BoxDecoration(
                color: m.color,
                borderRadius: BorderRadius.circular((1.0 - expand) * 8),
                border: Border.all(color: Colors.black, width: 3),
              ),
            ),
          ),
        // Phase 3: horizontal strips dropping away under gravity.
        if (t > 0.25)
          ...List.generate(stripCount, (index) {
            final stripHeight = box.height / stripCount;
            final startY = index * stripHeight;
            final stripStart = 0.6 + (index * 0.012);
            const stripSpan = 0.22;

            double fall = 0;
            if (t > stripStart) {
              fall = Curves.easeInCirc.transform(((t - stripStart) / stripSpan).clamp(0.0, 1.0));
            }

            return Positioned.fill(
              child: IgnorePointer(
                ignoring: fall > 0,
                child: Transform.translate(
                  offset: Offset(0, fall * box.height),
                  child: ClipRect(
                    clipper: _StripClipper(startY, stripHeight),
                    child: loadingScreen(),
                  ),
                ),
              ),
            );
          }),
        // Splash particles firing out of the tapped tile.
        if (t < 0.45)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SplatPainter(progress: (t / 0.45).clamp(0.0, 1.0), origin: _origin, color: m.color),
              ),
            ),
          ),
      ],
    );
  }
}

class _StripClipper extends CustomClipper<Rect> {
  final double startY;
  final double height;

  _StripClipper(this.startY, this.height);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, startY, size.width, height + 1.0);

  @override
  bool shouldReclip(covariant _StripClipper oldClipper) => true;
}

class _SplatPainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color color;

  _SplatPainter({required this.progress, required this.origin, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 1 - progress);

    const count = 10;
    final eased = Curves.easeOutCubic.transform(progress);
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final distance = eased * size.width * 0.45;
      final center = origin + Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final radius = (1 - progress) * 11 + 2;
      paint.color = color.withValues(alpha: 1 - progress);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_SplatPainter old) => true;
}

// ---------------------------------------------------------
// 3. GLASS TILE
// ---------------------------------------------------------
class _GlassTileDemo extends StatefulWidget {
  const _GlassTileDemo();

  @override
  State<_GlassTileDemo> createState() => _GlassTileDemoState();
}

class _GlassTileDemoState extends State<_GlassTileDemo> {
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    const items = [
      ['ORDERS', Icons.inventory_2],
      ['AUDIT', Icons.fact_check],
      ['PAYSLIP', Icons.receipt_long],
      ['LEAVE', Icons.event_available],
      ['GATE PASS', Icons.badge],
      ['REPAIRS', Icons.build],
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Something busy underneath so the frosting is actually visible.
        const _GlassBackdrop(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
          child: GridView.builder(
            key: ValueKey(_run),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _TintedGlassTile(
              title: items[i][0] as String,
              icon: items[i][1] as IconData,
              index: i,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: () => setState(() => _run++),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF68D391),
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
              ),
              child: const Text('REPLAY',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'monospace')),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF5A2A6B), Color(0xFF9B3B5A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(left: -30, top: -20, child: _blob(150, const Color(0xFF68D391))),
          Positioned(right: -40, top: 60, child: _blob(180, const Color(0xFFF6E05E))),
          Positioned(left: 60, bottom: -50, child: _blob(200, const Color(0xFF90CDF4))),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.55), shape: BoxShape.circle),
      );
}

class _TintedGlassTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final int index;

  const _TintedGlassTile({required this.title, required this.icon, required this.index});

  @override
  State<_TintedGlassTile> createState() => _TintedGlassTileState();
}

class _TintedGlassTileState extends State<_TintedGlassTile> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scaleIn;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.8, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _scaleIn = Tween<double>(begin: 0.86, end: 1.0)
        .animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scaleIn,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _pressed ? 0.28 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 26),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.4,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. GLOW TRACE
// ---------------------------------------------------------
class _GlowTraceDemo extends StatefulWidget {
  const _GlowTraceDemo();

  @override
  State<_GlowTraceDemo> createState() => _GlowTraceDemoState();
}

class _GlowTraceDemoState extends State<_GlowTraceDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: const Size(240, 70),
            painter: _WordmarkPainter(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  final double t;

  _WordmarkPainter(this.t);

  static final Paint _base = Paint()
    ..color = Colors.white.withValues(alpha: 0.15)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _glow = Paint()
    ..color = const Color(0xFFF6E05E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // P
    path.moveTo(0, h);
    path.lineTo(0, 0);
    path.quadraticBezierTo(w * 0.20, 0, w * 0.20, h * 0.25);
    path.quadraticBezierTo(w * 0.20, h * 0.5, 0, h * 0.5);

    // P
    path.moveTo(w * 0.25, h);
    path.lineTo(w * 0.25, 0);
    path.quadraticBezierTo(w * 0.45, 0, w * 0.45, h * 0.25);
    path.quadraticBezierTo(w * 0.45, h * 0.5, w * 0.25, h * 0.5);

    // M
    path.moveTo(w * 0.50, h);
    path.lineTo(w * 0.50, 0);
    path.lineTo(w * 0.625, h * 0.65);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w * 0.75, h);

    // S
    path.moveTo(w, h * 0.2);
    path.quadraticBezierTo(w, 0, w * 0.9, 0);
    path.quadraticBezierTo(w * 0.8, 0, w * 0.8, h * 0.25);
    path.quadraticBezierTo(w * 0.8, h * 0.5, w * 0.9, h * 0.5);
    path.quadraticBezierTo(w, h * 0.5, w, h * 0.75);
    path.quadraticBezierTo(w, h, w * 0.9, h);
    path.quadraticBezierTo(w * 0.8, h, w * 0.8, h * 0.8);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(path, _base);

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      final trail = length * 0.30;
      final start = (length * t) % length;
      final end = start + trail;

      if (end <= length) {
        canvas.drawPath(metric.extractPath(start, end), _glow);
      } else {
        canvas.drawPath(metric.extractPath(start, length), _glow);
        canvas.drawPath(metric.extractPath(0, end - length), _glow);
      }
    }
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.t != t;
}

// ---------------------------------------------------------
// 5. HANG TAG
// ---------------------------------------------------------
class _HangTagDemo extends StatelessWidget {
  const _HangTagDemo();

  @override
  Widget build(BuildContext context) {
    const tags = [
      ['SAMPLING', Color(0xFF90CDF4), 18.0, false],
      ['CUTTING', Color(0xFFF6E05E), 40.0, true],
      ['SEWING', Color(0xFFFFB6B9), 26.0, false],
      ['FINISHING', Color(0xFF68D391), 52.0, true],
      ['DISPATCH', Color(0xFFB794F4), 32.0, false],
    ];

    return Container(
      color: const Color(0xFF17171A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // The rail the tags hang from.
          Container(height: 4, color: const Color(0xFF6B6B70)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tag in tags)
                    _HangingTag(
                      title: tag[0] as String,
                      color: tag[1] as Color,
                      stringHeight: tag[2] as double,
                      dashed: tag[3] as bool,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HangingTag extends StatefulWidget {
  final String title;
  final Color color;
  final double stringHeight;
  final bool dashed;

  const _HangingTag({
    required this.title,
    required this.color,
    required this.stringHeight,
    required this.dashed,
  });

  @override
  State<_HangingTag> createState() => _HangingTagState();
}

class _HangingTagState extends State<_HangingTag> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _swing;

  @override
  void initState() {
    super.initState();
    // Longer string = slower pendulum, same as the real physics.
    final ms = 1200 + (widget.stringHeight * 30).toInt();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    _swing = Tween<double>(begin: -3.5, end: 3.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nudge() {
    _controller.stop();
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Container(width: 2, height: widget.stringHeight, color: const Color(0xFF8A8A90)),
          AnimatedBuilder(
            animation: _swing,
            builder: (context, child) => Transform.rotate(
              angle: _swing.value * math.pi / 180,
              alignment: Alignment.topCenter,
              child: child,
            ),
            child: GestureDetector(
              onTap: _nudge,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 92,
                  height: 132,
                  child: widget.dashed ? _dashedTag() : _solidTag(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _solidTag() {
    return ClipPath(
      clipper: _HangTagClipper(),
      child: Container(
        color: widget.color,
        child: _tagBody(Colors.black),
      ),
    );
  }

  Widget _dashedTag() {
    return CustomPaint(
      painter: _DashedTagPainter(),
      child: ClipPath(
        clipper: _HangTagClipper(),
        child: Container(
          color: Colors.white.withValues(alpha: 0.06),
          child: _tagBody(Colors.white),
        ),
      ),
    );
  }

  Widget _tagBody(Color ink) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Punch hole.
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF17171A),
              border: Border.all(color: ink.withValues(alpha: 0.5), width: 1.5),
            ),
          ),
          const Spacer(),
          Text(
            widget.title,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 28, color: ink.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

/// Chamfered top-left corner, like a real garment hang tag.
class _HangTagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const chamfer = 22.0;
    return Path()
      ..moveTo(chamfer, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, chamfer)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashedTagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _HangTagClipper().getClip(size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
