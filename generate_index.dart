// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final baseDir = Directory('historical-reports');
  final outputFile = File('index.html');

  final reports = await getReportList(baseDir);

  final htmlContent = generateHTML(reports);
  await outputFile.writeAsString(htmlContent);

  print('✅ Generated: ${outputFile.path}');
}

Future<List<Map<String, String>>> getReportList(Directory dir) async {
  final reports = <Map<String, String>>[];

  if (!await dir.exists()) return reports;

  final entries = await dir.list().toList();
  for (final entity in entries) {
    if (entity is Directory) {
      final indexFile = File('${entity.path}/index.html');
      if (await indexFile.exists()) {
        reports.add({
          'name': entity.uri.pathSegments[entity.uri.pathSegments.length - 2],
          'url':
              'historical-reports/${entity.uri.pathSegments.last}/index.html',
        });
      }
    }
  }

  // Sort reports (latest first)
  reports.sort(
    (a, b) =>
        parseReportDate(b['name']!).compareTo(parseReportDate(a['name']!)),
  );

  return reports;
}

int parseReportDate(String reportName) {
  final regex = RegExp(r'_(\w+)_(\d{1,2})_(\d{4})_(\d{2})_(\d{2})$');
  final match = regex.firstMatch(reportName);
  if (match == null) return 0;

  final months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  final month = months[match.group(1)!] ?? 1;
  final day = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);

  return DateTime(year, month, day, hour, minute).millisecondsSinceEpoch;
}

String generateHTML(List<Map<String, String>> reports) {
  final rows = reports
      .map((report) {
        final isLatest = report['name'] == reports.first['name'];
        return '''
<tr>
  <td><a href="${report['url']}" class="${isLatest ? 'latest' : ''}">
    ${report['name']}${isLatest ? ' ⬅️ Latest' : ''}
  </a></td>
</tr>
''';
      })
      .join();

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Historical Reports</title>
<style>
  body { font-family: Arial, sans-serif; margin: 20px; }
  h1 { color: #333; }
  table { width: 100%; border-collapse: collapse; }
  th, td { padding: 10px; border: 1px solid #ccc; text-align: left; }
  th { background-color: #f4f4f4; }
  a { text-decoration: none; color: blue; }
  .latest { font-weight: bold; color: green; }
</style>
</head>
<body>
<h1>Historical Reports</h1>
<table>
<thead>
<tr>
  <th>Report</th>
</tr>
</thead>
<tbody>
$rows
</tbody>
</table>
</body>
</html>
''';
}
