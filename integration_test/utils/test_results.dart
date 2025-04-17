import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'google_cloud_paths.dart';
import 'google_cloud_service.dart';

class TestResults {
  TestResults(String testName) {
    initialize(testName);
  }
  final Map<String, dynamic> _report = {};

  ///Initializes the report with the test name and status as failed.
  void initialize(String testName) {
    _report['name'] = testName;
    _report['status'] = 'failed';
    startTimeStamp();
  }

  ///Returns the report content.
  Map<String, dynamic> getTestData() {
    return Map.unmodifiable(_report);
  }

  ///Sets the start timestamp of the test, as default it uses the current time.
  void startTimeStamp({int? start}) {
    _report['start'] = start ?? DateTime.now().millisecondsSinceEpoch;
  }

  ///Sets the stop timestamp as the current time.
  void stopTimeStamp({int? stop}) {
    _report['stop'] = stop ?? DateTime.now().millisecondsSinceEpoch;
  }

  ///Sets the status of the test as passed.
  void stopAndPass() {
    _report['status'] = 'passed';
    stopTimeStamp();
  }

  /// Add a new step to the report.
  /// The step function is executed and
  /// the status is updated based on the result.
  Future<void> addStep(
    String stepName,
    void Function() stepFunction, {
    dynamic status,
    int? start,
    int? stop,
  }) async {
    try {
      // Add the step with default 'in progress' status
      await registerStep(stepName, status: 'in progress', start: start);

      // Execute the step function
      await Future.sync(() => stepFunction());

      // If successful, update the step status to 'passed'
      await updateStep(stepName, status: 'passed', stop: stop);
    } catch (e) {
      // If an error occurs, update the step status to 'failed'
      await updateStep(stepName, status: 'failed', stop: stop);
      rethrow; // Ensure the test fails as expected
    }
  }

  /// Add a new step to the report with the failed status by default.
  ///
  ///Also start and stop timestamps are set to the current time by default.
  Future<void> registerStep(
    String stepName, {
    dynamic status,
    int? start,
    int? stop,
  }) async {
    // Initialize steps if not already present
    final _ =
        _report.putIfAbsent('steps', () => <Map<String, dynamic>>[])
              as List<Map<String, dynamic>>
          ..add({
            'name': stepName,
            'status': (status ?? 'failed'),
            'start': (start ?? DateTime.now().millisecondsSinceEpoch),
            'stop': (stop ?? DateTime.now().millisecondsSinceEpoch),
          });

    //Add or update Stop timestamp to the whole report
    stopTimeStamp();
  }

  /// Update the last added step [stepName] in the test data
  /// adding passed status by default.
  Future<void> updateStep(
    String stepName, {
    dynamic status,
    int? start,
    int? stop,
  }) async {
    final steps = _report['steps'] as List<Map<String, dynamic>>;
    for (var i = steps.length - 1; i >= 0; i--) {
      if (steps[i]['name'] == stepName) {
        steps[i]['status'] = status ?? 'passed';
        steps[i]['start'] = start ?? steps[i]['start'];
        steps[i]['stop'] = stop ?? DateTime.now().millisecondsSinceEpoch;
        break;
      }
    }
    stopTimeStamp();
  }

  /// Upload the report to Google Cloud Storage
  Future<void> uploadReportToGoogleCloudStorage(String testUDID) async {
    final destinationPath =
        '${GoogleCloudPaths().destinationPath}/$testUDID-result.json';
    await uploadStringToCloudStorage(
      content: jsonEncode(_report),
      bucketName: GoogleCloudPaths().bucketName,
      destinationPath: destinationPath,
    );
  }

  ///Generates an unique ID for the Allure report
  String generateAllureReportId() {
    const uuid = Uuid();
    return uuid.v4(); // Generates a unique ID
  }
}
