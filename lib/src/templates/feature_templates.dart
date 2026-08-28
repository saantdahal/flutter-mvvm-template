/// Templates for a single MVVM feature slice.
///
/// Layer names mirror this template's vocabulary - `models`, `data`,
/// `repository`, `view_model`, `view` - scoped per feature.
class FeatureTemplates {
  const FeatureTemplates._();

  static const String model = r'''
/// The Model in MVVM: plain data, no Flutter, no network.
class {{feature_pascal}}Model {
  const {{feature_pascal}}Model({required this.id, required this.name});

  factory {{feature_pascal}}Model.fromJson(Map<String, dynamic> json) {
    return {{feature_pascal}}Model(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
    );
  }

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  {{feature_pascal}}Model copyWith({String? id, String? name}) {
    return {{feature_pascal}}Model(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is {{feature_pascal}}Model &&
          other.id == id &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => '{{feature_pascal}}Model(id: $id, name: $name)';
}
''';

  static const String remoteDataSource = r'''
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

abstract class {{feature_pascal}}RemoteDataSource {
  /// Throws an [AppException] when the call fails.
  Future<List<{{feature_pascal}}Model>> get{{feature_plural_pascal}}();
}
''';

  static const String remoteDataSourceImpl = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/app.exception.dart';
import 'package:{{project_name}}/core/network/interceptors/error.interceptor.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.remote.data.source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

class {{feature_pascal}}RemoteDataSourceImpl
    implements {{feature_pascal}}RemoteDataSource {
  const {{feature_pascal}}RemoteDataSourceImpl({required this.dio});

  final Dio dio;

  /// TODO: move this to ApiEndPoints once the real path is known.
  static const String endpoint = '/{{feature_plural}}';

  @override
  Future<List<{{feature_pascal}}Model>> get{{feature_plural_pascal}}() async {
    try {
      final response = await dio.get<dynamic>(endpoint);
      final data = response.data;
      if (data is! List) {
        throw const ServerException('Unexpected response shape.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map({{feature_pascal}}Model.fromJson)
          .toList();
    } on DioException catch (error) {
      // The error interceptor has already classified this.
      throw ErrorInterceptor.toAppException(error);
    }
  }
}
''';

  static const String localDataSource = r'''
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

abstract class {{feature_pascal}}LocalDataSource {
  /// Throws a [CacheException] when nothing is cached.
  Future<List<{{feature_pascal}}Model>> getCached{{feature_plural_pascal}}();

  Future<void> cache{{feature_plural_pascal}}(
    List<{{feature_pascal}}Model> {{feature_plural_camel}},
  );
}
''';

  static const String localDataSourceImpl = r'''
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:{{project_name}}/core/error/app.exception.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.local.data.source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

class {{feature_pascal}}LocalDataSourceImpl
    implements {{feature_pascal}}LocalDataSource {
  const {{feature_pascal}}LocalDataSourceImpl({required this.preferences});

  final SharedPreferences preferences;

  static const String cacheKey = 'cached_{{feature_plural}}';

  @override
  Future<List<{{feature_pascal}}Model>> getCached{{feature_plural_pascal}}() async {
    final raw = preferences.getString(cacheKey);
    if (raw == null) {
      throw const CacheException('No cached {{feature_plural}} available.');
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map({{feature_pascal}}Model.fromJson)
          .toList();
    } on FormatException {
      await preferences.remove(cacheKey);
      throw const CacheException('Cached {{feature_plural}} were corrupted.');
    }
  }

  @override
  Future<void> cache{{feature_plural_pascal}}(
    List<{{feature_pascal}}Model> {{feature_plural_camel}},
  ) async {
    final encoded = jsonEncode(
      {{feature_plural_camel}}.map((item) => item.toJson()).toList(),
    );
    await preferences.setString(cacheKey, encoded);
  }
}
''';

  static const String repositoryContract = r'''
import 'package:{{project_name}}/core/result/result.dart';
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

/// The contract the view model depends on. Swap the implementation in tests
/// by overriding `{{feature_camel}}RepositoryProvider`.
abstract class Base{{feature_pascal}}Repository {
  Future<Result<List<{{feature_pascal}}Model>>> get{{feature_plural_pascal}}();
}
''';

  static const String repositoryImpl = r'''
{{#uses_failures}}
import 'package:{{project_name}}/core/error/app.exception.dart';
import 'package:{{project_name}}/core/error/app.failure.dart';
{{/uses_failures}}
{{#use_connectivity}}
import 'package:{{project_name}}/core/network/network.info.dart';
{{/use_connectivity}}
import 'package:{{project_name}}/core/result/result.dart';
{{#use_local}}
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.local.data.source.dart';
{{/use_local}}
{{#use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.remote.data.source.dart';
{{/use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';
import 'package:{{project_name}}/features/{{feature_name}}/repository/base.{{feature_name}}.repository.dart';

/// Exceptions stop here: everything above sees a [Result].
class {{feature_pascal}}Repository implements Base{{feature_pascal}}Repository {
{{#has_repo_deps}}
  const {{feature_pascal}}Repository({
{{#use_remote}}
    required this.remoteDataSource,
{{/use_remote}}
{{#use_local}}
    required this.localDataSource,
{{/use_local}}
{{#use_connectivity}}
    required this.networkInfo,
{{/use_connectivity}}
  });
{{/has_repo_deps}}
{{^has_repo_deps}}
  const {{feature_pascal}}Repository();
{{/has_repo_deps}}

{{#use_remote}}
  final {{feature_pascal}}RemoteDataSource remoteDataSource;
{{/use_remote}}
{{#use_local}}
  final {{feature_pascal}}LocalDataSource localDataSource;
{{/use_local}}
{{#use_connectivity}}
  final NetworkInfo networkInfo;
{{/use_connectivity}}

  @override
  Future<Result<List<{{feature_pascal}}Model>>>
      get{{feature_plural_pascal}}() async {
{{#use_remote}}
{{#use_connectivity}}
    if (!await networkInfo.isConnected) {
{{#use_local}}
      // Offline: serve whatever was cached on the last successful load.
      return _readCache(fallback: const NetworkFailure());
{{/use_local}}
{{^use_local}}
      return const Err(NetworkFailure());
{{/use_local}}
    }

{{/use_connectivity}}
    try {
      final remote = await remoteDataSource.get{{feature_plural_pascal}}();
{{#use_local}}
      await localDataSource.cache{{feature_plural_pascal}}(remote);
{{/use_local}}
      return Ok(remote);
    } on AppException catch (error) {
{{#use_local}}
      return _readCache(fallback: AppFailure.from(error));
{{/use_local}}
{{^use_local}}
      return Err(AppFailure.from(error));
{{/use_local}}
    } catch (error) {
      return Err(UnknownFailure(error.toString()));
    }
{{/use_remote}}
{{^use_remote}}
{{#use_local}}
    return _readCache(fallback: const CacheFailure());
{{/use_local}}
{{^use_local}}
    // No data source is configured yet - return the seed data.
    return const Ok([
      {{feature_pascal}}Model(id: '1', name: '{{feature_title}} 1'),
      {{feature_pascal}}Model(id: '2', name: '{{feature_title}} 2'),
    ]);
{{/use_local}}
{{/use_remote}}
  }
{{#use_local}}

  /// Reads the cache, reporting [fallback] when there is nothing to read.
  Future<Result<List<{{feature_pascal}}Model>>> _readCache({
    required AppFailure fallback,
  }) async {
    try {
      return Ok(await localDataSource.getCached{{feature_plural_pascal}}());
    } on AppException {
      return Err(fallback);
    }
  }
{{/use_local}}
}
''';

  static const String viewModel = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name}}/core/result/result.dart';
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';
import 'package:{{project_name}}/features/{{feature_name}}/{{feature_name}}.providers.dart';

/// The ViewModel in MVVM.
///
/// It owns the screen's state and nothing else: no Dio, no SharedPreferences,
/// no BuildContext. `build` is called the first time the view watches it, and
/// again after `ref.invalidate`.
class {{feature_pascal}}ViewModel
    extends AsyncNotifier<List<{{feature_pascal}}Model>> {
  @override
  Future<List<{{feature_pascal}}Model>> build() => _load();

  Future<List<{{feature_pascal}}Model>> _load() async {
    final result =
        await ref.read({{feature_camel}}RepositoryProvider)
            .get{{feature_plural_pascal}}();

    // An Err becomes an AsyncError, which the view renders. AppFailure is an
    // Exception, so it can travel through AsyncValue unchanged.
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Re-fetch, showing the spinner.
  Future<void> reload() async {
    state = const AsyncLoading<List<{{feature_pascal}}Model>>();
    state = await AsyncValue.guard(_load);
  }

  /// Re-fetch while keeping the current list on screen (pull to refresh).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}
''';

  static const String providers = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

{{#has_repo_deps}}
import 'package:{{project_name}}/core/providers/core.providers.dart';
{{/has_repo_deps}}
{{#use_local}}
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.local.data.source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.local.data.source.impl.dart';
{{/use_local}}
{{#use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.remote.data.source.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/{{feature_name}}.remote.data.source.impl.dart';
{{/use_remote}}
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';
import 'package:{{project_name}}/features/{{feature_name}}/repository/base.{{feature_name}}.repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/repository/{{feature_name}}.repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/view_model/{{feature_name}}.view.model.dart';

/// Wiring for the {{feature_title}} feature.
///
/// Each layer is a provider, so a test can override any single one of them.
{{#use_remote}}

final {{feature_camel}}RemoteDataSourceProvider =
    Provider<{{feature_pascal}}RemoteDataSource>(
  (ref) => {{feature_pascal}}RemoteDataSourceImpl(dio: ref.watch(dioProvider)),
);
{{/use_remote}}
{{#use_local}}

final {{feature_camel}}LocalDataSourceProvider =
    Provider<{{feature_pascal}}LocalDataSource>(
  (ref) => {{feature_pascal}}LocalDataSourceImpl(
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);
{{/use_local}}

final {{feature_camel}}RepositoryProvider =
    Provider<Base{{feature_pascal}}Repository>(
{{#has_repo_deps}}
  (ref) => {{feature_pascal}}Repository(
{{#use_remote}}
    remoteDataSource: ref.watch({{feature_camel}}RemoteDataSourceProvider),
{{/use_remote}}
{{#use_local}}
    localDataSource: ref.watch({{feature_camel}}LocalDataSourceProvider),
{{/use_local}}
{{#use_connectivity}}
    networkInfo: ref.watch(networkInfoProvider),
{{/use_connectivity}}
  ),
{{/has_repo_deps}}
{{^has_repo_deps}}
  (ref) => const {{feature_pascal}}Repository(),
{{/has_repo_deps}}
);

final {{feature_camel}}ViewModelProvider = AsyncNotifierProvider<
    {{feature_pascal}}ViewModel, List<{{feature_pascal}}Model>>(
  {{feature_pascal}}ViewModel.new,
);
''';

  static const String view = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name}}/core/error/app.failure.dart';
import 'package:{{project_name}}/core/widgets/app.error.widget.dart';
import 'package:{{project_name}}/core/widgets/empty.widget.dart';
import 'package:{{project_name}}/core/widgets/loading.widget.dart';
import 'package:{{project_name}}/features/{{feature_name}}/{{feature_name}}.providers.dart';
import 'package:{{project_name}}/features/{{feature_name}}/widgets/{{feature_name}}.list.item.dart';

/// The View in MVVM: it watches the view model and renders it. No logic here
/// beyond choosing a widget per state.
class {{feature_pascal}}View extends ConsumerWidget {
  const {{feature_pascal}}View({super.key});

  static const String routeName = '{{feature_name}}';
  static const String routePath = '/{{feature_name}}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({{feature_camel}}ViewModelProvider);
    final viewModel = ref.read({{feature_camel}}ViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
{{#use_localization}}
        title: Text('{{feature_name}}.title'.tr()),
{{/use_localization}}
{{^use_localization}}
        title: const Text('{{feature_title}}'),
{{/use_localization}}
      ),
      body: state.when(
        loading: LoadingWidget.new,
        error: (error, stackTrace) => AppErrorWidget(
          error.failureMessage,
          onRetry: viewModel.reload,
        ),
        data: ({{feature_plural_camel}}) {
          if ({{feature_plural_camel}}.isEmpty) {
            return EmptyWidget(
{{#use_localization}}
              message: '{{feature_name}}.empty'.tr(),
{{/use_localization}}
{{^use_localization}}
              message: 'No {{feature_plural}} yet.',
{{/use_localization}}
              onRefresh: viewModel.refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView.builder(
              itemCount: {{feature_plural_camel}}.length,
              itemBuilder: (context, index) => {{feature_pascal}}ListItem(
                {{feature_camel}}: {{feature_plural_camel}}[index],
              ),
            ),
          );
        },
      ),
    );
  }
}
''';

  static const String listItem = r'''
import 'package:flutter/material.dart';

{{#use_resources}}
import 'package:{{project_name}}/core/res/app.context.extension.dart';
{{/use_resources}}
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';

class {{feature_pascal}}ListItem extends StatelessWidget {
  const {{feature_pascal}}ListItem({required this.{{feature_camel}}, super.key});

  final {{feature_pascal}}Model {{feature_camel}};

  @override
  Widget build(BuildContext context) {
{{#use_resources}}
    final dimension = context.resources.dimension;

    return Card(
      elevation: dimension.lightElevation,
      margin: EdgeInsets.symmetric(
        horizontal: dimension.medium,
        vertical: dimension.small,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dimension.radius),
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text({{feature_camel}}.id)),
        title: Text({{feature_camel}}.name),
      ),
    );
{{/use_resources}}
{{^use_resources}}
    return ListTile(
      leading: CircleAvatar(child: Text({{feature_camel}}.id)),
      title: Text({{feature_camel}}.name),
    );
{{/use_resources}}
  }
}
''';

  static const String viewModelTest = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{project_name}}/core/error/app.failure.dart';
import 'package:{{project_name}}/core/result/result.dart';
import 'package:{{project_name}}/features/{{feature_name}}/models/{{feature_name}}.model.dart';
import 'package:{{project_name}}/features/{{feature_name}}/repository/base.{{feature_name}}.repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/{{feature_name}}.providers.dart';

class _Fake{{feature_pascal}}Repository implements Base{{feature_pascal}}Repository {
  const _Fake{{feature_pascal}}Repository(this._result);

  final Result<List<{{feature_pascal}}Model>> _result;

  @override
  Future<Result<List<{{feature_pascal}}Model>>>
      get{{feature_plural_pascal}}() async => _result;
}

void main() {
  const items = [
    {{feature_pascal}}Model(id: '1', name: '{{feature_title}} 1'),
  ];
  const failure = ServerFailure('boom');

  /// `ProviderContainer.test` disposes itself at the end of the test.
  /// Retry is disabled so a failure surfaces immediately instead of being
  /// retried in the background.
  ProviderContainer containerWith(
    Result<List<{{feature_pascal}}Model>> result,
  ) {
    return ProviderContainer.test(
      retry: (retryCount, error) => null,
      overrides: [
        {{feature_camel}}RepositoryProvider.overrideWithValue(
          _Fake{{feature_pascal}}Repository(result),
        ),
      ],
    );
  }

  group('{{feature_pascal}}ViewModel', () {
    test('exposes the repository data', () async {
      final container = containerWith(const Ok(items));

      final value =
          await container.read({{feature_camel}}ViewModelProvider.future);

      expect(value, items);
    });

    test('surfaces a failure as an AsyncError', () async {
      final container = containerWith(const Err(failure));

      await expectLater(
        container.read({{feature_camel}}ViewModelProvider.future),
        throwsA(isA<ServerFailure>()),
      );
      expect(
        container.read({{feature_camel}}ViewModelProvider).hasError,
        isTrue,
      );
    });

    test('refresh re-reads the repository', () async {
      final container = containerWith(const Ok(items));
      await container.read({{feature_camel}}ViewModelProvider.future);

      await container
          .read({{feature_camel}}ViewModelProvider.notifier)
          .refresh();

      expect(
        container.read({{feature_camel}}ViewModelProvider).value,
        items,
      );
    });
  });
}
''';
}

/// Snippets inserted into existing files when wiring a feature up.
class FeatureWiring {
  const FeatureWiring._();

  static const String routeImport = r'''
import 'package:{{project_name}}/features/{{feature_name}}/view/{{feature_name}}.view.dart';
''';

  static const String route = r'''
GoRoute(
  path: {{feature_pascal}}View.routePath,
  name: {{feature_pascal}}View.routeName,
  builder: (context, state) => const {{feature_pascal}}View(),
),
''';

  static const String translationKeys = r'''
  "{{feature_name}}": {
    "title": "{{feature_title}}",
    "empty": "No {{feature_plural}} yet."
  },
''';
}
