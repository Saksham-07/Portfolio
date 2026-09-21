import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protfolio/core/routing/replace_route.dart';

void main() {
  testWidgets('replaceRoute asks the browser to replace its history entry (Back stays 1 click)', (tester) async {
    final calls = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, (c) async {
      if (c.method == 'routeInformationUpdated') calls.add(Map<Object?, Object?>.from(c.arguments as Map));
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, null));
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const Text('home')),
      GoRoute(path: '/a', builder: (c, s) => Builder(builder: (c) => TextButton(onPressed: () => replaceRoute(c, '/b'), child: const Text('to b')))),
      GoRoute(path: '/b', builder: (c, s) => const Text('page b')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.go('/a');
    await tester.pumpAndSettle();
    calls.clear();
    await tester.tap(find.text('to b'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(calls.single['uri'], '/b');
    expect(calls.single['replace'], isTrue);
  });
}
