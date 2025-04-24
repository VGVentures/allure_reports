import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final reportsDir = Directory('historical-reports');
  final outputFile = File('index.html');

  if (!reportsDir.existsSync()) {
    print('Error: historical-reports folder not found.');
    return;
  }

  final buffer = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="UTF-8">')
    ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">')
    ..writeln('<title>Historical Reports</title>')
    ..writeln('<style>')
    ..writeln('body { background: #f9fafb; font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; align-items: start; padding: 2em; }')
    ..writeln('.container { background: white; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border-radius: 12px; padding: 2em; max-width: 600px; width: 100%; }')
    ..writeln('h1 { color: #222; text-align: center; }')
    ..writeln('ul { list-style: none; padding: 0; margin-top: 1em; }')
    ..writeln('li { margin: 0.8em 0; display: flex; align-items: center; }')
    ..writeln('a { text-decoration: none; color: #1a73e8; font-size: 1.05em; flex-grow: 1; }')
    ..writeln('a:hover { text-decoration: underline; color: #0c47b7; }')
    ..writeln('.badge { background: #ff5252; color: white; font-size: 0.75em; padding: 2px 6px; border-radius: 8px; margin-left: 8px; }')
    ..writeln('.footer { text-align: center; margin-top: 2em; font-size: 0.9em; color: #777; }')
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<div class="container">')
    ..writeln('<h1>Historical Reports</h1>')
    ..writeln('<p style="color: #555; font-size: 0.95em;">If you don\'t see the latest report, wait a few minutes — we might still be processing something.</p>')
    ..writeln('<ul>');

  final subDirs = reportsDir
      .listSync()
      .whereType<Directory>()
      .where((dir) => dir.path.contains(RegExp(r'report_')))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));  // Newest first!

  int count = 0;

  for (var i = 0; i < subDirs.length; i++) {
    final dir = subDirs[i];
    final dirName = p.basename(dir.path);
    final indexFile = File(p.join(dir.path, 'index.html'));

    if (indexFile.existsSync()) {
      buffer.write('<li><a href="historical-reports/$dirName/index.html">$dirName</a>');
      if (i == 0) {
        buffer.write('<span class="badge">Latest</span>');
      }
      buffer.writeln('</li>');
      count++;
    }
  }

  if (count == 0) {
    buffer.writeln('<li>No reports found.</li>');
  }

  buffer
    ..writeln('</ul>')
    ..writeln('<div class="footer">Generated on ${DateTime.now().toLocal()}</div>')
    ..writeln('</div>')
    ..writeln('</body>')
    ..writeln('</html>');

  await outputFile.writeAsString(buffer.toString());

  print('✅ index.html generated with $count reports.');
}
