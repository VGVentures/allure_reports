# Flutter Integration Tests with Allure Reports

This project showcases how to integrate **Allure Reports** into Flutter integration tests — making it simple to generate structured, visually rich test reports that help developers, QA and stakeholders understand test outcomes at a glance.

Read our blog [Elevating Flutter Test Reports with Allure](https://www.verygood.ventures/blog/elevating-flutter-test-reports-with-allure)


---

## 📁 Project Structure

- `integration_test/` — Flutter integration test files.
- `scripts/` — Shell script for running tests and generating report.
- `allure-results/` — Raw Allure test result files.
- `allure-report/` — Generated Allure HTML reports.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) — For uploading/downloading test results from GCS.
- [Allure Commandline](https://docs.qameta.io/allure/#_installing_a_commandline) — For generating HTML reports.

---

## 🧪 Writing Tests for Allure

> **Tip:** You can use this approach with both Flutter's built-in integration_test package and the [Patrol](https://patrol.leancode.co/) framework.


To take full advantage of Allure's structured reporting:

- Use the `TestResults` class in your integration tests.
- Wrap each meaningful step in `report.addStep()` to ensure it's logged and visible in the final report.
- At the end of your test, if no exceptions were thrown, call `report.passTest()` to mark the test as passed in the final report.
- In the `tearDown()` block, export the test results to your storage solution.

➡️ Example usage: see `integration_test/app_test.dart`.

---

## ⚙️ Running Tests & Generating Report Locally

Use the provided script to run integration tests and generate an Allure report locally:

```bash
cd scripts
./run_tests_locally_allure.sh
```

---

## 🔄 What the Script Does

The `run_tests_locally_allure.sh` script automates the entire flow:

1. Cleans up local `allure-results/`.
2. Deletes previous results from your GCS bucket.
3. Runs Flutter integration tests (`integration_test/app_test.dart` by default).
4. Downloads the latest test results from GCS.
5. Generates the Allure HTML report.
6. Opens the report automatically in your browser.

---

## 📌 Notes

- Ensure access to the Google Cloud Storage bucket defined in the script.
- The Allure CLI must be in your system’s PATH.
- To use GCS:
  - Save your service account key in `assets/keys/`.
  - Configure the `GoogleCloudPaths` class with your bucket details.
- You can replace GCS with any other storage service or a local solution.

---

## 🌍 Hosting & Managing Historical Reports on the Web

We’ve set up a system to automatically **generate and host Allure reports** using **GitHub Pages**. This makes the latest and historical test results easily accessible — without any manual work.

- [Historical reports - GitHub Pages](https://ideal-carnival-kr6ykzj.pages.github.io/)

A GitHub Actions workflow handles the entire process:

- Retrieves tests results and generates the Allure HTML report (`--single-file`).
- Archives past reports in a `/historical-reports/` folder.
- Automatically creates or updates a `index.html` with links to all past reports.
- Pushes everything to the `allure-report` branch.
- GitHub Pages serves this branch, making the reports publicly accessible.

📎 You can browse or reuse the full setup in our [GitHub workflow](https://github.com/VGVentures/allure_reports/blob/main/.github/workflows/run-allure-report.yml).  
🛠️ Feel free to adapt it to your project and infrastructure!

---

## 🗂️ Example Structure for Historical Reports (on allure-report branch)

```
/project-root
|── /allure-report    👈 Latest Allure report
|── /allure-results   👈 Latest JSON results files
|── /historical-reports
│     |── report_2025_01_01/index.html
│     |── report_2025_01_02/index.html
│     |── ...
|── index.html         👈 Generated historical report
|── generate_index.dart  👈 Dart script for building the index
```
