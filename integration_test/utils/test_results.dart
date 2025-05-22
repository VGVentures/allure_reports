import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'google_cloud_paths.dart';
import 'google_cloud_service.dart';

class TestResults {
  TestResults(String testName) {
    _report['name'] = testName;
    _report['status'] = 'failed';
    startTimeStamp();
  }
  final Map<String, dynamic> _report = {};

  ///Returns the report content.
  Map<String, dynamic> getTestData() {
    return Map.unmodifiable(_report);
  }

  ///Sets the start timestamp of the test, as default it uses the current time.
  void startTimeStamp({int? start}) =>
      _report['start'] = start ?? DateTime.now().millisecondsSinceEpoch;

  ///Sets the stop timestamp as the current time.
  void stopTimeStamp({int? stop}) =>
      _report['stop'] = stop ?? DateTime.now().millisecondsSinceEpoch;

  ///Sets the status of the test as passed.
  void passTest() => _report['status'] = 'passed';

  /// Adds a report step and updates its status based on execution.
  Future<void> addStep(
    String stepName,
    void Function() stepFunction, {
    String? status,
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
    } on Exception {
      // If an error occurs, update the step status to 'failed'
      await updateStep(stepName, status: 'failed', stop: stop);
      rethrow; // Ensure the test fails as expected
    }
  }

  /// Registers a failed step with current timestamps by default.
  Future<void> registerStep(
    String stepName, {
    String? status,
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
    stopTimeStamp(stop: stop);
  }

  /// Updates the given step with 'passed' status and current timestamps.
  Future<void> updateStep(
    String stepName, {
    String? status,
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
    stopTimeStamp(stop: stop);
  }

  /// Uploads the report to Google Cloud Storage
  Future<void> uploadReportToGoogleCloudStorage(String testUUID) async {
    final destinationPath =
        '${GoogleCloudPaths().destinationPath}/$testUUID-result.json';
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
