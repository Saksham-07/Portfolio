import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protfolio/features/retro_os/retro_os_view.dart';

Future<void> _boot(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: RetroOSView()));
  for (var i = 0; i < 80 && find.text('ABOUT_ME.TXT').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('About opens beside the desktop icons so every icon stays visible', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _boot(tester);
    final win = tester.getTopLeft(find.text('ABOUT_ME.TXT').first).dx; // the window title (the taskbar tab has the same text)
    for (final label in ['PROJECTS', 'ABOUT ME', 'CONTACT', 'UI_LAB.EXE', 'RESUME.PDF', 'TERMINAL.EXE']) {
      expect(tester.getTopRight(find.text(label)).dx, lessThan(win), reason: '$label icon is left of the window');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('windows resize from the edges and corners (and respect a minimum size)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _boot(tester);
    // the window's outer box (window + 10px handle margin) is the Stack that contains the title
    Rect box() => tester.getRect(find.ancestor(of: find.text('ABOUT_ME.TXT').first, matching: find.byType(Stack)).first);
    final start = box();

    // (a drag swallows ~20px of touch slop, so check the direction and rough size rather than exact pixels)
    // bottom-right corner: shrink
    await tester.dragFrom(start.bottomRight - const Offset(4, 4), const Offset(-100, -80));
    await tester.pump();
    final shrunk = box();
    expect(shrunk.width, lessThan(start.width - 50));
    expect(shrunk.height, lessThan(start.height - 40));
    expect(shrunk.topLeft, start.topLeft);

    // left edge: grow leftwards, right edge stays put
    await tester.dragFrom(Offset(shrunk.left + 6, shrunk.center.dy), const Offset(-60, 0));
    await tester.pump();
    final wider = box();
    expect(wider.width, greaterThan(shrunk.width + 20));
    expect(wider.right, closeTo(shrunk.right, 1));

    // top edge: drag down far past the limit -> stops at the minimum height (300 + the 20px handle margin)
    await tester.dragFrom(Offset(wider.center.dx, wider.top + 6), Offset(0, wider.height * 2));
    await tester.pump();
    expect(box().height, greaterThanOrEqualTo(319));
    expect(box().height, lessThan(shrunk.height));
    expect(tester.takeException(), isNull);
  });
}
