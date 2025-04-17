# Flutter Integration Tests with Allure Reports

This project showcases how to integrate **Allure Reports** into Flutter integration tests, making it easy to generate clear, structured, and visually rich test reports.

## Project Overview

The project uses a combination of Flutter, Google Cloud Storage, and Allure to automate both the execution of integration tests and the creation of reports that help developers and QA teams better understand test outcomes.

## Project Structure

- `integration_test/` — Contains the Flutter integration test files.
- `scripts/` — Contains helper scripts for running tests and generating reports.
- `allure-results/` — Stores raw test result files.
- `allure-report/` — Stores the generated Allure report.

## Prerequisites

Before you can run the tests and generate the Allure report, make sure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)  
  *(for uploading and downloading test results from GCS)*
- [Allure Commandline](https://docs.qameta.io/allure/#_installing_a_commandline)  
  *(used to generate the HTML report from raw results)*

## Notes on Writing Tests for Allure Reports

In order to produce a structured Allure report, you need to integrate the `TestResults` class into your tests.  
You should wrap each important test action or validation inside the `report.addStep()` method to log the steps clearly.

You can check the implementation example in `integration_test/app_test.dart` to understand how to properly use `TestResults` and `report.addStep()` within your test scenarios.

This will ensure each test step is reported and visualized in the final Allure report.

## How to Run Tests and Generate the Allure Report

Running tests and generating an Allure report is straightforward:

```bash
# Navigate to the scripts folder
cd scripts

# Run the run_tests_locally_allure.sh script
./run_tests_locally_allure.sh
```

## What This Script Does

The `run_tests_locally_allure.sh` script automates the full cycle of testing and reporting:

1. **Cleans up** any old test results in `allure-results/`.
2. **Deletes previous results** from the configured Google Cloud Storage bucket.
3. **Runs your Flutter integration tests** — the default entry point is `integration_test/app_test.dart`.
4. **Downloads the latest test results** from Google Cloud Storage.
5. **Generates an Allure report** in the `allure-report/` folder.
6. **Opens the report** automatically in your default web browser.

## Notes

- Make sure you have access permissions to the Google Cloud Storage bucket defined in the script.
- The script assumes that the Allure CLI is installed and available in your system's PATH.
- If errors occur during execution, the script will log them, but it won’t necessarily stop unless configured to do so.

## License

This project is licensed under the MIT License.  
See the [LICENSE](LICENSE) file for more details.
