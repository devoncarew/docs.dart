
import 'log.dart';

export 'log.dart' show Progress;

Log log = new Log();

void error([String message]) => log.error(message);
void status([String message]) => log.status(message);
void trace([String message]) => log.trace(message);
