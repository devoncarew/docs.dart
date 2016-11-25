
import 'package:analyzer/dart/element/element.dart';

class DocSet {
  /// Pacakges in the DocSet, sorted by package label.
  final List<Package> packages = [];

  DocSet.from(List<LibraryElement> libraries) {
    // TODO: create packages

    // TODO: create libraries

    //   String filePath = lib.definingCompilationUnit.librarySource.fullName;
    //   filePath = path.relative(filePath);
    //   String relativePath = filePath.substring('lib/'.length);
    //   filePath = path.join(outputDir.path, relativePath);
    //   String ext = path.extension(filePath);
    //   filePath = filePath.substring(0, filePath.length - ext.length) + '.html';

  }
}

class Package extends DocumentableElement {
  final DocSet _docset;
  final String name;

  /// The libraries in the Package, sorted by library path.
  final List<Library> libraries = [];

  Package(this._docset, this.name) : super(null);

  String get label => 'package:${name}';
  DocSet get docset => _docset;
}

class Library extends DocumentableElement {
  final String libraryPath;

  Library(Package package, this.libraryPath) : super(package);

  String get label => libraryPath;
  Package get package => parent;
}

abstract class DocumentableElement {
  final DocumentableElement parent;

  DocumentableElement(this.parent);

  /// The user-facing name of the element (`package:foo`).
  String get label;

  DocSet get docset => parent?.docset;
}
