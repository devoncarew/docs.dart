
import 'dart:async';
import 'dart:io' as io;

class Log {
  bool verbose = false;
  bool ansi = true;

  Progress _currentProgress;

  void error([String message]) {
    _currentProgress?.cancel();
    io.stderr.writeln(message ?? '');
  }

  void status([String message]) {
    _currentProgress?.cancel();
    print(message ?? '');
  }

  void trace([String message]) {
    if (verbose) {
      _currentProgress?.cancel();
      print(message ?? '');
    }
  }

  void exit(int code) {
    io.exit(code);
  }

  Progress progress(String initialMessage) {
    _currentProgress?.cancel();
    _currentProgress = ansi
      ? new _AnsiProgress(this, initialMessage)
      : new _PlainProgress(this, initialMessage);
    return _currentProgress;
  }
}

abstract class Progress {
  void spin();
  void cancel();
  void finish(String message, { bool printTiming: false });
}

class _PlainProgress implements Progress {
  final Log _log;
  final Stopwatch _watch = new Stopwatch()..start();

  bool done = false;

  _PlainProgress(this._log, String initialMessage) {
    print(initialMessage);
  }

  void spin() { }

  void cancel() {
    if (done) return;

    done = true;
    _log._currentProgress = null;
  }

  void finish(String message, { bool printTiming: false }) {
    if (done) return;

    done = true;
    _log._currentProgress = null;
    if (printTiming) {
      print('${message} [${(_watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]');
    } else {
      print(message);
    }
  }
}

class _AnsiProgress {
  static const kPadding = 60;
  static const kSpinInterval = 100;
  static final String _chars = r"/-\!";

  final Log _log;
  final Stopwatch _watch = new Stopwatch()..start();
  String _initialMessage;
  int _frame = 0;
  int _lastFrameTime = -kSpinInterval;
  Timer _timer;

  bool done = false;

  _AnsiProgress(this._log, String initialMessage) {
    _initialMessage = initialMessage.padRight(kPadding);

    _hideCursor();
    _draw(true);

    _timer = new Timer.periodic(new Duration(milliseconds: kSpinInterval), (_) => spin());
  }

  void spin() {
    if (_lastFrameTime + kSpinInterval <= _watch.elapsedMilliseconds) _draw();
  }

  void cancel() {
    if (done) return;

    done = true;
    _timer.cancel();
    _log._currentProgress = null;

    _clearLine();
    _showCursor();
    print(_initialMessage);
  }

  void finish(String message, { bool printTiming: false }) {
    if (done) return;

    done = true;
    _timer.cancel();
    _log._currentProgress = null;

    _clearLine();
    _showCursor();

    if (printTiming) {
      print('${message.padRight(kPadding)} '
        '[${(_watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s]');
    } else {
      print(message);
    }
  }

  void _draw([ bool erase = true ]) {
    if (erase) _clearLine();

    _frame = (_frame + 1) % _chars.length;
    _lastFrameTime = (_watch.elapsedMilliseconds ~/ kSpinInterval) * kSpinInterval;
    io.stdout.write('${_initialMessage} ${_chars.substring(_frame, _frame + 1)}');
  }

  void _clearLine() {
    io.stdout.write('\u001B[1G'); // move to column 1
    io.stdout.write('\u001B[2K'); // clear line
  }

  void _hideCursor() {
    io.stdout.write('\u001B[?25l');
  }

  void _showCursor() {
    io.stdout.write('\u001B[?25h');
  }
}
