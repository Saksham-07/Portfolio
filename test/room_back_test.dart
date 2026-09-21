import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protfolio/features/isometric_room/isometric_room_view.dart';

/// The room's back arrow always goes home: whatever opened the room (retro or the home screen) was replaced, not stacked.
void main() {
  testWidgets('back arrow goes to the home screen', (tester) async {
    final router = GoRouter(initialLocation: '/isometric', routes: [
      GoRoute(path: '/', builder: (c, s) => const Text('HOME')),
      GoRoute(path: '/retro', builder: (c, s) => const Text('RETRO')),
      GoRoute(path: '/isometric', builder: (c, s) => const IsometricRoomView(intro: false)),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.arrow_back));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('RETRO'), findsNothing);
  });
}
