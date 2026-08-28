import 'dart:io';

import 'config.dart';
import 'engine.dart';
import 'templates/feature_templates.dart';
import 'writer.dart';

/// Generates one MVVM feature slice and wires it into the app.
class FeatureGenerator {
  FeatureGenerator({
    required this.writer,
    required this.project,
    required this.feature,
  });

  final ProjectWriter writer;
  final ProjectConfig project;
  final FeatureConfig feature;

  final List<String> warnings = [];

  void generate() {
    final vars = feature.toTemplateVars(project: project);
    // A feature can only talk to the network / cache if the project has them.
    vars['use_remote'] = feature.remote && project.use('network');
    vars['use_local'] = feature.local && project.use('prefs');
    vars['has_repo_deps'] = vars['use_remote'] == true ||
        vars['use_local'] == true ||
        project.use('connectivity');
    // Failures are only constructed when there is a data source that can fail.
    vars['uses_failures'] =
        vars['use_remote'] == true || vars['use_local'] == true;

    final name = vars['feature_name']! as String;
    final base = 'lib/features/$name';

    void emit(String path, String template) =>
        writer.write(path, TemplateEngine.render(template, vars));

    emit('$base/models/$name.model.dart', FeatureTemplates.model);

    if (vars['use_remote'] == true) {
      emit('$base/data/$name.remote.data.source.dart',
          FeatureTemplates.remoteDataSource);
      emit('$base/data/$name.remote.data.source.impl.dart',
          FeatureTemplates.remoteDataSourceImpl);
    }
    if (vars['use_local'] == true) {
      emit('$base/data/$name.local.data.source.dart',
          FeatureTemplates.localDataSource);
      emit('$base/data/$name.local.data.source.impl.dart',
          FeatureTemplates.localDataSourceImpl);
    }

    emit('$base/repository/base.$name.repository.dart',
        FeatureTemplates.repositoryContract);
    emit('$base/repository/$name.repository.dart',
        FeatureTemplates.repositoryImpl);
    emit('$base/view_model/$name.view.model.dart', FeatureTemplates.viewModel);
    emit('$base/$name.providers.dart', FeatureTemplates.providers);

    if (feature.withPage) {
      emit('$base/view/$name.view.dart', FeatureTemplates.view);
      emit('$base/widgets/$name.list.item.dart', FeatureTemplates.listItem);
    }

    if (feature.withTests) {
      // The test runner only discovers files ending in `_test.dart`, so tests
      // keep snake_case even though lib/ uses the dot convention.
      final testName = name.replaceAll('.', '_');
      emit('test/features/$name/${testName}_view_model_test.dart',
          FeatureTemplates.viewModelTest);
    }

    if (feature.wire) {
      _wire(vars);
    }
  }

  /// Riverpod needs no central registration - the feature's own providers file
  /// is the wiring. Only the router and the translations have to be touched.
  void _wire(Map<String, Object?> vars) {
    String render(String template) => TemplateEngine.render(template, vars);

    if (project.use('routing') && feature.withPage) {
      _apply(
        'lib/core/router/app.router.dart',
        'mvvm_gen:imports',
        render(FeatureWiring.routeImport),
        label: 'route import',
      );
      _apply(
        'lib/core/router/app.router.dart',
        'mvvm_gen:routes',
        render(FeatureWiring.route),
        label: 'route',
        uniqueBy: '${vars['feature_pascal']}View.routeName',
      );
    }

    if (project.use('localization') && feature.withPage) {
      _addTranslations(render(FeatureWiring.translationKeys));
    }
  }

  void _apply(
    String path,
    String marker,
    String snippet, {
    required String label,
    String? uniqueBy,
  }) {
    final result = writer.insertBefore(
      path,
      marker,
      snippet,
      uniqueBy: uniqueBy,
    );
    switch (result) {
      case PatchResult.applied:
      case PatchResult.alreadyPresent:
        break;
      case PatchResult.missingFile:
        warnings.add('Could not add $label: $path not found.');
      case PatchResult.missingMarker:
        warnings.add(
          'Could not add $label: marker "// $marker" missing in $path.',
        );
    }
  }

  void _addTranslations(String block) {
    for (final locale in project.locales) {
      final path = 'assets/translations/$locale.json';
      final file = File(writer.pathFor(path));
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();
      if (content.contains('"${feature.name}"')) continue;

      final open = content.indexOf('{');
      if (open == -1) continue;
      final updated =
          content.replaceRange(open + 1, open + 1, '\n$block'.trimRight());
      if (!writer.dryRun) file.writeAsStringSync(updated);
      writer.patched.add(path);
    }
  }
}
