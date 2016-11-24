import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as fileSystem;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:package_config/discovery.dart' as package_config;
import 'package:path/path.dart' as path;

import 'globals.dart';
import 'utils.dart';

String get sdkDir => path.dirname(path.dirname(Platform.resolvedExecutable));

List<LibraryElement> parseLibraries(Progress progress, List<String> files) {
  List<LibraryElement> libraries = [];
  DartSdk sdk = new FolderBasedDartSdk(PhysicalResourceProvider.INSTANCE,
      PhysicalResourceProvider.INSTANCE.getFolder(sdkDir));
  List<UriResolver> resolvers = [];

  fileSystem.Folder cwd =
      PhysicalResourceProvider.INSTANCE.getResource('.');
  Map<String, List<fileSystem.Folder>> packageMap = _calculatePackageMap(cwd);
  if (packageMap != null) {
    resolvers.add(new SdkExtUriResolver(packageMap));
    resolvers.add(new PackageMapUriResolver(PhysicalResourceProvider.INSTANCE, packageMap));
    resolvers.add(new DartUriResolver(sdk));
  } else {
    resolvers.add(new DartUriResolver(sdk));
  }
  resolvers.add(
      new fileSystem.ResourceUriResolver(PhysicalResourceProvider.INSTANCE));

  SourceFactory sourceFactory = new SourceFactory(resolvers);

  var options = new AnalysisOptionsImpl();

  AnalysisEngine.instance.processRequiredPlugins();

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
    ..analysisOptions = options
    ..sourceFactory = sourceFactory;

  List<Source> sources = [];

  void processLibrary(String filePath) {
    progress.spin();

    String name = filePath;
    if (name.startsWith(Directory.current.path)) {
      name = name.substring(Directory.current.path.length);
      if (name.startsWith(Platform.pathSeparator)) name = name.substring(1);
    }
    trace('parsing ${name}...');
    JavaFile javaFile = new JavaFile(filePath).getAbsoluteFile();
    Source source = new FileBasedSource(javaFile);
    Uri uri = context.sourceFactory.restoreUri(source);
    if (uri != null) {
      source = new FileBasedSource(javaFile, uri);
    }
    sources.add(source);
    if (context.computeKindOf(source) == SourceKind.LIBRARY) {
      LibraryElement library = context.computeLibraryElement(source);
      libraries.add(library);
    }
  }

  files.forEach(processLibrary);

  // Ensure that the analysis engine performs all remaining work.
  AnalysisResult result = context.performAnalysisTask();
  while (result.hasMoreWork) {
    progress.spin();

    result = context.performAnalysisTask();
  }

  List<AnalysisErrorInfo> errorInfos = [];

  for (Source source in sources) {
    progress.spin();

    context.computeErrors(source);
    errorInfos.add(context.getErrors(source));
  }

  List<_Error> errors = errorInfos
      .expand((AnalysisErrorInfo info) {
        return info.errors.map((error) =>
            new _Error(error, info.lineInfo, '.'));
      })
      .where((_Error error) => error.isError)
      .toList()..sort();

  // double seconds = _stopwatch.elapsedMilliseconds / 1000.0;
  // print("Parsed ${libraries.length} "
  //     "file${libraries.length == 1 ? '' : 's'} in "
  //     "${seconds.toStringAsFixed(1)} seconds.\n");

  if (errors.isNotEmpty) {
    errors.forEach(print);
    int len = errors.length;
    throw new DocFailure(
        "encountered ${len} analysis error${len == 1 ? '' : 's'}");
  }

  return libraries.toList();
}

class _Error implements Comparable<_Error> {
  final AnalysisError error;
  final LineInfo lineInfo;
  final String projectPath;

  _Error(this.error, this.lineInfo, this.projectPath);

  String get description => '${error.message} at ${location}, line ${line}.';
  bool get isError => error.errorCode.errorSeverity == ErrorSeverity.ERROR;
  int get line => lineInfo.getLocation(error.offset).lineNumber;
  String get location {
    String path = error.source.fullName;
    if (path.startsWith(projectPath)) {
      path = path.substring(projectPath.length + 1);
    }
    return path;
  }

  int get severity => error.errorCode.errorSeverity.ordinal;

  String get severityName => error.errorCode.errorSeverity.displayName;

  @override
  int compareTo(_Error other) {
    if (severity == other.severity) {
      int cmp = error.source.fullName.compareTo(other.error.source.fullName);
      return cmp == 0 ? line - other.line : cmp;
    } else {
      return other.severity - severity;
    }
  }

  @override
  String toString() => '[${severityName}] ${description}';
}


Map<String, List<fileSystem.Folder>> _calculatePackageMap(
    fileSystem.Folder dir) {
  Map<String, List<fileSystem.Folder>> map = new Map();
  var info = package_config.findPackagesFromFile(dir.toUri());

  for (String name in info.packages) {
    Uri uri = info.asMap()[name];
    fileSystem.Resource resource =
        PhysicalResourceProvider.INSTANCE.getResource(uri.toFilePath());
    if (resource is fileSystem.Folder) {
      map[name] = [resource];
    }
  }

  return map;
}
