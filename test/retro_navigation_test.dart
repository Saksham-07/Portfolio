import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protfolio/features/retro_os/retro_os_view.dart';

/// What the router tells the browser's history when leaving the retro OS.
void main() {
  Future<List<String>> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, (c) async {
      if (c.method == 'routeInformationUpdated') calls.add('${(c.arguments as Map)['uri']} replace=${(c.arguments as Map)['replace']}');
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, null));
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (c, s) => const Text('HOME')),
      GoRoute(path: '/retro', builder: (c, s) => const RetroOSView()),
      GoRoute(path: '/isometric', builder: (c, s) => const Text('ROOM')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    router.go('/retro'); // like BOOT RETRO OS on the home screen: a normal push
    for (var i = 0; i < 80 && find.text('START').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    calls.clear();
    return calls;
  }

  testWidgets('retro -> 2D room replaces the history entry (Back then goes home)', (tester) async {
    final calls = await open(tester);
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('BOOT 2D ROOM'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('ROOM'), findsOneWidget);
    expect(calls, ['/isometric replace=true']);
  });

  testWidgets('retro SHUTDOWN -> EXIT goes home by replacing the entry (Back does not reopen retro)', (tester) async {
    final calls = await open(tester);
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('SHUTDOWN'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('EXIT'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('HOME'), findsOneWidget);
    expect(calls, ['/ replace=true']);
  });
}
