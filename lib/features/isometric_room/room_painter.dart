import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'room_models.dart';

/// Grid -> screen projection. `s` is half a tile's width in px.
class Iso {
  Iso(Size size) : s = _scale(size) {
    ox = size.width / 2;
    final usable = size.height - hudTop - hudBottom;
    oy = hudTop + (usable - (roomSize + wallHeight + slab) * s) / 2 + wallHeight * s;
  }
  static const hudTop = 58.0, hudBottom = 62.0, slab = 0.35;
  static double _scale(Size size) => math.max(
      1.0,
      math.min(size.width / (2 * roomSize + 1.4),
          (size.height - hudTop - hudBottom) / (roomSize + wallHeight + slab)));

  final double s;
  late final double ox, oy;

  Offset p(double x, double y, [double z = 0]) => Offset(ox + (x - y) * s, oy + (x + y) * s / 2 - z * s);
  Offset wall(Wall w, double u, double z) => w == Wall.left ? p(0, u, z) : p(u, 0, z);

  Offset toGrid(Offset px) {
    final a = (px.dx - ox) / s, b = (px.dy - oy) / (s / 2); // a = x-y, b = x+y
    return Offset((a + b) / 2, (b - a) / 2);
  }

  Rect partBounds(Part q) {
    final r = q.rect;
    return _bounds([
      for (final x in [r.left, r.right])
        for (final y in [r.top, r.bottom])
          for (final z in [q.z, q.top]) p(x, y, z)
    ]);
  }

  Rect propBounds(Prop o) => o.parts.map(partBounds).reduce((a, b) => a.expandToInclude(b));

  Rect doorBounds(Door d) =>
      _bounds([wall(d.wall, d.u, 0), wall(d.wall, d.u + d.w, 0), wall(d.wall, d.u, 2.4), wall(d.wall, d.u + d.w, 2.4)]);

  static Rect _bounds(List<Offset> pts) {
    var r = Rect.fromPoints(pts.first, pts.first);
    for (final q in pts.skip(1)) {
      r = r.expandToInclude(Rect.fromPoints(q, q));
    }
    return r;
  }
}

Color shade(Color c, double k) => k < 1 ? Color.lerp(c, Colors.black, 1 - k)! : Color.lerp(c, Colors.white, k - 1)!;

class _Item {
  _Item(this.rect, this.z0, this.z1, this.draw);
  final Rect rect;
  final double z0, z1;
  final VoidCallback draw;
}

const _bookColors = [0xFFB45F4F, 0xFF4F7A9B, 0xFFD8B26A, 0xFF5E8C6A, 0xFF7A6A9E, 0xFFC98B5A, 0xFFE8E2D4, 0xFF3F7F80];

class RoomPainter extends CustomPainter {
  RoomPainter(this.iso, this.room, this.pos, this.near, this.moving, this.t, {this.seat, this.sit = 0, this.playing, this.pose = const Pose(), this.say, this.sayAlpha = 1});
  final Iso iso;
  final RoomDef room;
  final Offset pos;
  final Prop? near;
  final bool moving;
  final double t;
  final Seat? seat; // the seat being used (if any)
  final double sit; // 0 = standing ... 1 = seated
  final Act? playing; // game currently being played (its kiosk screen shows a placeholder)
  final Pose pose; // lying / falling / tumbling animation state
  final String? say; // speech bubble over his head
  final double sayAlpha;

  static const _wt = 0.32; // wall thickness
  late Canvas c; // set at the start of every paint()
  bool _mir = false; // drawing the floor reflection (z is flipped)

  Color get _accent => room.accent;

  // ---- drawing helpers ----------------------------------------------------------

  Offset _p(double x, double y, [double z = 0]) => iso.p(x, y, _mir ? -z : z);
  Offset _w(Wall w, double u, double z) => iso.wall(w, u, z);
  Path _path(List<Offset> pts) => Path()..addPolygon(pts, true);
  List<Offset> _wq(Wall w, double u0, double z0, double u1, double z1) =>
      [_w(w, u0, z0), _w(w, u1, z0), _w(w, u1, z1), _w(w, u0, z1)];

  Color _a(Color col, double alpha) => col.withValues(alpha: alpha);

  void _fill(List<Offset> pts, Color col, [double alpha = 1]) => c.drawPath(_path(pts), Paint()..color = _a(col, alpha));

  ui.Gradient _lin(Offset a, Offset b, List<Color> colors, [List<double>? stops]) => ui.Gradient.linear(a, b, colors, stops);

  /// Additive soft glow: the "bloom" of a light source.
  void _bloom(Path path, Color col, double sigma, double alpha) {
    if (_mir) return;
    c.drawPath(
        path,
        Paint()
          ..color = _a(col, alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma)
          ..blendMode = BlendMode.plus);
  }

  /// A glowing LED line.
  void _led(Offset a, Offset b, Color col, {double width = 0, double glow = 1}) {
    final w = width > 0 ? width : math.max(1.5, iso.s * 0.045);
    if (!_mir) {
      c.drawLine(
          a,
          b,
          Paint()
            ..color = _a(col, 0.55 * glow)
            ..strokeWidth = w * 4
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, iso.s * 0.2)
            ..blendMode = BlendMode.plus);
    }
    c.drawLine(
        a,
        b,
        Paint()
          ..color = shade(col, 1.35)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  // ---- paint ----------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    _mir = false;
    _background(size);
    _slab();
    _floor();
    _wallAO();
    _walls();
    for (final d in room.decals) {
      _decal(d);
    }
    for (final d in room.doors) {
      _door(d);
    }
    _floorLight();
    final items = _sorted(_items());
    _reflections(items);
    _shadows();
    _rings();
    for (final i in items) {
      i.draw();
    }
    _labels();
    _speech(size);
  }

  void _background(Size size) {
    c.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = _lin(Offset.zero, Offset(0, size.height), const [Color(0xFF0B1020), Color(0xFF05070D)]));
    final ctr = Offset(iso.ox, iso.oy + roomSize * iso.s * 0.35);
    c.drawCircle(
        ctr,
        iso.s * 12,
        Paint()
          ..shader = ui.Gradient.radial(ctr, iso.s * 12, [_a(_accent, 0.22), _a(_accent, 0)]));
  }

  void _slab() {
    const th = Iso.slab, n = roomSize;
    // floating drop shadow
    final sh = _path([iso.p(0, 0, -th), iso.p(n, 0, -th), iso.p(n, n, -th), iso.p(0, n, -th)]).shift(Offset(0, iso.s * 0.9));
    c.drawPath(sh, Paint()..color = const Color(0x99000000)..maskFilter = MaskFilter.blur(BlurStyle.normal, iso.s * 0.7));
    final l = [iso.p(0, n), iso.p(n, n), iso.p(n, n, -th), iso.p(0, n, -th)];
    final r = [iso.p(n, 0), iso.p(n, n), iso.p(n, n, -th), iso.p(n, 0, -th)];
    c.drawPath(_path(l), Paint()..shader = _lin(l[0], l[3], const [Color(0xFF2A313C), Color(0xFF12161D)]));
    c.drawPath(_path(r), Paint()..shader = _lin(r[0], r[3], const [Color(0xFF1C222B), Color(0xFF0C0F14)]));
    _led(iso.p(0, n, -th + 0.06), iso.p(n, n, -th + 0.06), _accent, glow: 0.8);
    _led(iso.p(n, n, -th + 0.06), iso.p(n, 0, -th + 0.06), _accent, glow: 0.8);
    c.drawLine(iso.p(0, n), iso.p(n, n), Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1);
    c.drawLine(iso.p(n, n), iso.p(n, 0), Paint()..color = const Color(0x33FFFFFF)..strokeWidth = 1);
  }

  // ---- floor -------------------------------------------------------------------------

  Path get _floorPath => _path([iso.p(0, 0), iso.p(roomSize, 0), iso.p(roomSize, roomSize), iso.p(0, roomSize)]);

  void _floor() {
    const n = roomSize;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0x1F000000);
    switch (room.style) {
      case FloorStyle.wood:
        for (var i = 0; i < 16; i++) {
          final y0 = i * 0.5;
          final col = Color.lerp(room.floorA, room.floorB, ((i * 37) % 7) / 6)!;
          final quad = [iso.p(0, y0), iso.p(n, y0), iso.p(n, y0 + 0.5), iso.p(0, y0 + 0.5)];
          c.drawPath(_path(quad), Paint()..color = col);
          c.drawPath(_path(quad), line);
          final grain = Paint()
            ..color = _a(shade(col, 0.7), 0.16)
            ..strokeWidth = 0.6;
          for (final g in [0.14, 0.31, 0.42]) {
            c.drawLine(iso.p(0, y0 + g), iso.p(n, y0 + g), grain);
          }
          for (final cut in [(i * 3) % 5 + 1.2, (i * 3) % 5 + 4.4]) {
            c.drawLine(iso.p(cut, y0), iso.p(cut, y0 + 0.5), line);
          }
        }
      case FloorStyle.marble:
        for (var i = 0; i < 4; i++) {
          for (var j = 0; j < 4; j++) {
            final x0 = i * 2.0, y0 = j * 2.0;
            final quad = [iso.p(x0, y0), iso.p(x0 + 2, y0), iso.p(x0 + 2, y0 + 2), iso.p(x0, y0 + 2)];
            c.drawPath(_path(quad), Paint()..color = (i + j).isEven ? room.floorA : room.floorB);
            final vein = Paint()
              ..color = const Color(0x1A5A6472)
              ..strokeWidth = 1;
            for (var k = 0; k < 3; k++) {
              final a = ((i * 5 + j * 3 + k * 7) % 10) / 10 * 2, b = ((i * 3 + j * 7 + k * 5) % 10) / 10 * 2;
              c.drawLine(iso.p(x0 + a, y0), iso.p(x0 + 2, y0 + b), vein);
            }
            c.drawPath(_path(quad), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = const Color(0x2E000000));
          }
        }
      case FloorStyle.concrete:
        for (var i = 0; i < 4; i++) {
          for (var j = 0; j < 4; j++) {
            final x0 = i * 2.0, y0 = j * 2.0;
            final quad = [iso.p(x0, y0), iso.p(x0 + 2, y0), iso.p(x0 + 2, y0 + 2), iso.p(x0, y0 + 2)];
            c.drawPath(_path(quad), Paint()..color = Color.lerp(room.floorA, room.floorB, ((i * 3 + j * 5) % 4) / 3)!);
            c.drawPath(_path(quad), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x40000000));
          }
        }
        // glowing floor edge lines
        _led(iso.p(0.32, 0.32), iso.p(n, 0.32), _accent, glow: 0.6);
        _led(iso.p(0.32, 0.32), iso.p(0.32, n), _accent, glow: 0.6);
    }

    // rugs: soft layered borders with a fine weave
    for (final r in room.rugs) {
      for (final (inset, col) in [(0.0, r.a), (0.22, r.b), (0.42, r.a)]) {
        final q = r.rect.deflate(inset);
        c.drawPath(_path([iso.p(q.left, q.top), iso.p(q.right, q.top), iso.p(q.right, q.bottom), iso.p(q.left, q.bottom)]),
            Paint()..color = col);
      }
      final weave = Paint()
        ..color = const Color(0x12FFFFFF)
        ..strokeWidth = 0.6;
      for (var y = r.rect.top + 0.6; y < r.rect.bottom - 0.5; y += 0.3) {
        c.drawLine(iso.p(r.rect.left + 0.5, y), iso.p(r.rect.right - 0.5, y), weave);
      }
    }

    // polished-floor sheen + edge vignette
    final fp = _floorPath;
    c.drawPath(
        fp,
        Paint()
          ..shader = _lin(iso.p(0, 0), iso.p(n, n), const [Color(0x22FFFFFF), Color(0x00FFFFFF), Color(0x40000000)], const [0, 0.45, 1]));
    c.drawPath(
        fp,
        Paint()
          ..shader = _lin(iso.p(n, 0), iso.p(0, n), const [Color(0x18FFFFFF), Color(0x00FFFFFF)]));
  }

  /// Ambient occlusion where the floor meets the walls.
  void _wallAO() {
    const n = roomSize, d = 1.2;
    final l = [iso.p(0, 0), iso.p(d, 0), iso.p(d, n), iso.p(0, n)];
    c.drawPath(_path(l), Paint()..shader = _lin(iso.p(0, n / 2), iso.p(d, n / 2), const [Color(0x66000000), Color(0x00000000)]));
    final r = [iso.p(0, 0), iso.p(n, 0), iso.p(n, d), iso.p(0, d)];
    c.drawPath(_path(r), Paint()..shader = _lin(iso.p(n / 2, 0), iso.p(n / 2, d), const [Color(0x55000000), Color(0x00000000)]));
  }

  // ---- walls -----------------------------------------------------------------------

  void _walls() {
    const n = roomSize, h = wallHeight, wt = _wt;
    for (final left in [true, false]) {
      final quad = left
          ? [iso.p(0, 0, h), iso.p(0, n, h), iso.p(0, n), iso.p(0, 0)]
          : [iso.p(0, 0, h), iso.p(n, 0, h), iso.p(n, 0), iso.p(0, 0)];
      final base = left ? room.wallL : room.wallR;
      final mid = (quad[0] + quad[2]) / 2;
      c.drawPath(
          _path(quad),
          Paint()
            ..shader = _lin(Offset(mid.dx, iso.p(0, 0, h).dy), Offset(mid.dx, iso.p(n, n).dy),
                [shade(base, 1.12), base, shade(base, 0.7)], const [0, 0.5, 1]));
      // panel seams
      final seam = Paint()..color = const Color(0x22000000)..strokeWidth = 1;
      final hi = Paint()..color = const Color(0x10FFFFFF)..strokeWidth = 1;
      for (var u = 2.0; u < n; u += 2) {
        final a = left ? iso.p(0, u) : iso.p(u, 0), b = left ? iso.p(0, u, h) : iso.p(u, 0, h);
        c.drawLine(a, b, seam);
        c.drawLine(a.translate(1, 0), b.translate(1, 0), hi);
      }
      // LED cove wash from the top edge
      final w = left ? Wall.left : Wall.right;
      final wash = _wq(w, 0, h - 1.1, n, h);
      c.drawPath(_path(wash), Paint()..shader = _lin(_w(w, n / 2, h), _w(w, n / 2, h - 1.1), [_a(_accent, 0.26), _a(_accent, 0)]));
      // skirting board with a soft LED
      _fill(_wq(w, 0, 0, n, 0.15), const Color(0xFF0C0F14));
      _led(_w(w, 0, 0.17), _w(w, n, 0.17), _accent, width: math.max(1.2, iso.s * 0.03), glow: 0.5);
      _led(_w(w, 0, h - 0.09), _w(w, n, h - 0.09), _accent, width: math.max(1.2, iso.s * 0.03), glow: 0.7);
    }
    // wall thickness: brushed-aluminium caps and cut ends
    const cap = Color(0xFFD5DBE4);
    _fill([iso.p(-wt, -wt, h), iso.p(0, -wt, h), iso.p(0, n, h), iso.p(-wt, n, h)], cap);
    _fill([iso.p(0, -wt, h), iso.p(n, -wt, h), iso.p(n, 0, h), iso.p(0, 0, h)], shade(cap, 1.05));
    _fill([iso.p(-wt, n, h), iso.p(0, n, h), iso.p(0, n), iso.p(-wt, n)], const Color(0xFF8E97A5));
    _fill([iso.p(n, -wt, h), iso.p(n, 0, h), iso.p(n, 0), iso.p(n, -wt)], const Color(0xFF6C7482));
  }

  // ---- wall decals: windows, curtains, art ---------------------------------------------

  void _decal(Decal d) {
    final w = d.wall, u1 = d.u + d.w, z1 = d.z + d.h;
    switch (d.kind) {
      case DecalKind.window:
        _window(d);
      case DecalKind.curtain:
        // brushed rod + sheer pleats
        c.drawLine(_w(w, d.u - 0.06, z1 + 0.06), _w(w, u1 + 0.06, z1 + 0.06),
            Paint()..color = const Color(0xFFB4BCC8)..strokeWidth = math.max(2, iso.s * 0.07));
        const folds = 6;
        for (var i = 0; i < folds; i++) {
          final a = d.u + d.w * i / folds, b = d.u + d.w * (i + 1) / folds;
          final q = _wq(w, a, d.z, b, z1);
          final base = shade(d.c1, i.isEven ? 1.0 : 0.82);
          c.drawPath(_path(q), Paint()..shader = _lin(q[3], q[0], [_a(base, 0.62), _a(shade(base, 0.85), 0.42)]));
        }
      case DecalKind.painting:
        _art(d);
      case DecalKind.mirror:
        _fill(_wq(w, d.u - 0.07, d.z - 0.07, u1 + 0.07, z1 + 0.07), const Color(0xFFB08D57));
        final q = _wq(w, d.u, d.z, u1, z1);
        c.drawPath(_path(q), Paint()..shader = _lin(q[3], q[1], const [Color(0xFFDCE9F0), Color(0xFF8FA8B6)]));
        _fill([_w(w, d.u + d.w * 0.15, z1), _w(w, d.u + d.w * 0.42, z1), _w(w, d.u + d.w * 0.12, d.z), _w(w, d.u, d.z)], Colors.white, 0.35);
      case DecalKind.neon:
        _neon(d);
      case DecalKind.shelf:
        // board + a few objects, with a soft shadow underneath
        final shadow = _wq(w, d.u + 0.05, d.z - 0.16, u1, d.z);
        c.drawPath(_path(shadow), Paint()..shader = _lin(_w(w, d.u, d.z), _w(w, d.u, d.z - 0.16), const [Color(0x40000000), Color(0x00000000)]));
        for (var i = 0; i < 5; i++) {
          final bu = d.u + 0.1 + i * 0.1, bh = 0.2 + (i % 3) * 0.07;
          _fill(_wq(w, bu, d.z + 0.05, bu + 0.08, d.z + 0.05 + bh), Color(_bookColors[(i * 3 + d.u.floor()) % _bookColors.length]));
        }
        _fill(_wq(w, u1 - 0.32, d.z + 0.05, u1 - 0.2, d.z + 0.33), const Color(0xFFCFE3EA), 0.85);
        _fill(_wq(w, u1 - 0.5, d.z + 0.05, u1 - 0.4, d.z + 0.22), const Color(0xFFC2714F));
        _fill(_wq(w, d.u - 0.02, d.z, u1 + 0.02, d.z + 0.055), d.c1);
      case DecalKind.light:
        // wall sconce: emissive bar + soft up/down light cones
        final up = [_w(w, d.u - 0.02, z1), _w(w, d.u + d.w + 0.02, z1), _w(w, d.u + 0.6, z1 + 0.95), _w(w, d.u - 0.5, z1 + 0.95)];
        c.drawPath(_path(up), Paint()..shader = _lin(_w(w, d.u, z1), _w(w, d.u, z1 + 0.95), [_a(d.c1, 0.32), _a(d.c1, 0)]));
        final dn = [_w(w, d.u - 0.02, d.z), _w(w, d.u + d.w + 0.02, d.z), _w(w, d.u + 0.6, d.z - 0.95), _w(w, d.u - 0.5, d.z - 0.95)];
        c.drawPath(_path(dn), Paint()..shader = _lin(_w(w, d.u, d.z), _w(w, d.u, d.z - 0.95), [_a(d.c1, 0.32), _a(d.c1, 0)]));
        final bar = _wq(w, d.u, d.z, d.u + d.w, z1);
        _bloom(_path(bar), d.c1, iso.s * 0.35, 0.7);
        _fill(bar, shade(d.c1, 1.2));
    }
  }

  /// Floor-to-ceiling glass with a night skyline.
  void _window(Decal d) {
    final w = d.wall, u1 = d.u + d.w, z1 = d.z + d.h;
    _fill(_wq(w, d.u - 0.08, d.z - 0.06, u1 + 0.08, z1 + 0.06), const Color(0xFF0E1218));
    final glass = _wq(w, d.u, d.z, u1, z1);
    c.drawPath(
        _path(glass),
        Paint()
          ..shader = _lin(_w(w, d.u, z1), _w(w, d.u, d.z),
              const [Color(0xFF060A1C), Color(0xFF16204A), Color(0xFF4A3C7A), Color(0xFFE58A86)], const [0, 0.5, 0.82, 1]));
    // stars
    for (var i = 0; i < 16; i++) {
      final su = d.u + d.w * (((i * 37) % 97) / 97), sz = d.z + d.h * (0.5 + 0.48 * (((i * 53) % 89) / 89));
      c.drawCircle(_w(w, su, sz), 0.7 + (i % 3) * 0.3, Paint()..color = const Color(0xCCFFFFFF));
    }
    // moon
    final mu = d.u + d.w * 0.78, mz = d.z + d.h * 0.8;
    c.drawPath(_path([for (var a = 0; a < 20; a++) _w(w, mu + 0.14 * math.cos(a * math.pi / 10), mz + 0.14 * math.sin(a * math.pi / 10))]),
        Paint()..color = const Color(0xFFF3F1E6));
    // skyline: far layer with lit windows, near layer as silhouette
    const bldg = 11;
    for (final near in [false, true]) {
      for (var i = 0; i < bldg; i++) {
        final bw = d.w / bldg, bu = d.u + i * bw + (near ? bw * 0.5 : 0);
        final hh = d.h * ((near ? 0.1 : 0.16) + (((i * (near ? 31 : 53)) % 9) / 9) * (near ? 0.2 : 0.3));
        final u0 = bu + 0.02, uu1 = math.min(bu + bw - 0.02, u1);
        if (u0 >= uu1) continue;
        _fill(_wq(w, u0, d.z, uu1, d.z + hh), near ? const Color(0xFF080C1A) : const Color(0xFF131B3A));
        if (!near) {
          final rows = (hh / 0.2).floor();
          for (var r = 0; r < rows; r++) {
            for (var k = 0; k < 2; k++) {
              if ((i * 7 + r * 3 + k) % 3 == 0) continue;
              final wu = u0 + 0.05 + k * (uu1 - u0 - 0.14) / 1.4;
              final wz = d.z + 0.1 + r * 0.2;
              _fill(_wq(w, wu, wz, wu + 0.05, wz + 0.08), (i + r) % 4 == 0 ? const Color(0xFF7DD3FC) : const Color(0xFFFFD98A), 0.85);
            }
          }
        }
      }
    }
    // glass sheen + mullions
    _fill([_w(w, d.u, z1), _w(w, d.u + d.w * 0.4, z1), _w(w, d.u + d.w * 0.1, d.z), _w(w, d.u, d.z)], Colors.white, 0.06);
    _fill([_w(w, d.u + d.w * 0.55, z1), _w(w, d.u + d.w * 0.62, z1), _w(w, d.u + d.w * 0.32, d.z), _w(w, d.u + d.w * 0.25, d.z)], Colors.white, 0.05);
    final mull = Paint()..color = const Color(0xFF0E1218)..strokeWidth = math.max(2, iso.s * 0.06);
    c.drawLine(_w(w, d.u + d.w / 2, d.z), _w(w, d.u + d.w / 2, z1), mull);
    c.drawLine(_w(w, d.u, d.z + d.h * 0.62), _w(w, u1, d.z + d.h * 0.62), mull);
  }

  void _art(Decal d) {
    final w = d.wall, u1 = d.u + d.w, z1 = d.z + d.h;
    _fill(_wq(w, d.u - 0.06, d.z - 0.06, u1 + 0.06, z1 + 0.06), const Color(0xFF0B0E13));
    _fill(_wq(w, d.u - 0.02, d.z - 0.02, u1 + 0.02, z1 + 0.02), const Color(0xFFEDEAE3), 0.94);
    final q = _wq(w, d.u + 0.05, d.z + 0.05, u1 - 0.05, z1 - 0.05);
    c.drawPath(_path(q), Paint()..shader = _lin(q[3], q[1], [d.c1, shade(d.c1, 1.35)]));
    Path disc(double a, double zc, double r) => _path([
          for (var k = 0; k < 24; k++)
            _w(w, d.u + d.w * a + r * math.cos(k * math.pi / 12), d.z + d.h * zc + r * math.sin(k * math.pi / 12))
        ]);
    c.drawPath(disc(0.36, 0.58, d.h * 0.28), Paint()..color = _a(d.c2, 0.92));
    c.drawPath(disc(0.66, 0.42, d.h * 0.17), Paint()..color = _a(shade(d.c2, 1.4), 0.85));
    _fill(_wq(w, d.u + d.w * 0.12, d.z + d.h * 0.14, d.u + d.w * 0.88, d.z + d.h * 0.2), shade(d.c2, 0.75), 0.9);
  }

  void _neon(Decal d) {
    // text laid out in wall space: local x = along the wall, local y = down from the top of the sign
    const text = 'PLAY';
    final ux = d.wall == Wall.left ? Offset(-iso.s, iso.s / 2) : Offset(iso.s, iso.s / 2);
    final origin = _w(d.wall, d.u, d.z + d.h);
    TextPainter mk(Paint? fg) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 100 * d.h * 0.85,
              fontWeight: FontWeight.w300,
              letterSpacing: 18,
              color: fg == null ? Colors.white : null,
              foreground: fg,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final tp = mk(null);
    final glow = mk(Paint()..color = d.c1..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    final tube = mk(Paint()..color = shade(d.c1, 1.25)..style = PaintingStyle.stroke..strokeWidth = 2);
    final scale = d.w * 100 / tp.width;
    c.save();
    c.transform(Float64List.fromList([
      ux.dx / 100 * scale, ux.dy / 100 * scale, 0, 0, //
      0, iso.s / 100 * scale, 0, 0,
      0, 0, 1, 0,
      origin.dx, origin.dy, 0, 1,
    ]));
    glow.paint(c, Offset.zero);
    tube.paint(c, Offset.zero);
    tp.paint(c, Offset.zero);
    c.restore();
  }

  /// Glowing sliding-glass door to the next room.
  void _door(Door d) {
    final w = d.wall, u1 = d.u + d.w;
    _fill(_wq(w, d.u - 0.09, 0, u1 + 0.09, 2.5), const Color(0xFF0C1015));
    final glass = _wq(w, d.u, 0, u1, 2.4);
    c.drawPath(
        _path(glass),
        Paint()
          ..shader = _lin(_w(w, d.u, 2.4), _w(w, d.u, 0), [_a(shade(_accent, 0.5), 0.85), const Color(0xFF0E1822)]));
    _fill([_w(w, d.u, 2.4), _w(w, d.u + d.w * 0.4, 2.4), _w(w, d.u + d.w * 0.1, 0), _w(w, d.u, 0)], Colors.white, 0.08);
    final seam = Paint()..color = const Color(0xFF0C1015)..strokeWidth = math.max(2, iso.s * 0.05);
    c.drawLine(_w(w, d.u + d.w / 2, 0), _w(w, d.u + d.w / 2, 2.4), seam);
    _fill(_wq(w, d.u + d.w / 2 - 0.13, 0.95, d.u + d.w / 2 - 0.08, 1.55), const Color(0xFFB4BCC8));
    _fill(_wq(w, d.u + d.w / 2 + 0.08, 0.95, d.u + d.w / 2 + 0.13, 1.55), const Color(0xFFB4BCC8));
    _led(_w(w, u1 + 0.05, 0.05), _w(w, u1 + 0.05, 2.45), _accent);
    _led(_w(w, d.u - 0.05, 0.05), _w(w, d.u - 0.05, 2.45), _accent, glow: 0.6);
  }

  // ---- floor lighting ---------------------------------------------------------------

  void _floorLight() {
    // moonlight from windows
    for (final d in room.decals.where((d) => d.kind == DecalKind.window)) {
      const len = 3.6;
      final List<Offset> quad;
      final Offset a, b;
      if (d.wall == Wall.left) {
        quad = [iso.p(0, d.u), iso.p(0, d.u + d.w), iso.p(len, d.u + d.w + len * 0.4), iso.p(len, d.u + len * 0.4)];
        a = iso.p(0, d.u + d.w / 2);
        b = iso.p(len, d.u + d.w / 2 + len * 0.4);
      } else {
        quad = [iso.p(d.u, 0), iso.p(d.u + d.w, 0), iso.p(d.u + d.w + len * 0.4, len), iso.p(d.u + len * 0.4, len)];
        a = iso.p(d.u + d.w / 2, 0);
        b = iso.p(d.u + d.w / 2 + len * 0.4, len);
      }
      c.drawPath(_path(quad), Paint()..shader = _lin(a, b, const [Color(0x449FC4FF), Color(0x009FC4FF)]));
    }
    // door thresholds glow on the floor
    for (final d in room.doors) {
      final r = d.trigger;
      final List<Offset> q;
      final Offset a, b;
      if (d.wall == Wall.left) {
        q = [iso.p(0, r.top), iso.p(1.6, r.top), iso.p(1.6, r.bottom), iso.p(0, r.bottom)];
        a = iso.p(0, r.center.dy);
        b = iso.p(1.6, r.center.dy);
      } else {
        q = [iso.p(r.left, 0), iso.p(r.right, 0), iso.p(r.right, 1.6), iso.p(r.left, 1.6)];
        a = iso.p(r.center.dx, 0);
        b = iso.p(r.center.dx, 1.6);
      }
      c.drawPath(_path(q), Paint()..shader = _lin(a, b, [_a(_accent, 0.32), _a(_accent, 0)]));
    }
    // light pools under lamps / screens (additive)
    for (final o in room.props) {
      for (final q in o.parts.where((q) => q.glow != null && q.h > 0.1)) {
        final at = iso.p(q.rect.center.dx + 0.4, q.rect.center.dy + 0.4);
        final r = iso.s * (q.z > 1.2 ? 2.4 : 2.8);
        c.save();
        c.translate(at.dx, at.dy);
        c.scale(1, 0.5);
        c.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..blendMode = BlendMode.plus
              ..shader = ui.Gradient.radial(Offset.zero, r, [_a(q.glow!, 0.15), _a(q.glow!, 0)]));
        c.restore();
      }
    }
  }

  /// Mirror-image of furniture on the glossy floor.
  void _reflections(List<_Item> items) {
    final alpha = switch (room.style) { FloorStyle.marble => 0.26, FloorStyle.concrete => 0.2, FloorStyle.wood => 0.13 };
    final fp = _floorPath;
    c.save();
    c.clipPath(fp);
    c.saveLayer(fp.getBounds(), Paint()..color = Colors.white.withValues(alpha: alpha));
    _mir = true;
    for (final i in items.where((i) => i.z0 < 0.9)) {
      i.draw();
    }
    _mir = false;
    c.restore();
    c.restore();
  }

  void _shadows() {
    final soft = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, iso.s * 0.2);
    final tight = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, iso.s * 0.07);
    void quad(Rect r, Paint p) =>
        c.drawPath(_path([iso.p(r.left, r.top), iso.p(r.right, r.top), iso.p(r.right, r.bottom), iso.p(r.left, r.bottom)]), p);
    for (final o in room.props) {
      for (final q in o.parts.where((q) => q.z < 0.15 && !q.plant)) {
        quad(q.rect.inflate(0.16).shift(const Offset(0.14, 0.14)), soft);
        quad(q.rect.inflate(0.03), tight);
      }
    }
    final pr = Rect.fromCenter(center: pos, width: 0.5, height: 0.5);
    quad(pr.inflate(0.06).shift(const Offset(0.1, 0.1)), soft);
  }

  /// Pulsing floor rings around anything you can interact with.
  void _rings() {
    final pulse = 0.5 + 0.5 * math.sin(t * 3);
    for (final o in room.props.where((o) => o.act != null)) {
      final hot = o == near;
      final r = o.rect.inflate(0.45);
      final ring = _path([iso.p(r.left, r.top), iso.p(r.right, r.top), iso.p(r.right, r.bottom), iso.p(r.left, r.bottom)]);
      c.drawPath(ring, Paint()..color = _a(_accent, hot ? 0.16 : 0.05));
      _bloom(ring, _accent, iso.s * 0.14, hot ? 0.5 : 0.2 + 0.15 * pulse);
      c.drawPath(
          ring,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = hot ? 2.2 : 1.3
            ..color = _a(shade(_accent, 1.2), hot ? 0.95 : 0.42 + 0.2 * pulse));
    }
  }

  // ---- depth-sorted furniture + player -------------------------------------------------

  List<_Item> _items() => [
        for (final o in room.props)
          for (final q in o.parts) _Item(q.rect, q.z, q.top, () => _part(q)),
        _Item(Rect.fromCenter(center: pos, width: 0.5, height: 0.5), _playerBase, 1.7 + _playerBase, _player),
      ];

  /// <0: [a] is drawn first. Anything entirely above another item is drawn after it (safe: if the lower
  /// item is in front it can't overlap the upper one on screen). Otherwise use the separating axis.
  int _order(_Item a, _Item b) {
    final ar = a.rect, br = b.rect;
    if (a.z1 <= b.z0 + 0.01) return -1;
    if (b.z1 <= a.z0 + 0.01) return 1;
    if (ar.left < br.right && br.left < ar.right && ar.top < br.bottom && br.top < ar.bottom) {
      return (ar.center.dx + ar.center.dy).compareTo(br.center.dx + br.center.dy);
    }
    if (br.left >= ar.right || br.top >= ar.bottom) return -1;
    if (ar.left >= br.right || ar.top >= br.bottom) return 1;
    return 0;
  }

  /// Topological painter's order (Kahn), falling back to nearest-first if the relation ever cycles.
  List<_Item> _sorted(List<_Item> items) {
    final n = items.length;
    final after = List.generate(n, (_) => <int>[]);
    final indeg = List.filled(n, 0);
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final o = _order(items[i], items[j]);
        if (o < 0) {
          after[i].add(j);
          indeg[j]++;
        } else if (o > 0) {
          after[j].add(i);
          indeg[i]++;
        }
      }
    }
    double key(int i) => items[i].rect.center.dx + items[i].rect.center.dy;
    final done = List.filled(n, false);
    final out = <_Item>[];
    while (out.length < n) {
      int? best;
      for (var i = 0; i < n; i++) {
        if (done[i]) continue;
        if (best == null || indeg[i] < indeg[best] || (indeg[i] == indeg[best] && key(i) < key(best))) best = i;
      }
      done[best!] = true;
      out.add(items[best]);
      for (final j in after[best]) {
        indeg[j]--;
      }
    }
    return out;
  }

  /// Height the avatar's feet are at, for depth sorting (on a seat / on the bed / falling).
  double get _playerBase => (pose.lie > 0.5 ? bedSeat.z : (sit > 0.5 ? seat!.z : 0.0)) + pose.lift.clamp(0, 99);

  // ---- furniture ------------------------------------------------------------------------

  List<Offset> _plan(Part q) {
    final r = q.rect;
    if (!q.soft) return [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    final k = math.min(q.w, q.d) * 0.22;
    return [
      Offset(r.left + k, r.top), Offset(r.right - k, r.top), Offset(r.right, r.top + k), Offset(r.right, r.bottom - k), //
      Offset(r.right - k, r.bottom), Offset(r.left + k, r.bottom), Offset(r.left, r.bottom - k), Offset(r.left, r.top + k),
    ];
  }

  void _part(Part q) {
    if (q.plant) return _leaves(q);
    _prism(q);
    if (q.decor != null) _decor(q, q.decor!);
    if (q.mat == Mat.emissive && q.glow != null) {
      final r = q.rect;
      _bloom(_path([_p(r.left, r.top, q.top), _p(r.right, r.top, q.top), _p(r.right, r.bottom, q.top), _p(r.left, r.bottom, q.top)]),
          q.glow!, iso.s * 0.25, 0.5);
    }
  }

  void _prism(Part q) {
    final pts = _plan(q), n = pts.length, z0 = q.z, z1 = q.top;
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      final dx = b.dx - a.dx, dy = b.dy - a.dy, len = math.sqrt(dx * dx + dy * dy);
      final nx = dy / len, ny = -dx / len; // outward normal
      if (nx + ny <= 0.01) continue; // faces away from the camera
      final k = 0.55 + 0.42 * math.max(0.0, nx * 0.4 + ny * 0.92);
      _side([_p(a.dx, a.dy, z1), _p(b.dx, b.dy, z1), _p(b.dx, b.dy, z0), _p(a.dx, a.dy, z0)], q.color, k, q.mat);
    }
    _top([for (final v in pts) _p(v.dx, v.dy, z1)], q.color, q.mat, q.soft);
  }

  void _side(List<Offset> pts, Color base, double k, Mat mat) {
    final path = _path(pts), b = path.getBounds(), c0 = shade(base, k);
    switch (mat) {
      case Mat.glass:
        c.drawPath(path, Paint()..color = _a(shade(base, 1.1), 0.2));
        c.drawPath(path, Paint()..shader = _lin(b.topLeft, b.bottomRight, const [Color(0x30FFFFFF), Color(0x00FFFFFF)]));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x66CFEFFF));
        return;
      case Mat.emissive:
        c.drawPath(path, Paint()..color = shade(base, 1.1));
        return;
      default:
        c.drawPath(path, Paint()..shader = _lin(b.topCenter, b.bottomCenter, [shade(c0, 1.1), shade(c0, 0.82)]));
    }
    if (mat == Mat.gloss) {
      c.drawPath(
          path,
          Paint()
            ..shader = _lin(b.centerLeft, b.centerRight, const [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)], const [0.1, 0.32, 0.62]));
    } else if (mat == Mat.metal) {
      c.drawPath(
          path,
          Paint()
            ..shader = _lin(b.centerLeft, b.centerRight,
                const [Color(0x40000000), Color(0x55FFFFFF), Color(0x25000000), Color(0x2AFFFFFF)], const [0, 0.3, 0.62, 1]));
    }
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..strokeJoin = StrokeJoin.round..color = _a(shade(base, 0.45), 0.32));
  }

  void _top(List<Offset> pts, Color base, Mat mat, bool soft) {
    final path = _path(pts), b = path.getBounds();
    switch (mat) {
      case Mat.glass:
        c.drawPath(path, Paint()..color = _a(shade(base, 1.15), 0.24));
        c.drawPath(path, Paint()..shader = _lin(b.topLeft, b.bottomRight, const [Color(0x50FFFFFF), Color(0x00FFFFFF)]));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0x99DFF4FF));
        return;
      case Mat.emissive:
        c.drawPath(path, Paint()..color = shade(base, 1.25));
        return;
      default:
    }
    if (soft) {
      c.drawPath(path, Paint()..shader = ui.Gradient.radial(b.center.translate(-b.width * 0.15, -b.height * 0.2), math.max(b.width, b.height) * 0.75, [shade(base, 1.28), shade(base, 0.98)]));
    } else {
      c.drawPath(path, Paint()..shader = _lin(b.topLeft, b.bottomRight, [shade(base, 1.2), shade(base, 1.03)]));
    }
    if (mat == Mat.gloss || mat == Mat.metal) {
      c.drawPath(path, Paint()..shader = _lin(b.topLeft, b.bottomRight, const [Color(0x44FFFFFF), Color(0x00FFFFFF), Color(0x18FFFFFF)], const [0, 0.5, 1]));
    }
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..strokeJoin = StrokeJoin.round..color = const Color(0x40FFFFFF));
  }

  /// Leafy plant: curved blades fanning out from the pot, back-to-front.
  void _leaves(Part q) {
    final ctr = q.rect.center;
    final leaves = [
      for (var i = 0; i < 16; i++)
        (ang: i * 2.399 + 0.4, len: 0.62 + ((i * 37) % 10) / 10 * 0.38, reach: 0.35 + ((i * 53) % 10) / 10 * 0.65)
    ]..sort((a, b) => (math.cos(a.ang) + math.sin(a.ang)).compareTo(math.cos(b.ang) + math.sin(b.ang)));
    for (final lf in leaves) {
      final dirx = math.cos(lf.ang), diry = math.sin(lf.ang);
      final base = _p(ctr.dx, ctr.dy, q.z);
      final reach = q.w / 2 * lf.reach * 1.6;
      final tip = _p(ctr.dx + dirx * reach, ctr.dy + diry * reach, q.z + q.h * lf.len);
      final ctl = _p(ctr.dx + dirx * reach * 0.25, ctr.dy + diry * reach * 0.25, q.z + q.h * lf.len * 1.05);
      final n = Offset(-(tip.dy - base.dy), tip.dx - base.dx);
      final nn = n / n.distance * iso.s * 0.16;
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctl.dx + nn.dx, ctl.dy + nn.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(ctl.dx - nn.dx, ctl.dy - nn.dy, base.dx, base.dy);
      final light = (dirx + diry) * 0.5;
      c.drawPath(path, Paint()..shader = _lin(base, tip, [shade(q.color, 0.5 + 0.15 * light), shade(q.color, 1.05 + 0.25 * light)]));
      c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = _a(shade(q.color, 0.4), 0.5));
    }
  }

  void _decor(Part q, Decor d) {
    final r = q.rect;
    // quad on the visible face, u in [ua,ub] of its width, v in [va,vb] of the part's height
    List<Offset> face(double ua, double ub, double va, double vb) {
      final z0 = q.z + q.h * va, z1 = q.z + q.h * vb;
      if (d.face == Face.y) {
        final x0 = r.left + r.width * ua, x1 = r.left + r.width * ub;
        return [_p(x0, r.bottom, z1), _p(x1, r.bottom, z1), _p(x1, r.bottom, z0), _p(x0, r.bottom, z0)];
      }
      final y0 = r.top + r.height * ua, y1 = r.top + r.height * ub;
      return [_p(r.right, y0, z1), _p(r.right, y1, z1), _p(r.right, y1, z0), _p(r.right, y0, z0)];
    }

    switch (d.kind) {
      case DecorKind.screen:
        final quad = face(0.04, 0.96, d.f0, d.f1);
        final path = _path(quad);
        if (q.glow != null) _bloom(path, q.glow!, iso.s * 0.35, 0.55);
        c.drawPath(path, Paint()..shader = _lin(quad[0], quad[2], [d.c1, d.c2]));
        Offset at(double u, double v) => Offset.lerp(Offset.lerp(quad[0], quad[1], u), Offset.lerp(quad[3], quad[2], u), v)!;
        if (d.game != null && d.game == playing && !_mir) {
          _gameScreen(d.game!, at, d.c2);
        } else {
        // soft "aurora" highlight + UI bars
        c.drawPath(_path([at(0, 0.55), at(0.6, 0.15), at(1, 0.35), at(1, 0.9), at(0.4, 1), at(0, 1)]),
            Paint()..color = _a(shade(d.c2, 1.3), 0.16));
        final bar = Paint()..color = const Color(0x55FFFFFF)..strokeWidth = math.max(1.2, iso.s * 0.05)..strokeCap = StrokeCap.round;
        for (final (v, len) in [(0.26, 0.5), (0.44, 0.7), (0.62, 0.36)]) {
          c.drawLine(at(0.1, v), at(0.1 + len * 0.8, v), bar);
        }
        }
        c.drawPath(_path([quad[0], Offset.lerp(quad[0], quad[1], 0.4)!, Offset.lerp(quad[3], quad[2], 0.12)!, quad[3]]), Paint()..color = const Color(0x10FFFFFF));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x40FFFFFF));
      case DecorKind.books:
        final shelves = d.count;
        for (var s = 0; s < shelves; s++) {
          final v0 = d.f0 + (d.f1 - d.f0) * s / shelves, v1 = d.f0 + (d.f1 - d.f0) * (s + 0.88) / shelves;
          _fill(face(0.05, 0.95, v0, v1), const Color(0xFF1E140E));
          const books = 15;
          for (var b = 0; b < books; b++) {
            final hh = 0.6 + ((b * 7 + s * 3) % 4) * 0.1;
            final ua = 0.07 + 0.86 * b / books, ub = 0.07 + 0.86 * (b + 0.85) / books;
            _fill(face(ua, ub, v0 + 0.01, v0 + (v1 - v0) * hh), Color(_bookColors[(b * 5 + s * 3) % _bookColors.length]));
          }
          _fill(face(0.05, 0.95, v0 - 0.012, v0 + 0.006), const Color(0xFF8B6B4E));
        }
      case DecorKind.drawers:
        for (var i = 0; i < d.count; i++) {
          final v0 = 0.05 + 0.9 * i / d.count, v1 = 0.05 + 0.9 * (i + 0.92) / d.count;
          final f = face(0.05, 0.95, v0, v1);
          c.drawPath(_path(f), Paint()..shader = _lin(f[0], f[3], [shade(d.c1, 1.1), shade(d.c1, 0.88)]));
          c.drawPath(_path(f), Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0x55000000));
          final h0 = Offset.lerp(Offset.lerp(f[0], f[1], 0.38), Offset.lerp(f[3], f[2], 0.38), 0.4)!;
          final h1 = Offset.lerp(Offset.lerp(f[0], f[1], 0.62), Offset.lerp(f[3], f[2], 0.62), 0.4)!;
          c.drawLine(h0, h1, Paint()..color = const Color(0xFFDCE2EA)..strokeWidth = math.max(1.4, iso.s * 0.05)..strokeCap = StrokeCap.round);
        }
    }
  }

  // ---- game placeholder on the kiosk screen -----------------------------------------------

  /// A looping mock of the game being played, drawn inside the kiosk's screen quad.
  void _gameScreen(Act game, Offset Function(double, double) at, Color accent) {
    void cell(int x, int y, int cols, int rows, Color col, {double inset = 0.1}) {
      final u0 = (x + inset) / cols, u1 = (x + 1 - inset) / cols, v0 = (y + inset) / rows, v1 = (y + 1 - inset) / rows;
      c.drawPath(_path([at(u0, v0), at(u1, v0), at(u1, v1), at(u0, v1)]), Paint()..color = col);
    }

    // dark backdrop
    c.drawPath(_path([at(0, 0), at(1, 0), at(1, 1), at(0, 1)]), Paint()..color = const Color(0xFF04060C));
    switch (game) {
      case Act.snake:
        const cols = 12, rows = 8;
        final loop = <(int, int)>[
          for (var x = 1; x < cols - 1; x++) (x, 1),
          for (var y = 2; y < rows - 1; y++) (cols - 2, y),
          for (var x = cols - 3; x >= 1; x--) (x, rows - 2),
          for (var y = rows - 3; y >= 2; y--) (1, y),
        ];
        final head = (t * 6).floor();
        for (var i = 9; i >= 0; i--) {
          final (x, y) = loop[(head - i) % loop.length];
          cell(x, y, cols, rows, Color.lerp(const Color(0xFF34D399), const Color(0xFF064E3B), i / 9)!);
        }
        final pulse = 0.5 + 0.5 * math.sin(t * 8);
        cell(cols ~/ 2, rows ~/ 2, cols, rows, Color.lerp(const Color(0xFFF43F5E), Colors.white, pulse * 0.4)!, inset: 0.22);
      case Act.mines:
        const cols = 10, rows = 6;
        final step = (t * 1.6).floor();
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < cols; x++) {
            final open = (x * 7 + y * 13 + step) % 6 < 4;
            cell(x, y, cols, rows, open ? const Color(0xFF0F1A33) : const Color(0xFF3B4A6B), inset: 0.07);
            if (open && (x + y) % 3 != 0) {
              final n = (x * 3 + y) % 3;
              final col = [const Color(0xFF38BDF8), const Color(0xFF34D399), const Color(0xFFF43F5E)][n];
              final ctr = at((x + 0.5) / cols, (y + 0.5) / rows);
              c.drawCircle(ctr, math.max(1.2, iso.s * 0.07), Paint()..color = col);
            } else if (!open && (x * 5 + y) % 9 == 0) {
              cell(x, y, cols, rows, const Color(0xFFF43F5E), inset: 0.32);
            }
          }
        }
      case Act.memory:
        const cols = 4, rows = 3;
        final phase = (t / 1.3).floor();
        final faces = [const Color(0xFFF43F5E), const Color(0xFFFBBF24), const Color(0xFF38BDF8), const Color(0xFFA78BFA), const Color(0xFF34D399), const Color(0xFFF472B6)];
        for (var k = 0; k < cols * rows; k++) {
          final x = k % cols, y = k ~/ cols;
          final up = k == phase % 12 || k == (phase * 5 + 7) % 12;
          cell(x, y, cols, rows, up ? faces[k % faces.length] : const Color(0xFF1E3A5F), inset: 0.09);
          if (up) {
            c.drawCircle(at((x + 0.5) / cols, (y + 0.5) / rows), math.max(1.6, iso.s * 0.09), Paint()..color = Colors.white.withValues(alpha: 0.85));
          }
        }
      default:
        break;
    }
    // scanline sweep
    final sweep = (t * 0.6) % 1.0;
    c.drawLine(at(0, sweep), at(1, sweep), Paint()..color = _a(accent, 0.35)..strokeWidth = math.max(1, iso.s * 0.03));
  }

  // ---- avatar ---------------------------------------------------------------------------------

  void _player() {
    final s = iso.s, sg = _mir ? -1.0 : 1.0;
    if (_mir && !pose.neutral) return; // no reflection while lying / falling
    final base = iso.p(pos.dx, pos.dy); // floor point under the hip
    final k = sit;
    final f = seat?.face ?? const Offset(0, 1);
    final front = seat == null || k < 0.5 || pose.lie > 0.3 || f.dx + f.dy > 0; // facing the camera?
    final fwd = Offset((f.dx - f.dy) * s, (f.dx + f.dy) * s / 2); // screen vector for one tile forward
    double y(double z) => base.dy - sg * z * s;
    Offset up(Offset o, double z) => Offset(o.dx, o.dy - sg * z * s);
    final bob = moving ? math.sin(t * 24).abs() * 0.03 : (pose.lie > 0.5 ? math.sin(t * 2) * 0.012 : 0.0); // breathing when asleep
    var hipZ = seat == null ? 0.8 : 0.8 + (seat!.z + 0.1 - 0.8) * k;
    hipZ = hipZ + (bedSeat.z + 0.2 - hipZ) * pose.lie + pose.lift + bob;

    // rotate the whole (upright) figure about the hip: lying along the bed, or tumbling
    final head = Offset((bedHead.dx - bedHead.dy) * s, (bedHead.dx + bedHead.dy) * s / 2);
    final phiLie = math.atan2(head.dx / head.distance, -head.dy / head.distance);
    final phi = phiLie * pose.lie + pose.spin;
    final hip = Offset(base.dx, y(hipZ));
    if (pose.alpha < 1) c.saveLayer(Rect.fromCircle(center: hip, radius: 6 * s), Paint()..color = Colors.white.withValues(alpha: pose.alpha.clamp(0, 1)));
    c.save();
    c.translate(hip.dx, hip.dy);
    c.rotate(phi);
    c.scale(pose.scale);
    c.translate(-hip.dx, -hip.dy);

    if (!_mir && pose.neutral && k < 0.6) {
      // glowing ring on the floor
      final ring = Rect.fromCenter(center: base, width: 1.5 * s, height: 0.75 * s);
      final a = 1 - k / 0.6;
      c.drawOval(ring, Paint()..color = _a(_accent, 0.5 * a)..style = PaintingStyle.stroke..strokeWidth = 4..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.12)..blendMode = BlendMode.plus);
      c.drawOval(ring, Paint()..color = _a(shade(_accent, 1.3), a)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    }

    void legs() {
      final leg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.15 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF232B38);
      for (final side in [-1.0, 1.0]) {
        final lat = Offset(side * 0.11 * s, 0);
        final lift = moving && k == 0 ? math.max(0.0, math.sin(t * 12 + (side > 0 ? 0 : math.pi))) * 0.12 : 0.0;
        final legTop = up(base + lat, hipZ);
        final kneeStand = up(base + lat, hipZ * 0.5 + lift * 0.5);
        final kneeSit = up(base + lat + fwd * 0.45, hipZ - 0.02);
        final footStand = up(base + lat, hipZ - 0.8 + lift); // legs keep their length when lifted / lying
        final footSit = up(base + lat + fwd * 0.5, 0);
        final knee = Offset.lerp(kneeStand, kneeSit, k)!, foot = Offset.lerp(footStand, footSit, k)!;
        c.drawPath(Path()..moveTo(legTop.dx, legTop.dy)..lineTo(knee.dx, knee.dy)..lineTo(foot.dx, foot.dy), leg);
      }
    }

    void torsoAndHead() {
      final rect = Rect.fromPoints(Offset(base.dx - 0.24 * s, y(hipZ - 0.06)), Offset(base.dx + 0.24 * s, y(hipZ + 0.62)));
      final tr = RRect.fromRectAndRadius(rect, Radius.circular(0.16 * s));
      c.drawRRect(tr, Paint()..shader = _lin(rect.topLeft, rect.bottomRight, const [Color(0xFF4A5670), Color(0xFF1B2230)]));
      c.drawRRect(tr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x40FFFFFF));
      if (front) _led(Offset(base.dx, y(hipZ + 0.5)), Offset(base.dx, y(hipZ + 0.12)), _accent, width: math.max(1.5, s * 0.05), glow: 0.7);
      final headC = Offset(base.dx, y(hipZ + 0.88));
      c.drawCircle(headC, 0.235 * s, Paint()..shader = ui.Gradient.radial(headC.translate(-0.07 * s, -0.08 * sg * s), 0.3 * s, const [Color(0xFFE8ECF3), Color(0xFF8D97A8)]));
      if (front) {
        final visor = RRect.fromRectAndRadius(
            Rect.fromPoints(Offset(base.dx - 0.17 * s, y(hipZ + 0.8)), Offset(base.dx + 0.17 * s, y(hipZ + 0.95))), Radius.circular(0.06 * s));
        c.drawRRect(visor, Paint()..color = const Color(0xFF0B1018));
        if (!_mir) {
          // eyes closed (a flat line) while asleep, a bright visor otherwise
          final asleep = pose.lie > 0.6;
          c.drawLine(Offset(base.dx - 0.11 * s, y(hipZ + 0.875)), Offset(base.dx + 0.11 * s, y(hipZ + 0.875)),
              Paint()..color = asleep ? _a(shade(_accent, 1.3), 0.35) : shade(_accent, 1.3)..strokeWidth = math.max(1.5, s * 0.05)..strokeCap = StrokeCap.round);
        }
      } else {
        // back of the head: a small status light
        c.drawCircle(headC.translate(0, 0.02 * s), 0.05 * s, Paint()..color = shade(_accent, 1.2));
      }
    }

    // seated + facing the camera: thighs come toward the viewer, so they go over the torso
    if (front && k > 0.5 && pose.lie < 0.3) {
      torsoAndHead();
      legs();
    } else {
      legs();
      torsoAndHead();
    }
    c.restore();
    if (pose.alpha < 1) c.restore();

    if (_mir) return;
    // "Zzz" drifting up from his head while he sleeps
    if (pose.zzz) {
      final headTop = hip + Offset(math.sin(phi), -math.cos(phi)) * (1.05 * s);
      for (var i = 0; i < 3; i++) {
        final ph = ((t * 0.5) + i / 3) % 1.0;
        final tp = TextPainter(
          text: TextSpan(text: i == 0 ? 'z' : 'Z', style: TextStyle(color: Colors.white.withValues(alpha: (1 - ph) * 0.9), fontSize: (10 + i * 4) * (0.8 + ph * 0.5), fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, headTop + Offset(8 + ph * 26 + i * 6, -14 - ph * 46));
      }
    }
    if (pose.shout != null) _pill(hip.translate(0, -1.8 * s * pose.scale), pose.shout!, hot: true);
  }

  // ---- labels ------------------------------------------------------------------------------

  void _labels() {
    for (final o in room.props) {
      if (o.label == null) continue;
      final hot = o == near;
      final top = iso.p(o.rect.center.dx, o.rect.center.dy, o.topZ + 0.06);
      final at = iso.p(o.rect.center.dx, o.rect.center.dy, o.topZ + 0.75);
      c.drawLine(at, top, Paint()..color = _a(_accent, hot ? 0.9 : 0.5)..strokeWidth = 1);
      c.drawCircle(top, 2.5, Paint()..color = shade(_accent, 1.3));
      _pill(at.translate(0, hot ? math.sin(t * 5) * 2 : 0), o.label!, hot: hot);
    }
    for (final d in room.doors) {
      _pill(_w(d.wall, d.u + d.w / 2, 2.75), d.label, small: true);
    }
  }

  /// Comic-style speech bubble with a tail, above his head.
  void _speech(Size size) {
    if (say == null || sayAlpha <= 0.01) return;
    final head = iso.p(pos.dx, pos.dy, 2.05);
    final tp = TextPainter(
      text: TextSpan(text: say, style: TextStyle(color: _a(const Color(0xFF0B1020), sayAlpha), fontSize: 14, fontWeight: FontWeight.w600, height: 1.25)),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: 210);
    const padX = 14.0, padY = 10.0, tail = 12.0;
    final w = tp.width + padX * 2, h = tp.height + padY * 2;
    final cx = head.dx.clamp(w / 2 + 8, size.width - w / 2 - 8);
    final box = Rect.fromCenter(center: Offset(cx, head.dy - tail - h / 2), width: w, height: h);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(16));
    final bubble = Path()
      ..addRRect(rr)
      ..moveTo(head.dx.clamp(box.left + 22, box.right - 22) - 8, box.bottom - 1)
      ..lineTo(head.dx, box.bottom + tail)
      ..lineTo(head.dx.clamp(box.left + 22, box.right - 22) + 8, box.bottom - 1)
      ..close();
    c.drawPath(bubble.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.35 * sayAlpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawPath(bubble, Paint()..color = Colors.white.withValues(alpha: 0.97 * sayAlpha));
    tp.paint(c, box.topLeft + const Offset(padX, padY));
  }

  void _pill(Offset at, String text, {bool hot = false, bool small = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: hot ? const Color(0xFF06121A) : Colors.white, fontSize: small ? 9.5 : 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: at, width: tp.width + (small ? 16 : 24), height: tp.height + (small ? 8 : 12)), const Radius.circular(20));
    c.drawRRect(r.shift(const Offset(0, 3)), Paint()..color = const Color(0x66000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawRRect(r, Paint()..color = hot ? shade(_accent, 1.1) : const Color(0xCC0B111A));
    c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = _a(shade(_accent, 1.2), hot ? 1 : 0.6));
    tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(RoomPainter old) => true;
}
