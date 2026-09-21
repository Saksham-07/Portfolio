import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protfolio/main.dart';

void main() {
  testWidgets('App boots and shows the boot screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyPortfolioApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
