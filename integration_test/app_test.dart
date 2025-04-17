import 'package:allure_reports/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_results.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const testName = 'Tap on the floating action button, verify counter';
  final report = TestResults(testName);
  final testUDID = report.generateAllureReportId();

  testWidgets(testName, (tester) async {
    await report.addStep('Load app widget', () async {
      await tester.pumpWidget(const MyApp());
    });

    await report.addStep('Verify counter starts at 0', () async {
      expect(find.text('0'), findsOneWidget);
    });

    final fab = find.byKey(const ValueKey('increment'));
    await report.addStep('Finds the floating action button to tap on', () {
      expect(fab, findsOneWidget);
    });

    await report.addStep('Tap on the floating action button', () async {
      await tester.tap(fab);
    });

    await report.addStep('Pump and settle the widget', () async {
      await tester.pumpAndSettle();
    });

    await report.addStep('Verify counter increments by 1', () {
      expect(find.text('1'), findsOneWidget);
    });

    report.stopAndPass();
  });

  tearDown(() async {
    await report.uploadReportToGoogleCloudStorage(testUDID);
  });
}
