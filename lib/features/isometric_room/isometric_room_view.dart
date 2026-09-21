import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/routing/replace_route.dart';
import '../retro_os/contact_window.dart' show openResume;
import '../retro_os/neo_memory_game.dart';
import '../retro_os/neo_minesweeper.dart';
import '../retro_os/neo_snake_game.dart';
import 'holo_panels.dart';
import 'room_models.dart';
import 'room_painter.dart';

const _speed = 3.5; // tiles / second
const _bg = Color(0xFF0B1020);
final _moveKeys = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyD,
};

enum _Scene { wake, drop, windowFall, sleep }

/// Walk-around 3D-style rooms. Each room holds one part of the portfolio.
class IsometricRoomView extends StatefulWidget {
  const IsometricRoomView({super.key, this.debug = false, this.intro = true});

  /// Start by waking up in the bed (the eyes-opening sequence). Tests pass false to start awake in the living room.
  final bool intro;

  /// Shows a small state readout (position, seat, path...) - open `/isometric?debug=1`.
  final bool debug;

  @override
  State<IsometricRoomView> createState() => _IsometricRoomViewState();
}

class _IsometricRoomViewState extends State<IsometricRoomView> with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _t = 0;

  int _room = 0;
  Offset _pos = rooms[0].spawn;
  List<Offset> _path = []; // waypoints to walk (tap-to-walk / walking to a seat)
  Prop? _pending; // prop tapped: interact once we're close enough
  Prop? _near;
  bool _moving = false;
  bool _modal = false; // a dialog is open
  bool _busy = false; // walking through a door
  bool _veil = false; // fade-to-black during door transitions
  Iso? _iso;

  // sitting: _seatProp is set from "walk to the seat" until "stood back up"
  Prop? _seatProp;
  int _sitDir = 0; // +1 sitting down, -1 standing up
  double _sit = 0; // 0 standing ... 1 seated
  Offset _sitFrom = Offset.zero; // where he was when he started sitting down
  bool _ignoreHeld = false; // a movement key was already down when E was pressed: don't let it cancel the walk to the seat
  Act? _playing; // game whose placeholder is shown on the lounge kiosk
  Duration _lastPaint = Duration.zero;

  // story scenes: waking up, dropping into bed when leaving, falling out of a window
  _Scene? _scene;
  double _sceneT = 0;
  Pose _pose = const Pose();
  double _eyeOpen = 1; // 0 = eyes shut (black screen) ... 1 = fully open
  double _blur = 0;
  double _shake = 0;
  bool _dream = false; // this wake-up follows a window fall: show the "it was a dream" popup afterwards
  String? _leaveTo; // route to go to once he's asleep in bed
  Decal? _fallWin;
  String _fallLine = 'AAAAH!';
  static int _falls = 0; // static: survives leaving the room, resets when the page is closed / reloaded
  static const _fallLines = [
    'AAAAH!',
    'Whatt?!',
    'Again?!',
    'This can\'t be real...',
    'Here we go again...',
    'Am I even real?',
    'Something is fishy around here...',
    'Not the window again!',
    'I regret everything!',
    'Who keeps opening this?!',
    'Tell my laptop I loved it!',
    'I meant to do that.',
  ];
  String? _say; // speech bubble over his head
  double _sayT = 0;
  Offset _fallFrom = Offset.zero;

  Seat? get _activeSeat => _scene != null ? bedSeat : _seatProp?.seat;

  RoomDef get _def => rooms[_room];

  @override
  void initState() {
    super.initState();
    if (widget.intro) _startWake();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _free(Offset p) =>
      p.dx > 0.3 &&
      p.dy > 0.3 &&
      p.dx < roomSize - 0.3 &&
      p.dy < roomSize - 0.3 &&
      !_def.props.any((o) => o.parts.any((q) => q.solid && q.rect.overlaps(Rect.fromCenter(center: p, width: 0.5, height: 0.5))));

  // ---- pathfinding: BFS over a 0.25-tile grid of spots the character fits in ----------------------

  static const _cell = 0.25;
  static const _cells = 32; // roomSize / _cell
  final _walkGrids = <int, List<bool>>{};

  List<bool> get _walkable => _walkGrids.putIfAbsent(
        _room,
        () => [for (var j = 0; j < _cells; j++) for (var i = 0; i < _cells; i++) _free(Offset((i + 0.5) * _cell, (j + 0.5) * _cell))],
      );

  /// Waypoints from the current position to [zone] (any spot inside it) or to the reachable spot nearest [to].
  List<Offset> _findPath({Offset? to, Rect? zone}) {
    final walk = _walkable;
    int cellOf(Offset p) => (p.dy / _cell).floor().clamp(0, _cells - 1) * _cells + (p.dx / _cell).floor().clamp(0, _cells - 1);
    Offset centre(int c) => Offset((c % _cells + 0.5) * _cell, (c ~/ _cells + 0.5) * _cell);
    final start = cellOf(_pos);
    final prev = List<int>.filled(_cells * _cells, -2)..[start] = -1;
    final queue = <int>[start];
    int? goal, best;
    var bestD = double.infinity;
    for (var head = 0; head < queue.length; head++) {
      final c = queue[head], ctr = centre(c);
      if (zone != null && zone.contains(ctr)) {
        goal = c;
        break;
      }
      if (to != null) {
        final d = (ctr - to).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      final cx = c % _cells, cy = c ~/ _cells;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
        final x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= _cells || y >= _cells) continue;
        final n = y * _cells + x;
        if (prev[n] != -2 || !walk[n]) continue;
        if (dx != 0 && dy != 0 && !(walk[cy * _cells + x] && walk[y * _cells + cx])) continue; // don't cut corners
        prev[n] = c;
        queue.add(n);
      }
    }
    goal ??= best;
    if (goal == null) return [];
    final path = <Offset>[];
    for (var c = goal; c != -1; c = prev[c]) {
      path.add(centre(c));
    }
    final out = path.reversed.skip(1).toList(); // skip the cell we're already in
    // finish exactly on the requested spot (the last cell centre can be ~0.2 tiles away from it)
    if (to != null && _free(to) && _clear(out.isEmpty ? _pos : out.last, to)) out.add(to);
    return _straighten(out);
  }

  bool _clear(Offset a, Offset b) {
    final n = ((b - a).distance / 0.1).ceil();
    for (var k = 1; k <= n; k++) {
      if (!_free(Offset.lerp(a, b, k / n)!)) return false;
    }
    return true;
  }

  /// Drops waypoints that a straight walk can skip (so he moves at full speed in long segments).
  List<Offset> _straighten(List<Offset> pts) {
    final out = <Offset>[];
    var from = _pos, i = 0;
    while (i < pts.length) {
      var j = pts.length - 1;
      while (j > i && !_clear(from, pts[j])) {
        j--;
      }
      out.add(pts[j]);
      from = pts[j];
      i = j + 1;
    }
    return out;
  }

  Prop? _nearest() {
    Prop? best;
    var bestD = double.infinity;
    for (final o in _def.props.where((o) => o.act != null && o.rect.inflate(0.7).contains(_pos))) {
      final d = (o.rect.center - _pos).distance;
      if (d < bestD) {
        best = o;
        bestD = d;
      }
    }
    return best;
  }

  void _tick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.1);
    _last = elapsed;
    if (_busy) return;
    if (_modal) {
      // room stays alive behind the panel: animate the game placeholder on the kiosk screen (~20 fps)
      if (_playing != null && (elapsed - _lastPaint).inMilliseconds > 48) {
        _lastPaint = elapsed;
        setState(() => _t = elapsed.inMicroseconds / 1e6);
      }
      return;
    }
    _t = elapsed.inMicroseconds / 1e6;
    if (_say != null) {
      _sayT += dt;
      if (_sayT > 3.8) _say = null;
      if (_scene == null) setState(() {}); // keep the bubble animating while he's standing still
    }
    if (_scene != null) return _advanceScene(dt);
    if (_sitDir != 0) return _advanceSit(dt);

    final k = HardwareKeyboard.instance;
    bool down(LogicalKeyboardKey a, LogicalKeyboardKey b) => k.isLogicalKeyPressed(a) || k.isLogicalKeyPressed(b);
    // screen directions in grid space: up = (-1,-1), right = (1,-1)
    var dir = Offset.zero;
    if (down(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW)) dir += const Offset(-1, -1);
    if (down(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)) dir += const Offset(1, 1);
    if (down(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)) dir += const Offset(1, -1);
    if (down(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA)) dir += const Offset(-1, 1);

    if (_leaveTo != null) dir = Offset.zero; // going to sleep: no steering
    if (_ignoreHeld) {
      if (dir == Offset.zero) {
        _ignoreHeld = false; // released: from now on a fresh key press takes over again
      } else {
        dir = Offset.zero;
      }
    }

    var dist = dir.distance;
    if (dist > 0) {
      _path = [];
      _pending = null;
      _seatProp = null; // moving by hand cancels walking to a seat
    } else if (_path.isNotEmpty) {
      while (_path.length > 1 && (_path.first - _pos).distance < 0.12) {
        _path.removeAt(0);
      }
      dir = _path.first - _pos;
      dist = dir.distance;
      if (dist < 0.06) {
        _path.removeAt(0);
        dist = 0;
      }
    }

    var moved = false;
    if (dist > 0) {
      final step = dir / dist * math.min(_speed * dt, dist);
      final nx = _pos + Offset(step.dx, 0);
      if (_free(nx)) {
        _pos = nx;
        moved = true;
      }
      final ny = _pos + Offset(0, step.dy);
      if (_free(ny)) {
        _pos = ny;
        moved = true;
      }
      if (!moved) {
        _path = []; // walked into something
        _pending = null;
      }
    }

    // reached the spot next to the seat: sit down
    final walking = _seatProp;
    if (walking != null) {
      final st = walking.seat!.stand;
      if ((st - _pos).distance < 0.35) {
        _sitFrom = _pos; // the sit animation glides from here, so there's no visible snap
        _path = [];
        _sitDir = 1;
      } else if (!moved && _path.isEmpty) {
        _seatProp = null; // couldn't get there
      }
    }

    final near = _nearest();
    if (moved || near != _near || moved != _moving) {
      setState(() {
        _moving = moved;
        _near = near;
      });
    }

    // bedroom + back pressed: he walked to the bed, now he lies down
    if (_leaveTo != null && !_busy) {
      if ((bedSeat.stand - _pos).distance < 0.35 || (!moved && _path.isEmpty)) {
        _startSleep();
      }
      return;
    }

    // too close to a window: out he goes
    final win = _seatProp != null ? null : _def.windows.where((d) => d.windowTrigger.contains(_pos)).firstOrNull;
    if (win != null) {
      _startWindowFall(win);
      return;
    }

    final door = _seatProp != null ? null : _def.doors.where((d) => d.trigger.contains(_pos)).firstOrNull;
    if (door != null) {
      _enter(door.to, door.spawn);
    } else if (_pending != null && _pending == _near) {
      final p = _pending!;
      _pending = null;
      _path = [];
      _interact(p);
    }
  }

  // ---- story scenes ---------------------------------------------------------------------------------

  /// Fade the speech bubble in quickly and out slowly.
  double get _sayAlpha => _say == null ? 0 : math.min(1.0, math.min(_sayT / 0.25, (3.8 - _sayT) / 0.5)).clamp(0.0, 1.0);

  bool get _anyMoveKeyDown => _moveKeys.any(HardwareKeyboard.instance.isLogicalKeyPressed);

  /// Eyelid opening for the wake-up: a crack, a blink, then fully open.
  double _lidOpen(double t) {
    if (t < 0.4) return 0;
    if (t < 0.9) return 0.16 * Curves.easeOut.transform((t - 0.4) / 0.5);
    if (t < 1.15) return 0.16 - 0.14 * ((t - 0.9) / 0.25);
    return 0.02 + 0.98 * Curves.easeInOut.transform(((t - 1.15) / 1.45).clamp(0.0, 1.0));
  }

  void _startWake({bool dream = false}) {
    _dream = dream;
    _scene = _Scene.wake;
    _sceneT = 0;
    _room = bedroomIndex;
    _pos = bedSeat.pos;
    _sit = 0;
    _sitDir = 0;
    _seatProp = null;
    _path = [];
    _pending = null;
    _near = null;
    _veil = false;
    _pose = const Pose(lie: 1, zzz: true);
    _eyeOpen = 0;
    _blur = 14;
  }

  void _advanceScene(double dt) {
    _sceneT += dt;
    final t = _sceneT;
    switch (_scene!) {
      case _Scene.wake:
        _eyeOpen = _lidOpen(t);
        _blur = 14 * (1 - Curves.easeOut.transform(((t - 0.4) / 2.4).clamp(0.0, 1.0)));
        final up = ((t - 1.6) / 0.7).clamp(0.0, 1.0); // sitting up
        final out = ((t - 2.3) / 0.7).clamp(0.0, 1.0); // swinging out and standing
        _pose = Pose(lie: 1 - Curves.easeInOut.transform(up), zzz: t < 1.3);
        _sit = out > 0 ? 1 - out : up;
        _pos = Offset.lerp(bedSeat.pos, bedSeat.stand, Curves.easeInOut.transform(out))!;
        if (t >= 3.05) {
          _scene = null;
          _pose = const Pose();
          _pos = bedSeat.stand;
          _sit = 0;
          _eyeOpen = 1;
          _blur = 0;
          _near = _nearest();
          _ignoreHeld = _anyMoveKeyDown;
          if (_dream) {
            _dream = false;
            _say = 'Thank god that was a dream'; // he says it out loud (speech bubble over his head)
            _sayT = 0;
          }
        }
      case _Scene.drop:
        const fall = 0.8;
        final lift = t < fall ? 7.0 * (1 - (t / fall) * (t / fall)) : (t < 1.15 ? 0.32 * math.sin(math.pi * (t - fall) / 0.35) : 0.0);
        _pose = Pose(
          lie: t < fall ? ((t - 0.45) / 0.35).clamp(0.0, 1.0) : 1.0,
          lift: lift,
          spin: t < fall ? 2.4 * (1 - t / fall) : 0.0,
          zzz: t > 1.5,
        );
        _pos = bedSeat.pos;
        _shake = (t >= fall && t < fall + 0.3) ? math.sin((t - fall) * 90) * 5 * (1 - (t - fall) / 0.3) : 0;
        final close = ((t - 2.0) / 0.9).clamp(0.0, 1.0); // eyes close, then off we go
        _eyeOpen = 1 - Curves.easeIn.transform(close);
        _blur = 10 * close;
        if (t >= 3.1) {
          final dest = _leaveTo!;
          _scene = null;
          _leaveTo = null;
          replaceRoute(context, dest);
        }
      case _Scene.sleep:
        final down = (t / 0.7).clamp(0.0, 1.0); // sits on the edge of the bed...
        final lay = ((t - 0.7) / 0.7).clamp(0.0, 1.0); // ...then lies back
        _pos = Offset.lerp(_fallFrom, bedSeat.pos, Curves.easeInOut.transform(down))!;
        _sit = lay > 0 ? 1 - lay : down;
        _pose = Pose(lie: Curves.easeInOut.transform(lay), zzz: t > 1.6);
        final close = ((t - 1.9) / 0.9).clamp(0.0, 1.0);
        _eyeOpen = 1 - Curves.easeIn.transform(close);
        _blur = 10 * close;
        if (t >= 3.0) {
          final dest = _leaveTo!;
          _scene = null;
          _leaveTo = null;
          replaceRoute(context, dest);
        }
      case _Scene.windowFall:
        final d = _fallWin!;
        final left = d.wall == Wall.left;
        final wallPt = left ? Offset(0.12, _fallFrom.dy) : Offset(_fallFrom.dx, 0.12);
        final outPt = left ? Offset(-1.0, _fallFrom.dy) : Offset(_fallFrom.dx, -1.0);
        final hop = (t / 0.4).clamp(0.0, 1.0);
        final go = ((t - 0.4) / 0.5).clamp(0.0, 1.0);
        _pos = t < 0.4 ? Offset.lerp(_fallFrom, wallPt, Curves.easeOut.transform(hop))! : Offset.lerp(wallPt, outPt, Curves.easeIn.transform(go))!;
        final fallT = math.max(0.0, t - 0.4);
        _pose = Pose(
          lift: t < 0.4 ? 0.7 * math.sin(math.pi * hop) : 0.5 - 7.0 * fallT * fallT,
          spin: fallT * 8,
          scale: 1 - 0.6 * (fallT / 1.2).clamp(0.0, 1.0),
          alpha: 1 - ((t - 0.6) / 0.7).clamp(0.0, 1.0),
          shout: t > 0.3 && t < 1.3 ? _fallLine : null,
        );
        if (t >= 1.7) {
          _scene = null;
          _afterWindowFall();
        }
    }
    setState(() {});
  }

  void _startSleep() {
    setState(() {
      _scene = _Scene.sleep;
      _sceneT = 0;
      _fallFrom = _pos; // he starts from wherever he ended up beside the bed
      _path = [];
      _pose = const Pose();
      _near = null;
    });
  }

  Future<void> _startWindowFall(Decal d) async {
    setState(() {
      _scene = _Scene.windowFall;
      _sceneT = 0;
      _fallWin = d;
      _fallFrom = _pos;
      _fallLine = _fallLines[_falls++ % _fallLines.length];
      _say = null; // cut off the "it was a dream" line if he falls again right away
      _path = [];
      _pending = null;
      _near = null;
    });
  }

  /// Fade out, then wake up in bed again ("it was all a dream").
  Future<void> _afterWindowFall() async {
    _busy = true;
    setState(() => _veil = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _startWake(dream: true);
    });
  }

  /// Leaving the room: wherever he is, he drops from the ceiling into bed, falls asleep, and the room closes.
  Future<void> _leave(String dest) async {
    if (_leaveTo != null) return;
    if (_scene == _Scene.wake || _scene == _Scene.windowFall || _busy) {
      replaceRoute(context, dest); // mid-cutscene: don't make anyone wait
      return;
    }
    if (_modal) return;
    if (_room == bedroomIndex) {
      // already in the bedroom: no dropping from the ceiling, he just walks over to the bed and goes to sleep
      setState(() {
        _leaveTo = dest;
        _seatProp = null;
        _sit = 0;
        _sitDir = 0;
        _pending = null;
        _ignoreHeld = false;
        _path = _findPath(to: bedSeat.stand);
      });
      return;
    }
    _leaveTo = dest;
    _busy = true;
    setState(() {
      _veil = true;
      _seatProp = null;
      _sit = 0;
      _sitDir = 0;
      _path = [];
      _pending = null;
      _ignoreHeld = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _room = bedroomIndex;
      _pos = bedSeat.pos;
      _near = null;
      _scene = _Scene.drop;
      _sceneT = 0;
      _pose = const Pose(lift: 7);
      _eyeOpen = 1;
      _blur = 0;
      _veil = false;
    });
  }

  Future<void> _enter(int room, Offset spawn) async {
    if (_busy || _modal || _seatProp != null || _scene != null || _leaveTo != null) return;
    _busy = true;
    setState(() => _veil = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _room = room;
      _pos = spawn;
      _pending = null;
      _path = [];
      _near = null;
      _moving = false;
      _veil = false;
    });
    _busy = false;
  }

  void _tap(TapDownDetails d) {
    if (_modal || _busy || _seatProp != null || _scene != null || _leaveTo != null) return;
    final iso = _iso!, at = d.localPosition;
    final door = _def.doors.where((x) => iso.doorBounds(x).contains(at)).firstOrNull;
    if (door != null) {
      _pending = null;
      _path = _findPath(zone: door.trigger);
      return;
    }
    final hit = _def.props.where((o) => o.act != null && iso.propBounds(o).contains(at)).toList()
      ..sort((a, b) => (b.rect.left + b.rect.top).compareTo(a.rect.left + a.rect.top));
    if (hit.isNotEmpty && hit.first.seat != null) {
      _interact(hit.first); // heads straight for the seat
    } else if (hit.isNotEmpty) {
      _pending = hit.first;
      _path = _findPath(zone: hit.first.rect.inflate(0.7)); // walk until we're within reach of it
    } else {
      _pending = null;
      final g = iso.toGrid(at);
      _path = _findPath(to: Offset(g.dx.clamp(0.4, roomSize - 0.4), g.dy.clamp(0.4, roomSize - 0.4)));
    }
  }

  void _interact(Prop o) {
    if (_seatProp != null) return;
    switch (o.act!) {
      case Act.resume:
        openResume();
      case Act.retro:
        _leave('/retro'); // he drops into bed, then the room closes
      default:
        if (o.seat == null) {
          _openPanel(o);
        } else {
          _pending = null;
          _ignoreHeld = _moveKeys.any(HardwareKeyboard.instance.isLogicalKeyPressed);
          _seatProp = o;
          _path = _findPath(to: o.seat!.stand); // walk to the seat, then sit (see _tick / _advanceSit)
          if (_path.isEmpty && (o.seat!.stand - _pos).distance > 0.15) _seatProp = null; // unreachable
        }
    }
  }

  /// Sit down / stand up animation; opens the panel once seated.
  void _advanceSit(double dt) {
    final o = _seatProp;
    if (o == null) {
      _sitDir = 0;
      return;
    }
    final seat = o.seat!;
    _sit = (_sit + _sitDir * dt / 0.6).clamp(0.0, 1.0);
    setState(() => _pos = Offset.lerp(_sitDir > 0 ? _sitFrom : seat.stand, seat.pos, Curves.easeInOut.transform(_sit))!);
    if (_sitDir > 0 && _sit >= 1) {
      _sitDir = 0;
      _openPanel(o);
    } else if (_sitDir < 0 && _sit <= 0) {
      setState(() {
        _sitDir = 0;
        _seatProp = null;
        _pos = seat.stand;
        _near = _nearest();
      });
    }
  }

  static const _gameColors = {Act.snake: Color(0xFFF43F5E), Act.mines: Color(0xFF38BDF8), Act.memory: Color(0xFF34D399)};

  /// Opens the module as a dark-glass panel docked beside the character, so he stays visible.
  Future<void> _openPanel(Prop o) async {
    _modal = true;
    final act = o.act!;
    final game = _gameColors.containsKey(act);
    final acc = game ? _gameColors[act]! : _def.accent;
    final (title, body) = switch (act) {
      Act.about => ('ABOUT ME', HoloAbout(accent: acc) as Widget),
      Act.projects => ('PROJECTS', HoloProjects(accent: acc)),
      Act.contact => ('CONTACT', HoloContact(accent: acc)),
      Act.snake => ('SNAKE', HoloGame(accent: acc, child: const NeoSnakeGame())),
      Act.mines => ('MINESWEEPER', HoloGame(accent: acc, child: const NeoMinesweeper())),
      Act.memory => ('MEMORY', HoloGame(accent: acc, child: const NeoMemoryGame())),
      _ => ('', const SizedBox()),
    };
    if (game) setState(() => _playing = act);

    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 760;
    final Alignment dock;
    if (narrow) {
      dock = Alignment.bottomCenter;
    } else if (game) {
      dock = Alignment.centerLeft; // leave the kiosk screens on the right visible
    } else if (o.seat != null) {
      final sx = _iso!.p(o.seat!.pos.dx, o.seat!.pos.dy).dx;
      dock = sx < size.width / 2 ? Alignment.centerRight : Alignment.centerLeft; // opposite side of the character
    } else {
      dock = Alignment.center;
    }
    final w = narrow ? size.width - 24 : (game ? math.min(460.0, size.width * 0.38) : math.min(640.0, size.width * 0.5));
    final h = narrow ? size.height * (game ? 0.62 : 0.86) : size.height - 48;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: game ? 0.18 : 0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, _) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: dock,
              child: SizedBox(width: w, height: h, child: HoloPanel(title: title, subtitle: _def.name, accent: acc, child: body)),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: Offset(narrow ? 0 : (dock.x > 0 ? 0.06 : -0.06), narrow ? 0.06 : 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
    _modal = false;
    if (!mounted) return;
    setState(() {
      _playing = null;
      if (_seatProp != null) _sitDir = -1; // stand back up
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _leave('/')), // back = home (whatever we arrived from was replaced, not stacked)
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_def.name, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 15)),
            Text('0${_room + 1} / 0${rooms.length}  ·  ${_def.topic}',
                style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 2, fontSize: 10, color: _def.accent)),
          ],
        ),
      ),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (_, e) {
          final k = e.logicalKey;
          // swallow movement keys so arrows don't move focus onto the back button
          if (_moveKeys.contains(k)) return KeyEventResult.handled;
          if (e is KeyDownEvent &&
              (k == LogicalKeyboardKey.keyE || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) &&
              _near != null &&
              _seatProp == null &&
              _scene == null &&
              _leaveTo == null &&
              !_modal &&
              !_busy) {
            _interact(_near!);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(builder: (context, c) {
          final iso = _iso = Iso(c.biggest);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _tap,
                  child: Transform.translate(
                    offset: Offset(0, _shake),
                    child: CustomPaint(
                      painter: RoomPainter(iso, _def, _pos, _near, _moving, _t,
                          seat: _activeSeat, sit: Curves.easeInOut.transform(_sit), playing: _playing, pose: _pose,
                          say: _say, sayAlpha: _sayAlpha),
                    ),
                  ),
                ),
              ),
              // room switcher (single scrollable row so it never wraps onto the room)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, bc) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: bc.maxWidth - 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < rooms.length; i++)
                            Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 8), child: _chip(i)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.debug)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black87,
                      child: Text(
                        'room=${_def.name}  pos=(${_pos.dx.toStringAsFixed(2)}, ${_pos.dy.toStringAsFixed(2)})\n'
                        'near=${_near?.label}  seat=${_seatProp?.label}  sitDir=$_sitDir  sit=${_sit.toStringAsFixed(2)}\n'
                        'path=${_path.length}${_path.isEmpty ? '' : ' -> ${_path.last.dx.toStringAsFixed(2)}, ${_path.last.dy.toStringAsFixed(2)}'}  '
                        'ignoreHeld=$_ignoreHeld  modal=$_modal  busy=$_busy  moving=$_moving\n'
                        'scene=${_scene?.name}  t=${_sceneT.toStringAsFixed(2)}  eyes=${_eyeOpen.toStringAsFixed(2)}  leaveTo=$_leaveTo\n'
                        'say=$_say',
                        style: const TextStyle(color: Color(0xFF7CFFB2), fontFamily: 'monospace', fontSize: 11, height: 1.4),
                      ),
                    ),
                  ),
                ),
              // interaction prompt / controls hint
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: _near != null && _seatProp == null && _leaveTo == null
                      ? GestureDetector(
                          onTap: () => _interact(_near!),
                          child: _glass(
                            radius: 30,
                            border: _def.accent,
                            glow: true,
                            padding: const EdgeInsets.fromLTRB(10, 9, 22, 9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: _def.accent, borderRadius: BorderRadius.circular(9)),
                                  child: const Text('E', style: TextStyle(color: Color(0xFF06121A), fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 12),
                                Text('PRESS E: ${_near!.label}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.4)),
                              ],
                            ),
                          ),
                        )
                      : const Text('WASD / ARROWS / TAP TO WALK  ·  E TO INTERACT  ·  WALK INTO DOORS',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10.5, letterSpacing: 1.2)),
                ),
              ),
              // door transition veil
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _veil ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const ColoredBox(color: _bg),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
        ),
        _EyeOverlay(open: _eyeOpen, blur: _blur), // eyes opening / closing covers the whole screen
      ],
    );
  }

  /// Frosted-glass container used by the HUD.
  Widget _glass({required Widget child, double radius = 20, Color? border, bool glow = false, EdgeInsets padding = EdgeInsets.zero}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow && border != null ? [BoxShadow(color: border.withValues(alpha: 0.35), blurRadius: 22)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0x66101827),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: (border ?? Colors.white).withValues(alpha: border == null ? 0.14 : 0.7)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _chip(int i) {
    final active = i == _room;
    final accent = rooms[i].accent;
    return GestureDetector(
      onTap: () => active ? null : _enter(i, rooms[i].spawn),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _glass(
          radius: 20,
          border: active ? accent : null,
          glow: active,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(rooms[i].topic,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.6)),
        ),
      ),
    );
  }
}

// ---- waking up / falling asleep ------------------------------------------------------------------

/// Eyelids that open (or close) over the whole screen, with a blurry-to-sharp focus pull.
class _EyeOverlay extends StatelessWidget {
  const _EyeOverlay({required this.open, required this.blur});
  final double open; // 0 = shut (black) ... 1 = open
  final double blur;

  @override
  Widget build(BuildContext context) {
    if (open >= 0.999 && blur < 0.3) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blur > 0.3 && open > 0.02)
            ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: const SizedBox.expand())),
          CustomPaint(painter: _LidPainter(open)),
        ],
      ),
    );
  }
}

class _LidPainter extends CustomPainter {
  _LidPainter(this.open);
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final cover = (1 - open).clamp(0.0, 1.0);
    // vignette: the edges of your vision stay dark a little longer
    if (open > 0.02) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.radial(size.center(Offset.zero), size.longestSide * 0.75,
                [Colors.transparent, Colors.black.withValues(alpha: 0.7 * cover)], const [0.35, 1]));
    }
    if (cover <= 0.001) return;
    final h = size.height / 2 * cover, bulge = size.height * 0.12 * cover;
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, h)
      ..quadraticBezierTo(size.width / 2, h + bulge, 0, h)
      ..close();
    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - h)
      ..quadraticBezierTo(size.width / 2, size.height - h - bulge, 0, size.height - h)
      ..close();
    final soft = Paint()..color = Colors.black..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 30 * cover);
    for (final path in [top, bottom]) {
      canvas.drawPath(path, soft); // soft edge
      canvas.drawPath(path, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(_LidPainter old) => old.open != open;
}
