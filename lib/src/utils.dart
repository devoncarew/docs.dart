
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

String getPackageName(File pubspecFile) {
  try {
    String contents = pubspecFile.readAsStringSync();
    var doc = yaml.loadYamlDocument(contents);
    return (doc.contents as Map)['name'];
  } catch (e) {
    return null;
  }
}

// TODO: test
File findPubspecFor(String filePath) {
  Directory dir = new Directory(path.dirname(filePath));

  while (true) {
    if (dir.parent == dir) return null;

    File file = new File(path.join(dir.path, 'pubspec.yaml'));
    if (file.existsSync()) return file;

    dir = dir.parent;
  }
}

void collectDocFiles(List<String> files, [
  String dir = 'lib',
  List<String> filter = const ['packages']
]) {
  for (FileSystemEntity entity in new Directory(dir).listSync(followLinks: false)) {
    String name = path.basename(entity.path);

    if (entity is Directory) {
      if (name.startsWith('.') || filter.contains(name)) continue;
      collectDocFiles(files, entity.path);
    } else if (entity is File && name.endsWith('.dart')) {
      // TODO: Filter out part files?
      files.add(entity.path);
    }
  }
}

String pluralize(String word, int count) => count == 1 ? word : '${word}s';

class DocFailure {
  final String message;
  DocFailure(this.message);
  String toString() => message;
}
