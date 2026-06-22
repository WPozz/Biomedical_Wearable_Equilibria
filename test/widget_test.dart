import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Analysis & Trends renders with Stress Index selected by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Analysis & Trends, Alex'), findsOneWidget);
    expect(find.text('Stress Index Trend (Week)'), findsOneWidget);
    expect(find.text('Other Well-being Metrics'), findsOneWidget);
    expect(find.text('Stress Index'), findsOneWidget);
    expect(find.text('WEEK'), findsOneWidget);
    expect(find.text('MONTH'), findsOneWidget);
  });

  testWidgets('Selecting a metric updates the trend chart title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.scrollUntilVisible(
      find.text('Heart Rate Variability'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heart Rate Variability'));
    await tester.pumpAndSettle();

    expect(find.text('Heart Rate Variability Trend (Week)'), findsOneWidget);
  });

  testWidgets('Month toggle and window navigation update visible range',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('MONTH'));
    await tester.pumpAndSettle();

    expect(find.text('Stress Index Trend (Month)'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);

    final Finder nextWindowButton =
        find.widgetWithIcon(IconButton, Icons.chevron_right).first;
    await tester.tap(nextWindowButton);
    await tester.pumpAndSettle();

    expect(find.text('October 2026'), findsOneWidget);
  });
}
