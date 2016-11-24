
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as path;

import 'impl/html.dart';
import 'src/analysis.dart';
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
  status('Found ${files.length} documentable ${pluralize('file', files.length)}.');

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
  } catch (e) {
    // TODO: better handling of exceptions
    progress.cancel();
    rethrow;
  }

  // Build model.
  DocSet docs = new DocSet.from(libraries);

  // TODO: Generate documentation.
  progress = log.progress('Generating docs...');
  try {
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

    for (var lib in libraries) {
      String filePath = lib.definingCompilationUnit.librarySource.fullName;
      filePath = path.relative(filePath);
      String relativePath = filePath.substring('lib/'.length);
      filePath = path.join(outputDir.path, relativePath);
      String ext = path.extension(filePath);
      filePath = filePath.substring(0, filePath.length - ext.length) + '.html';
      // print(filePath);
      // TODO:
      Html html = new Html();
      html.start(title: relativePath);

      html.startTag('header', attributes: "id=page-header");
      html.tag('p', contents: 'header');
      html.endTag();
      html.startTag('main');
      html.tag('p', contents: 'main');
      html.endTag();
      html.startTag('footer', attributes: "id=page-footer");
      html.tag('p', contents: 'footer');
      html.endTag();

      html.end();

      File file = new File(filePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(html.toString());
    }

    progress.finish('Wrote x files.', printTiming: true);
  } catch (e) {
    progress.cancel();
    rethrow;
  }

  status('');
  status('All done! Documentation written to ${outputDir.path}${Platform.pathSeparator}.');
}
