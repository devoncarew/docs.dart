
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

// TODO: flesh out the model more fully

class DocSet {
  /// Pacakges in the DocSet, sorted by package label.
  final List<Package> packages = [];

  DocSet.from(List<LibraryElement> libraries) {
    _ModelBuilder builder = new _ModelBuilder(libraries, this);
    builder.build();
  }
}

class Package extends DocumentableElement {
  final DocSet _docset;
  final String name;

  /// The libraries in the Package, sorted by library path.
  final List<Library> libraries = [];

  Package(this._docset, this.name) : super(null);

  String get label => name == null ? 'Other' : 'package:${name}';
  DocSet get docset => _docset;
}

class Library extends DocumentableElement {
  final String libraryPath;

  Library(Package package, this.libraryPath) : super(package);

  String get label => libraryPath;
  Package get package => parent;

  /// Sample text for how the user would import this library.
  String get importDirectiveText {
    if (package.name != null) {
      return 'package:${package.name}/${libraryPath}';
    } else {
      return libraryPath;
    }
  }
}

abstract class DocumentableElement {
  final DocumentableElement parent;

  DocumentableElement(this.parent);

  /// The user-facing name of the element (`package:foo`).
  String get label;

  DocSet get docset => parent?.docset;
}

class _ModelBuilder {
  final List<LibraryElement> elementLibraries;
  final DocSet docSet;

  _ModelBuilder(this.elementLibraries, this.docSet) {
    // TODO:

    //   String filePath = lib.definingCompilationUnit.librarySource.fullName;
    //   filePath = path.relative(filePath);
    //   String relativePath = filePath.substring('lib/'.length);
    //   filePath = path.join(outputDir.path, relativePath);
    //   String ext = path.extension(filePath);
    //   filePath = filePath.substring(0, filePath.length - ext.length) + '.html';

  }

  /// A one-time use method.
  void build() {
    for (LibraryElement lib in elementLibraries) {
      String packageName;
      Directory root;

      String filePath = lib.definingCompilationUnit.librarySource.fullName;
      File pubspec = findPubspecFor(filePath);
      if (pubspec != null) {
        packageName = getPackageName(pubspec);
        root = pubspec.parent;
      }

      Package package = getCreatePackage(packageName);
      String libPath;

      if (root != null) {
        libPath = path.relative(filePath, from: root.path);
        if (libPath.startsWith('lib')) {
          libPath = libPath.substring('lib/'.length);
        }
      } else {
        libPath = path.basename(filePath);
      }

      Library library = new Library(package, libPath);
      package.libraries.add(library);
    }
  }

  Package getCreatePackage(String packageName) {
    for (Package p in docSet.packages) {
      if (p.name == packageName) return p;
    }

    Package p = new Package(docSet, packageName);
    docSet.packages.add(p);
    return p;
  }
}

