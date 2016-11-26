
import 'dart:io';

import 'package:docs/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('pluralize', () {
      expect(pluralize('cat', 0), 'cats');
      expect(pluralize('cat', 1), 'cat');
      expect(pluralize('cat', 2), 'cats');
    });

    test('getPackageName', () {
      expect(getPackageName(new File('pubspec.yaml')), 'docs');
    });

    test('collectDocFiles', () {
      List<String> files = [];
      collectDocFiles(files, 'lib', ['src', 'packages']);
      expect(files, hasLength(1));
    });
  });
}
