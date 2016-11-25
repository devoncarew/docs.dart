
import 'package:test/test.dart';
import 'package:docs/src/globals.dart';

import 'impl/support.dart';
import '../bin/docs.dart' as docs_main;

void main() {
  group('cli', () {

    setUp(() {
      log = new TestLog();
    });

    test('help', () {
      try {
        docs_main.main(['--help']);
        fail('expected exit 0');
      } on String catch (exit) {
        expect(exit, 'exit 0');
        expect(_testLog.stdout.toString(), contains('usage: '));
      }
    });

    test('bad option', () {
      try {
        docs_main.main(['--foo']);
        fail('expected exit 1');
      } on String catch (exit) {
        expect(exit, 'exit 1');
        expect(_testLog.stderr.toString(), contains('Could not find an option'));
      }
    });
  });
}

TestLog get _testLog => log as TestLog;
