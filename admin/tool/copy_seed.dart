// Copies the app's bundled seed data into the admin panel's assets, used by
// "Load starter data" on an empty Firebase project.
//
// Run from the admin folder after changing app/assets/data:
//   dart run tool/copy_seed.dart
// (test/seed_copy_test.dart fails if the copy is out of date.)
import 'dart:io';

void main() {
  final source = Directory('../app/assets/data');
  final target = Directory('assets/seed')..createSync(recursive: true);
  for (final file in source.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final name = file.uri.pathSegments.last;
    file.copySync('${target.path}/$name');
    stdout.writeln('Copied $name');
  }
}
