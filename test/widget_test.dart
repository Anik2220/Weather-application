import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('app renders search bar', (tester) async {
    await tester.pumpWidget(const WeatherApp());
    expect(find.byType(TextField), findsOneWidget);
  });
}
