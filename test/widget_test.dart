// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mind_flow/core/services/injection_container.dart' as di;
import 'package:mind_flow/main.dart';

void main() {
  testWidgets('muestra la pantalla principal', (WidgetTester tester) async {
    await di.initServiceLocator();
    await tester.pumpWidget(const AlmaApp());

    expect(find.text('Alma'), findsWidgets);
  });
}
