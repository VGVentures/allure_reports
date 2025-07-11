import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'google_cloud_paths.dart';
import 'google_cloud_service.dart';

/// {@template test_results}
/// A utility class for recording and reporting test results in integration
/// tests with Allure reporting support.
/// {@endtemplate}
///
/// Basic usage:
/// ```dart
/// // Initialize test reporting
/// final report = TestResults('Test Name');
/// final testUUID = report.generateAllureReportId();
/// 
/// // Record test steps
/// await report.addStep('Step description', () async {
///   // Test code here
/// });
/// 
/// // Mark test as passed if all steps succeed
/// report.passTest();
/// 
/// // Upload results in tearDown
/// await report.uploadReportToGoogleCloudStorage(testUUID);
/// ```
class TestResults {
  /// Creates a new test results recorder with the specified test name.
  ///
  /// The test is initially marked as 'failed' and will remain so until
  /// [passTest] is explicitly called.
  ///
  /// {@macro test_results}
  TestResults(String testName) : _uuid = const Uuid(), _report = {} {
    _report['name'] = testName;
    _report['status'] = 'failed';
    startTimeStamp();
  }

  /// The unique identifier generator.
  final Uuid _uuid;

  /// The internal report data structure.
  ///
  /// Contains test name, status, timestamps, and steps information.
  final Map<String, dynamic> _report;

  /// Returns an unmodifiable view of the report content.
  ///
  /// This provides access to the report data without allowing direct
  /// modification.
  Map<String, dynamic> getTestData() {
    return Map.unmodifiable(_report);
  }

  /// Sets the start timestamp of the test.
  ///
  /// By default, it uses the current time if no [start] value is provided.
  ///
  /// [start] - Optional timestamp in milliseconds since epoch
  void startTimeStamp({int? start}) {
    _report['start'] = start ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// Sets the stop timestamp of the test.
  ///
  /// By default, it uses the current time if no [stop] value is provided.
  ///
  /// [stop] - Optional timestamp in milliseconds since epoch
  void stopTimeStamp({int? stop}) {
    _report['stop'] = stop ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// Sets the status of the test as passed.
  ///
  /// This should be called after all test steps have completed successfully.
  void passTest() {
    _report['status'] = 'passed';
  }

  /// Adds a report step and updates its status.
  ///
  /// Registers a step with the given name and executes the provided
  /// function. If the function completes successfully, the step status is set
  /// to 'passed'. If an exception occurs, the step status is set to 'failed'.
  /// The step's start and stop timestamps are recorded automatically.
  ///
  /// - [stepName] - The name of the step to be recorded
  /// - [stepCallback] - The function to execute as part of this step
  /// - [status] - Optional initial status for the step (defaults to 'in
  /// progress')
  /// - [start] - Optional custom start timestamp in milliseconds since epoch
  /// - [stop] - Optional custom stop timestamp in milliseconds since epoch
  ///
  /// Example:
  /// ```dart
  /// await report.addStep('Load widget', () async {
  ///   await tester.pumpWidget(const MyWidget());
  /// });
  /// ```
  Future<void> addStep(
    String stepName,
    FutureOr<void> Function() stepCallback, {
    String? status,
    int? start,
    int? stop,
  }) async {
    try {
      // Add the step with 'in progress' status
      await registerStep(stepName, status: 'in progress', start: start);

      // Execute the step function
      await Future.sync(stepCallback);

      // If successful, update the step status to 'passed'
      await updateStep(stepName, status: 'passed', stop: stop);
    } on Exception {
      // If an error occurs, update the step status to 'failed'
      await updateStep(stepName, status: 'failed', stop: stop);
      rethrow; // Ensure the test fails as expected
    }
  }

  /// Registers a new step in the test report.
  ///
  /// Creates a new step entry with the given name and records its start
  /// and stop timestamps. The step is registered with 'failed' status by
  /// default unless another status is specified.
  ///
  /// - [stepName] - The name of the step to register
  /// - [status] - Optional status of the step (defaults to 'failed')
  /// - [start] - Optional custom start timestamp in milliseconds since epoch
  /// - [stop] - Optional custom stop timestamp in milliseconds since epoch
  Future<void> registerStep(
    String stepName, {
    String? status,
    int? start,
    int? stop,
  }) async {
    // Get the current timestamp for defaults
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Initialize steps the list if not present
    if (!_report.containsKey('steps')) {
      _report['steps'] = <Map<String, dynamic>>[];
    }

    // Add the step to the list
    (_report['steps'] as List<Map<String, dynamic>>).add({
      'name': stepName,
      'status': status ?? 'failed',
      'start': start ?? currentTime,
      'stop': stop ?? currentTime,
    });

    // Update the test's stop timestamp
    stopTimeStamp(stop: stop);
  }

  /// Updates an existing step in the test report.
  ///
  /// Finds the most recent step with the given name and updates its properties.
  /// By default, updates the status to 'passed' and sets the stop timestamp
  /// to the current time if not specified.
  ///
  /// - [stepName] - The name of the step to update
  /// - [status] - Optional new status for the step (defaults to 'passed')
  /// - [start] - Optional new start timestamp in milliseconds since epoch
  /// - [stop] - Optional new stop timestamp in milliseconds since epoch
  ///
  /// Note: This method searches from the most recent step backward to find
  /// the first matching step name.
  Future<void> updateStep(
    String stepName, {
    String? status,
    int? start,
    int? stop,
  }) async {
    // Ensure steps list exists
    if (!_report.containsKey('steps')) {
      return;
    }

    final steps = _report['steps'] as List<Map<String, dynamic>>;

    // Search from most recent step backward
    for (var i = steps.length - 1; i >= 0; i--) {
      if (steps[i]['name'] == stepName) {
        // Update step properties
        steps[i]['status'] = status ?? 'passed';
        steps[i]['start'] = start ?? steps[i]['start'];
        steps[i]['stop'] = stop ?? DateTime.now().millisecondsSinceEpoch;
        break;
      }
    }

    // Update the test's stop timestamp
    stopTimeStamp(stop: stop);
  }

  /// Uploads the test report to Google Cloud Storage.
  ///
  /// Converts the report to JSON and uploads it to the configured Google Cloud
  /// Storage bucket with a filename based on the provided UUID.
  ///
  /// - [testUUID] - The unique identifier for this test run
  ///
  /// This method is typically called in the test's tearDown function after
  /// the test has completed.
  Future<void> uploadReportToGoogleCloudStorage(String testUUID) async {
    final destinationPath =
        '${GoogleCloudPaths().destinationPath}/$testUUID-result.json';

    await uploadStringToCloudStorage(
      content: jsonEncode(_report),
      bucketName: GoogleCloudPaths().bucketName,
      destinationPath: destinationPath,
    );
  }

  /// Generates a unique ID for the Allure report.
  ///
  /// Creates a UUID v4 (random) identifier that can be used to uniquely
  /// identify this test run in Allure reports.
  ///
  /// Returns a string containing the UUID.
  String generateAllureReportId() => _uuid.v4();
}
