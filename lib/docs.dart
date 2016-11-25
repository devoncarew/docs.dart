
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

import 'src/analysis.dart';
import 'src/generator.dart';
import 'src/globals.dart';
import 'src/model.dart';
import 'src/utils.dart';

export 'src/utils.dart' show DocFailure;

void generateDocs(
  Directory packageDir,
  Directory outputDir, {
  bool verbose,
  bool useColor
}) {
  log.verbose = verbose;
  log.ansi = useColor;

  // Hello to the user.
  String packageName = getPackageName() ?? 'package';
  status('Generating documentation for ${packageName}:'); // TODO:
  status('');

  // Find files.
  List<String> files = [];
  collectDocFiles(files, 'lib', ['src', 'packages']);
  trace('Found ${files.length} documentable ${pluralize('file', files.length)}.');

  // Parse files.
  List<LibraryElement> libraries;
  Progress progress = log.progress('Parsing...');
  try {
    libraries = parseLibraries(progress, files);
    progress.finish(
      'Parsed ${libraries.length} ${ libraries.length == 1 ? 'library' : 'libraries' }.',
      printTiming: true
    );
  } on DocFailure catch (failure) {
    progress.cancel();
    error(failure.toString());
    log.exit(1);
  } finally {
    progress.cancel();
  }

  // Build model.
  DocSet docs = new DocSet.from(libraries);

  // Generate documentation.
  progress = log.progress('Generating docs...');
  try {
    Generator generator = new Generator(docs, outputDir, progress: progress);
    generator.generate();
    progress.finish('Wrote ${generator.filesWritten} files.', printTiming: true);
  } finally {
    progress.cancel();
  }

  // Fini.
  status('');
  status('All done! Documentation written to ${outputDir.path}${Platform.pathSeparator}.');
}
