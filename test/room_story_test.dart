import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protfolio/features/isometric_room/isometric_room_view.dart';
import 'package:protfolio/features/isometric_room/room_models.dart';
import 'package:protfolio/features/isometric_room/room_painter.dart';

bool _free(RoomDef r, Offset p) =>
    p.dx > 0.3 &&
    p.dy > 0.3 &&
    p.dx < roomSize - 0.3 &&
    p.dy < roomSize - 0.3 &&
    !r.props.any((o) => o.parts.any((q) => q.solid && q.rect.overlaps(Rect.fromCenter(center: p, width: 0.5, height: 0.5))));

/// Cells (0.25 tile) the character can reach from [from] without cutting corners.
Set<int> _flood(RoomDef r, Offset from) {
  const cell = 0.25, n = 32;
  final walk = [for (var j = 0; j < n; j++) for (var i = 0; i < n; i++) _free(r, Offset((i + 0.5) * cell, (j + 0.5) * cell))];
  int cellOf(Offset p) => (p.dy / cell).floor().clamp(0, n - 1) * n + (p.dx / cell).floor().clamp(0, n - 1);
  final seen = <int>{cellOf(from)};
  final q = [cellOf(from)];
  for (var h = 0; h < q.length; h++) {
    final c = q[h], cx = c % n, cy = c ~/ n;
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]) {
      final x = cx + dx, y = cy + dy;
      if (x < 0 || y < 0 || x >= n || y >= n) continue;
      final k = y * n + x;
      if (seen.contains(k) || !walk[k]) continue;
      if (dx != 0 && dy != 0 && !(walk[cy * n + x] && walk[y * n + cx])) continue;
      seen.add(k);
      q.add(k);
    }
  }
  return {for (final c in seen) if (walk[c]) c};
}

bool _canReach(RoomDef r, Set<int> reach, Rect zone) =>
    reach.any((c) => zone.contains(Offset((c % 32 + 0.5) * 0.25, (c ~/ 32 + 0.5) * 0.25)));

void main() {
  test('every room: spawn is free; doors, windows, seats and props are reachable; arrivals are safe', () {
    for (final r in rooms) {
      expect(_free(r, r.spawn), isTrue, reason: '${r.name} spawn');
      final reach = _flood(r, r.spawn);
      for (final d in r.doors) {
        expect(_canReach(r, reach, d.trigger), isTrue, reason: '${r.name} door ${d.label} reachable');
        final dest = rooms[d.to];
        expect(_free(dest, d.spawn), isTrue, reason: 'arrival in ${dest.name} is free');
        expect(dest.doors.any((x) => x.trigger.contains(d.spawn)), isFalse, reason: 'arrival in ${dest.name} is outside its door triggers');
        expect(dest.windows.any((w) => w.windowTrigger.contains(d.spawn)), isFalse, reason: 'arrival in ${dest.name} is outside window triggers');
      }
      for (final w in r.windows) {
        expect(_canReach(r, reach, w.windowTrigger), isTrue, reason: '${r.name} window can be reached');
      }
      for (final o in r.props.where((o) => o.act != null)) {
        expect(_canReach(r, reach, o.rect.inflate(0.7)), isTrue, reason: '${r.name} ${o.label} reachable');
        final s = o.seat;
        if (s != null) {
          expect(_free(r, s.stand), isTrue, reason: '${o.label} stand spot free');
          expect(reach.contains((s.stand.dy / 0.25).floor() * 32 + (s.stand.dx / 0.25).floor()), isTrue, reason: '${o.label} stand spot reachable');
        }
      }
    }
    final bed = rooms[bedroomIndex];
    expect(_free(bed, bedSeat.stand), isTrue, reason: 'the spot he steps out onto beside the bed');
    expect(bed.windows.any((w) => w.windowTrigger.contains(bedSeat.stand)), isFalse);
  });

  testWidgets('back from the bedroom: he walks to the bed and goes to sleep (no ceiling drop), then the room closes', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/isometric', routes: [
      GoRoute(path: '/', builder: (c, s) => const Text('HOME')),
      GoRoute(path: '/isometric', builder: (c, s) => const IsometricRoomView(intro: false, debug: true)),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('BEDROOM'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('room=BEDROOM'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    var slept = false;
    for (var i = 0; i < 60 && find.text('HOME').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('scene=drop'), findsNothing, reason: 'no falling from the ceiling in the bedroom');
      slept = slept || find.textContaining('scene=sleep').evaluate().isNotEmpty;
    }
    expect(slept, isTrue);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('back from the bedroom while he is across the room: he walks to the bed first', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false, debug: true)));
    await tester.pump();
    await tester.tap(find.text('BEDROOM'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    final iso = Iso(const Size(1200, 800 - kToolbarHeight));
    final far = iso.p(6.0, 6.0); // front-right corner of the room
    await tester.tapAt(Offset(far.dx, far.dy + kToolbarHeight));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('leaveTo=/'), findsOneWidget);
    expect(find.textContaining('scene=null'), findsOneWidget); // still walking over
    var slept = false;
    for (var i = 0; i < 60 && !slept; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      slept = find.textContaining('scene=sleep').evaluate().isNotEmpty;
    }
    expect(slept, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [('desk', const Size(1200, 800)), ('phone', const Size(390, 780))]) {
    testWidgets('intro: wakes up in the bedroom, eyes open, then he is in control at $name size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(debug: true)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('room=BEDROOM'), findsOneWidget);
      expect(find.textContaining('scene=wake'), findsOneWidget);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('scene=null'), findsOneWidget);
      expect(find.textContaining('eyes=1.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('window: walking up to it drops him out, he wakes in bed, then says "it was a dream" in a speech bubble at $name size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false, debug: true)));
      await tester.pump();
      await tester.ensureVisible(find.text('PROJECTS'));
      await tester.pump();
      await tester.tap(find.text('PROJECTS')); // the study has a window on its right wall
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final iso = Iso(Size(size.width, size.height - kToolbarHeight));
      final spot = iso.p(2.2, 0.45); // right up against the glass
      await tester.tapAt(Offset(spot.dx, spot.dy + kToolbarHeight));
      var fell = false;
      for (var i = 0; i < 60 && !fell; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        fell = find.textContaining('scene=windowFall').evaluate().isNotEmpty;
      }
      expect(fell, isTrue, reason: 'he should go out of the window');
      for (var i = 0; i < 120 && find.textContaining('say=Thank god that was a dream').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('say=Thank god that was a dream'), findsOneWidget); // he says it
      expect(find.textContaining('room=BEDROOM'), findsOneWidget); // he woke up in bed
      expect(find.textContaining('scene=null'), findsOneWidget); // and he's free to move, nothing modal
      // the bubble goes away by itself
      for (var i = 0; i < 45; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('say=null'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving: he drops from the ceiling into bed, falls asleep, then the room closes at $name size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false, debug: true)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back)); // no router here, so we only watch the cutscene
      var dropping = false;
      for (var i = 0; i < 20 && !dropping; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        dropping = find.textContaining('scene=drop').evaluate().isNotEmpty;
      }
      expect(dropping, isTrue);
      expect(find.textContaining('room=BEDROOM'), findsOneWidget); // wherever he was, he lands on the bed
      expect(find.textContaining('leaveTo=/'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
