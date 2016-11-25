
import 'dart:io';

import 'package:args/args.dart';
import 'package:docs/docs.dart';
import 'package:docs/src/globals.dart';
import 'package:path/path.dart' as path;

main(List<String> args) {
  ArgParser parser = new ArgParser();
  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    help: 'Print verbose information when running.'
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show command help.'
  );
  parser.addFlag(
    'color',
    defaultsTo: true,
    help: 'Enable or disable ansi drawing.'
  );
  ArgResults argResults;

  try {
    argResults = parser.parse(args);
  } on ArgParserException catch (e) {
    error(e.message);
    error();
    error("Run 'docs -h' for help.");
    log.exit(1);
  }

  if (argResults['help']) {
    status("usage: dart docs");
    status('');
    status(parser.usage);
    log.exit(0);
  }

  Directory out = new Directory(path.join('doc', 'api'));

  generateDocs(
    Directory.current,
    out,
    verbose: argResults['verbose'],
    useColor: argResults['color']
  );
}
