// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_await.src.compiler;

import 'dart:io';

import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

import 'package:async_await/src/pretty_printer.dart';
import 'package:async_await/src/xform.dart';

class ErrorCollector extends AnalysisErrorListener {
  final errors = <AnalysisError>[];
  onError(error) => errors.add(error);
}

class Compiler {
  static Compiler _instance = new Compiler();

  AnalysisContext _context;
  DartSdk _sdk;

  Compiler() {
    _context = AnalysisEngine.instance.createAnalysisContext();
    String sdkPath = Platform.environment['DART_SDK'];
    if (sdkPath == null) {
      throw 'Cannot find the Dart SDK (perhaps DART_SDK is not set).';
    }
    _sdk = new DirectoryBasedDartSdk(new JavaFile(sdkPath)) as DartSdk;
    _context.sourceFactory = new SourceFactory([new DartUriResolver(_sdk),
                                                new FileUriResolver()]);
    (_context.analysisOptions as AnalysisOptionsImpl).enableAsync = true;
  }

  CompilationUnit _parse(String source, String path,
      AnalysisErrorListener errorListener) {
    var stringSource = new StringSource(source, path);
    var libraryElement = _context.computeLibraryElement(stringSource);
    return _context.getResolvedCompilationUnit(stringSource, libraryElement);
  }

  static String compile(String source, String path,
      String onError(ErrorCollector errorCollector)) {
    var errorCollector = new ErrorCollector();
    var unit = _instance._parse(source, path, errorCollector);

    if (errorCollector.errors.isNotEmpty) {
      return onError(errorCollector);
    }

    var worklistBuilder = new WorklistBuilder();
    worklistBuilder.visit(unit);
    var transform = new AsyncTransformer();
    var pretty = new PrettyPrinter();
    int position = 0;
    for (var item in worklistBuilder.worklist) {
      pretty.buffer.write(source.substring(position, item.position));
      pretty.visit(transform.visit(item.sourceBody));
      position = item.sourceBody.end;
    }
    pretty.buffer.write(source.substring(position));
    return pretty.buffer.toString();
  }
}
