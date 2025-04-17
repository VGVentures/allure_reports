// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'google_cloud_paths.dart';

Future<void> uploadStringToCloudStorage({
  required String content,
  required String bucketName,
  required String destinationPath,
}) async {
  // Load credentials
  final credentials = await rootBundle.loadString(
    GoogleCloudPaths().credentialsPath,
  );

  // Authentication
  final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
  final scopes = [StorageApi.devstorageFullControlScope];
  final client = await clientViaServiceAccount(accountCredentials, scopes);

  try {
    final storage = StorageApi(client);
    final bucket = bucketName;

    // Convert the string to bytes
    final bytes = utf8.encode(content);

    // Create Media from the string bytes
    final media = Media(Stream.fromIterable([bytes]), bytes.length);

    // Upload the file (string) to the bucket
    await storage.objects.insert(
      Object()..name = destinationPath,
      bucket,
      uploadMedia: media,
    );

    print('String uploaded successfully to $bucket/$destinationPath');
  } on Exception catch (e) {
    print('Error uploading string: $e');
  } finally {
    client.close();
  }
}
