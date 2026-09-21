import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protfolio/features/retro_os/about_window.dart';
import 'package:protfolio/features/retro_os/contact_window.dart';
import 'package:protfolio/features/retro_os/neo_memory_game.dart';
import 'package:protfolio/features/retro_os/neo_minesweeper.dart';
import 'package:protfolio/features/retro_os/neo_snake_game.dart';
import 'package:protfolio/features/retro_os/neo_terminal.dart';
import 'package:protfolio/features/retro_os/neo_ui_lab.dart';
import 'package:protfolio/features/retro_os/portfolio_projects_section.dart';

/// Every retro window's content must lay out without overflow at the smallest window size (and at the default one).
void main() {
  final widgets = <String, Widget Function()>{
    'projects': () => const PortfolioProjectsSection(),
    'about': () => const AboutMeWindow(),
    'contact': () => const ContactWindow(),
    'terminal': () => const NeoTerminal(),
    'snake': () => const NeoSnakeGame(),
    'mines': () => const NeoMinesweeper(),
    'memory': () => const NeoMemoryGame(),
    'uilab': () => const NeoUiLab(),
  };
  for (final e in widgets.entries) {
    for (final (w, h) in [(332.0, 248.0), (420.0, 464.0)]) {
      testWidgets('${e.key} at ${w.toInt()}x${h.toInt()}', (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: w, height: h, child: e.value())))));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  }

  // the exact case from the overflow report: a tile only ~183px wide (a small, resized Projects window)
  for (final (w, h) in [(263.0, 300.0), (263.0, 180.0), (300.0, 200.0)]) {
    testWidgets('projects grid scrolls instead of overflowing at ${w.toInt()}x${h.toInt()}', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: w, height: h, child: const PortfolioProjectsSection())))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }
}
