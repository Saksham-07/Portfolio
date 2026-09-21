import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:protfolio/features/isometric_room/isometric_room_view.dart';
import 'package:protfolio/features/isometric_room/holo_panels.dart';
import 'package:protfolio/features/isometric_room/room_models.dart';
import 'package:protfolio/features/isometric_room/room_painter.dart';
import 'package:protfolio/features/retro_os/neo_snake_game.dart';
import 'package:protfolio/features/retro_os/contact_window.dart';
import 'package:protfolio/features/retro_os/neo_terminal.dart';
import 'package:protfolio/features/retro_os/neo_ui_lab.dart';
import 'package:protfolio/features/retro_os/portfolio_projects_section.dart';

Widget _host(Widget child, Size size) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: SizedBox(width: size.width, height: size.height, child: child)),
      ),
    );

void main() {
  const sizes = [Size(1200, 800), Size(390, 780)];

  for (final size in sizes) {
    testWidgets('Contact window builds at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const ContactWindow(), size));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('DOWNLOAD RESUME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Terminal answers commands at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const NeoTerminal(), size));
      await tester.enterText(find.byType(TextField), 'skills');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.textContaining('Flutter, Django'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rooms: every room renders; Study desk -> sits, opens holo PROJECTS, stands up at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false)));
      await tester.pump();
      for (final topic in ['PROJECTS', 'CONTACT', 'GAMES', 'ABOUT']) {
        await tester.ensureVisible(find.text(topic));
        await tester.pump();
        await tester.tap(find.text(topic));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      // Study: walk right/up from the spawn point to the desk
      await tester.ensureVisible(find.text('PROJECTS'));
      await tester.pump();
      await tester.tap(find.text('PROJECTS'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PRESS E'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('PRESS E: PROJECTS'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      // walks to the chair, sits (~0.6s), then the panel slides in
      expect(find.byType(HoloProjects), findsNothing);
      for (var i = 0; i < 25 && find.byType(HoloProjects).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HoloProjects), findsOneWidget);
      expect(find.text('PRESS E: PROJECTS'), findsNothing); // seated: no walk-up prompt
      // close -> he stands back up
      await tester.tap(find.byIcon(Icons.close_rounded));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100)); // exit animation, then the seat-to-stand animation
      }
      expect(find.byType(HoloProjects), findsNothing);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rooms: pressing E on ABOUT from the far-left end of the TV zone still sits in the chair at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false)));
      await tester.pump();
      final iso = Iso(Size(size.width, size.height - kToolbarHeight));
      final spot = iso.p(1.6, 1.2); // leftmost end of the TV's reach
      await tester.tapAt(Offset(spot.dx, spot.dy + kToolbarHeight));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('PRESS E: ABOUT ME'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      for (var i = 0; i < 60 && find.byType(HoloAbout).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HoloAbout), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rooms: pressing E while an arrow key is still held still walks to the chair and sits at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false)));
      await tester.pump();
      final iso = Iso(Size(size.width, size.height - kToolbarHeight));
      final spot = iso.p(1.6, 1.2);
      await tester.tapAt(Offset(spot.dx, spot.dy + kToolbarHeight));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('PRESS E: ABOUT ME'), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft); // still pushing into the corner...
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE); // ...when E is pressed
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100)); // key stays held for 1.5s
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      for (var i = 0; i < 60 && find.byType(HoloAbout).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HoloAbout), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rooms: game kiosk -> sits on the pouf, opens the game panel with the kiosk mirroring it at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: IsometricRoomView(intro: false)));
      await tester.pump();
      await tester.ensureVisible(find.text('GAMES'));
      await tester.pump();
      await tester.tap(find.text('GAMES'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // tap the SNAKE kiosk in the scene (body = window minus the 56px app bar)
      final kiosk = rooms[3].props.firstWhere((o) => o.act == Act.snake);
      final c = Iso(Size(size.width, size.height - kToolbarHeight)).propBounds(kiosk).center;
      await tester.tapAt(Offset(c.dx, c.dy + kToolbarHeight));
      for (var i = 0; i < 60 && find.byType(HoloGame).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HoloGame), findsOneWidget);
      expect(find.byType(NeoSnakeGame), findsOneWidget);
      // let the kiosk placeholder animate for a bit
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close_rounded));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(HoloGame), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Holo panels (About / Contact / Projects + detail) build at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const accent = Color(0xFF5EEAD4);
      Future<void> show(Widget w, String title) async {
        await tester.pumpWidget(_host(HoloPanel(title: title, accent: accent, child: w), size));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      await show(const HoloAbout(accent: accent), 'ABOUT ME');
      expect(find.text('SAKSHAM BIR SINGH'), findsOneWidget);
      await show(const HoloContact(accent: accent), 'CONTACT');
      expect(find.text('DOWNLOAD RESUME'), findsOneWidget);
      await show(const HoloProjects(accent: accent), 'PROJECTS');
      await tester.tap(find.text('Merchandising Analytics'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('ALL PROJECTS'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('KEY HIGHLIGHTS'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('KEY HIGHLIGHTS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Projects section lists all cards at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const PortfolioProjectsSection(), size));
      await tester.pump();
      expect(find.text('MERCHANDISING ANALYTICS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Every UI_LAB demo renders without errors at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const NeoUiLab(), size));
      await tester.pump(const Duration(milliseconds: 500));

      for (final tab in ['KPI WHEEL', 'TILE BURST', 'GLASS TILE', 'GLOW TRACE', 'HANG TAG']) {
        await tester.ensureVisible(find.text(tab).first);
        await tester.tap(find.text(tab).first);
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull, reason: '$tab threw');
      }

      // Exercise the tile-burst launch → hold → strips-fall sequence.
      await tester.ensureVisible(find.text('TILE BURST').first);
      await tester.tap(find.text('TILE BURST').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('AUDIT').first);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.takeException(), isNull, reason: 'tile burst frame $i threw');
      }
    });
  }
}
