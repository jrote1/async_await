// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:barback/barback.dart';

import 'compiler.dart';

/// A [Transformer] that runs the async/await compiler on any .dart files it
/// finds.
class AsyncAwaitTransformer extends Transformer implements LazyTransformer {
  Compiler compiler = new Compiler();

  AsyncAwaitTransformer.asPlugin();

  String get allowedExtensions => ".dart";

  void declareOutputs(DeclaringTransform transform) {
    // Just transforms a Dart file in place.
    transform.declareOutput(transform.primaryId);
  }

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((source) {
      source = compiler.compile(source, transform.primaryInput.id.path,
          (errorCollector) {
            throw new FormatException(
                "Compilation error:\n${errorCollector.errors.join("\n")}");
           });
      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, source));
    });
  }
}
