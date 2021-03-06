// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for in-memory pipelines.
import 'dart:io';

import 'package:modular_test/src/io_pipeline.dart';

import 'pipeline_common.dart';

main() async {
  var uri = Directory.systemTemp.uri.resolve("io_modular_test_root/");
  int i = 0;
  while (await Directory.fromUri(uri).exists()) {
    uri = Directory.systemTemp.uri.resolve("io_modular_test_root$i/");
    i++;
  }
  runPipelineTest(new IOPipelineTestStrategy(uri));
}

/// The strategy implementation to exercise the pipeline test on a
/// [IOPipeline].
class IOPipelineTestStrategy implements PipelineTestStrategy<IOModularStep> {
  @override
  final Uri testRootUri;

  IOPipelineTestStrategy(this.testRootUri);

  @override
  Future<Pipeline<IOModularStep>> createPipeline(
      Map<Uri, String> sources, List<IOModularStep> steps) async {
    await Directory.fromUri(testRootUri).create();
    for (var uri in sources.keys) {
      var file = new File.fromUri(uri);
      await file.create(recursive: true);
      await file.writeAsStringSync(sources[uri]);
    }
    return new IOPipeline(steps, saveFoldersForTesting: true);
  }

  @override
  IOModularStep createSourceOnlyStep(
          {String Function(Map<Uri, String>) action,
          DataId resultId,
          bool requestSources: true}) =>
      SourceOnlyStep(action, resultId, requestSources);

  @override
  IOModularStep createModuleDataStep(
          {String Function(String) action,
          DataId inputId,
          DataId resultId,
          bool requestModuleData: true}) =>
      ModuleDataStep(action, inputId, resultId, requestModuleData);

  @override
  IOModularStep createLinkStep(
          {String Function(String, List<String>) action,
          DataId inputId,
          DataId depId,
          DataId resultId,
          bool requestDependenciesData: true}) =>
      LinkStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  String getResult(covariant IOPipeline pipeline, Module m, DataId dataId) {
    var folderUri = pipeline.tmpFoldersForTesting[dataId];
    return File.fromUri(folderUri.resolve("${m.name}.${dataId.name}"))
        .readAsStringSync();
  }

  @override
  Future<void> cleanup(Pipeline<IOModularStep> pipeline) async {
    var folders = (pipeline as IOPipeline).tmpFoldersForTesting.values;
    for (var folder in folders) {
      await Directory.fromUri(folder).delete(recursive: true);
    }
    await Directory.fromUri(testRootUri).delete(recursive: true);
  }
}

class SourceOnlyStep implements IOModularStep {
  final String Function(Map<Uri, String>) action;
  final DataId resultId;
  final bool needsSources;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => const [];

  SourceOnlyStep(this.action, this.resultId, this.needsSources);

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    Map<Uri, String> sources = {};

    for (var uri in module.sources) {
      var file = File.fromUri(root.resolveUri(uri));
      String data = await file.exists() ? await file.readAsString() : null;
      sources[uri] = data;
    }
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(action(sources));
  }
}

class ModuleDataStep implements IOModularStep {
  final String Function(String) action;
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  final List<DataId> moduleDataNeeded;
  final DataId resultId;
  final DataId inputId;

  ModuleDataStep(this.action, this.inputId, this.resultId, bool requestInput)
      : moduleDataNeeded = requestInput ? [inputId] : [];

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    var inputData = await _readHelper(module, root, inputId, toUri);
    var result =
        inputData == null ? "data for $module was null" : action(inputData);
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(result);
  }
}

class LinkStep implements IOModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => [inputId];
  final String Function(String, List<String>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;

  LinkStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    List<String> depsData = [];
    for (var dependency in module.dependencies) {
      var depData = await _readHelper(dependency, root, depId, toUri);
      depsData.add(depData);
    }
    var inputData = await _readHelper(module, root, inputId, toUri);
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(action(inputData, depsData));
  }
}

Future<String> _readHelper(Module module, Uri root, DataId dataId,
    ModuleDataToRelativeUri toUri) async {
  var file = File.fromUri(root.resolveUri(toUri(module, dataId)));
  if (await file.exists()) {
    return await file.readAsString();
  }
  return null;
}
