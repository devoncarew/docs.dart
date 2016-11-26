
import 'dart:io';

import 'package:path/path.dart' as path;

import 'css.dart' as css;
import 'globals.dart';
import 'html.dart';
import 'model.dart';

class Generator {
  final DocSet docs;
  final Directory out;
  final Progress progress;

  Generator(this.docs, this.out, { this.progress });

  int filesWritten = 0;

  void generate() {
    if (!out.existsSync()) out.createSync(recursive: true);

    for (Package package in docs.packages) {
      for (Library library in package.libraries) {
        trace('generating ${package.label} ${library.label}');

        // TODO: Emit each package into it's own directory? Only if multiple
        // packages?

        String relativePath = library.libraryPath;
        String filePath = path.join(out.path, relativePath);
        filePath = filePath.substring(
          0, filePath.length - path.extension(filePath).length
        ) + '.html';
        Html html = new Html();
        html.start(
          title: relativePath,
          cssRefs: [css.kSourceSansPro, css.kBootstrap],
          inlineCss: [css.docs]
        );

        html.startTag('header');
        html.startTag('nav');
        html.tag('p', contents: library.importDirectiveText);
        html.endTag(); // nav
        html.endTag(); // header

        html.startTag('main');
        html.tag('p', contents: 'main');
        html.endTag();

        html.startTag('footer');
        html.endTag();

        html.end();

        File file = new File(filePath);
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(html.toString());

        filesWritten++;
        progress?.spin();
      }
    }
  }
}
