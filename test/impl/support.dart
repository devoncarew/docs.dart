
import 'package:docs/src/log.dart';

class TestLog implements Log {
  StringBuffer stdout = new StringBuffer();
  StringBuffer stderr = new StringBuffer();

  bool ansi;
  bool verbose;

  @override
  void error([String message]) {
    message == null ? stderr.writeln() : stderr.writeln(message);
  }

  @override
  void exit(int code) {
    throw 'exit ${code}';
  }

  @override
  Progress progress(String initialMessage) {
    stdout.writeln(initialMessage);
    return new _NullProgress(this);
  }

  @override
  void status([String message]) {
    message == null ? stdout.writeln() : stdout.writeln(message);
  }

  @override
  void trace([String message]) {
    message == null ? stdout.writeln() : stdout.writeln(message);
  }
}

class _NullProgress implements Progress {
  final TestLog testLog;

  _NullProgress(this.testLog);

  void cancel() { }

  void finish(String message, { bool printTiming: false }) {
    testLog.stdout.writeln(message);
  }

  void spin() { }
}
