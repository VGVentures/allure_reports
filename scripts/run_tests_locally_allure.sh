#!/usr/bin/env bash
RESULTS_PATH="../allure-results"
RESULTS_BUCKET="integration_tests_results_qa_sandbox"
GCLOUD_RESULTS_DIR="integration_tests_results_qa_sandbox"
REPORT_DIR="../allure-report"


set +e  

rm -rf $RESULTS_PATH/$GCLOUD_RESULTS_DIR

gcloud storage rm --recursive gs://$RESULTS_BUCKET/$GCLOUD_RESULTS_DIR/

flutter test ../integration_test/app_test.dart

set -e

gcloud storage cp --recursive gs://$RESULTS_BUCKET/$GCLOUD_RESULTS_DIR/ $RESULTS_PATH

allure generate --single-file $RESULTS_PATH/$GCLOUD_RESULTS_DIR/ --clean -o "$REPORT_DIR"
allure open "$REPORT_DIR"

