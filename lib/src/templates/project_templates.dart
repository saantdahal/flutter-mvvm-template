/// Templates for everything outside a feature: app bootstrap, the core layer,
/// configuration files and docs.
///
/// File names follow this template's convention: dot separated, e.g.
/// `app.provider.observer.dart`.
class ProjectTemplates {
  const ProjectTemplates._();

  static const String pubspec = r'''
name: {{project_name}}
description: "{{description}}"
publish_to: "none"
version: {{app_version}}

environment:
  sdk: ^3.5.0

dependencies:
{{dependencies}}
dev_dependencies:
{{dev_dependencies}}
{{#use_localization}}
easy_localization:
  assets_path: assets/translations
  output_dir: lib/core/localization
  output_file: locale_keys.g.dart

{{/use_localization}}
flutter:
  uses-material-design: true
  assets:
    - assets/images/
{{#use_localization}}
    - assets/translations/
{{/use_localization}}
{{#use_env}}
    - .env
{{/use_env}}
{{#use_flavors}}

flavorizr:
  app:
    android:
      flavorDimensions: "flavor-type"
    ios:

  flavors:
    dev:
      app:
        name: "{{display_name}} Dev"
      android:
        applicationId: "{{android_package}}.dev"
      ios:
        bundleId: "{{ios_bundle_id}}.dev"
    stg:
      app:
        name: "{{display_name}} Stg"
      android:
        applicationId: "{{android_package}}.stg"
      ios:
        bundleId: "{{ios_bundle_id}}.stg"
    prod:
      app:
        name: "{{display_name}}"
      android:
        applicationId: "{{android_package}}"
      ios:
        bundleId: "{{ios_bundle_id}}"
{{/use_flavors}}
''';

  static const String main = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
{{#use_firebase}}
import 'package:firebase_core/firebase_core.dart';
{{/use_firebase}}
import 'package:flutter/material.dart';
{{#use_env}}
import 'package:flutter_dotenv/flutter_dotenv.dart';
{{/use_env}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{#use_prefs}}
import 'package:shared_preferences/shared_preferences.dart';
{{/use_prefs}}

import 'package:{{project_name}}/app.dart';
{{#use_firebase}}
import 'package:{{project_name}}/core/notifications/push.notification.service.dart';
{{/use_firebase}}
import 'package:{{project_name}}/core/observers/app.provider.observer.dart';
{{#use_prefs}}
import 'package:{{project_name}}/core/providers/core.providers.dart';
{{/use_prefs}}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
{{#use_localization}}
  await EasyLocalization.ensureInitialized();
{{/use_localization}}
{{#use_env}}
  await dotenv.load(fileName: '.env');
{{/use_env}}
{{#use_firebase}}
  await Firebase.initializeApp();
{{/use_firebase}}
{{#use_prefs}}

  // Resolved here so the rest of the app can read it synchronously.
  final preferences = await SharedPreferences.getInstance();
{{/use_prefs}}

  final container = ProviderScope(
    observers: const [AppProviderObserver()],
    // Riverpod 3 retries a failed provider automatically (10 times, with
    // backoff). That would keep the UI in its loading state instead of
    // showing the error, and{{#use_network}} RetryInterceptor already retries at the HTTP
    // layer{{/use_network}}{{^use_network}} the user has an explicit Retry button{{/use_network}}. Return a Duration here to opt back in.
    retry: (retryCount, error) => null,
{{#use_prefs}}
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
{{/use_prefs}}
{{#use_localization}}
    child: EasyLocalization(
      supportedLocales: const [
{{#locales}}
        Locale('{{language}}'),
{{/locales}}
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('{{default_locale}}'),
      child: const {{app_class}}(),
    ),
{{/use_localization}}
{{^use_localization}}
    child: const {{app_class}}(),
{{/use_localization}}
  );

  runApp(container);
{{#use_firebase}}
  await PushNotificationService().initialize();
{{/use_firebase}}
}
''';

  static const String app = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{#use_responsive}}
import 'package:flutter_screenutil/flutter_screenutil.dart';
{{/use_responsive}}

{{#use_routing}}
import 'package:{{project_name}}/core/router/app.router.dart';
{{/use_routing}}
{{#use_theming}}
import 'package:{{project_name}}/core/theme/app.theme.dart';
{{/use_theming}}
{{^use_routing}}
{{#use_example}}
import 'package:{{project_name}}/features/example/view/example.view.dart';
{{/use_example}}
{{/use_routing}}

/// A [ConsumerWidget] so the app itself can read providers - the router is
/// one, which lets routes depend on app state (auth, onboarding, ...).
class {{app_class}} extends ConsumerWidget {
  const {{app_class}}({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
{{#use_responsive}}
    return ScreenUtilInit(
      designSize: const Size({{design_width}}, {{design_height}}),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const _AppView(),
    );
{{/use_responsive}}
{{^use_responsive}}
    return const _AppView();
{{/use_responsive}}
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
{{#use_routing}}
    return MaterialApp.router(
      title: '{{display_name}}',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
{{/use_routing}}
{{^use_routing}}
    return MaterialApp(
      title: '{{display_name}}',
      debugShowCheckedModeBanner: false,
{{#use_example}}
      home: const ExampleView(),
{{/use_example}}
{{^use_example}}
      home: const Scaffold(body: Center(child: Text('{{display_name}}'))),
{{/use_example}}
{{/use_routing}}
{{#use_theming}}
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
{{/use_theming}}
{{#use_localization}}
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
{{/use_localization}}
    );
  }
}
''';

  static const String coreProviders = r'''
{{#use_network}}
import 'package:dio/dio.dart';
{{/use_network}}
{{#use_env_network}}
import 'package:flutter_dotenv/flutter_dotenv.dart';
{{/use_env_network}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{#use_secure_storage}}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
{{/use_secure_storage}}
{{#use_connectivity}}
import 'package:internet_connection_checker/internet_connection_checker.dart';
{{/use_connectivity}}
{{#use_prefs}}
import 'package:shared_preferences/shared_preferences.dart';
{{/use_prefs}}

{{#use_network}}
import 'package:{{project_name}}/core/constants/app.constants.dart';
import 'package:{{project_name}}/core/network/api.client.dart';
{{#use_secure_storage}}
import 'package:{{project_name}}/core/network/interceptors/auth.interceptor.dart';
{{/use_secure_storage}}
import 'package:{{project_name}}/core/network/interceptors/error.interceptor.dart';
{{#use_localization}}
import 'package:{{project_name}}/core/network/interceptors/headers.interceptor.dart';
{{/use_localization}}
import 'package:{{project_name}}/core/network/interceptors/retry.interceptor.dart';
{{/use_network}}
{{#use_connectivity}}
import 'package:{{project_name}}/core/network/network.info.dart';
import 'package:{{project_name}}/core/network/network.info.impl.dart';
{{/use_connectivity}}
{{#use_secure_storage}}
import 'package:{{project_name}}/core/storage/secure.storage.service.dart';
{{/use_secure_storage}}

/// Application wide dependencies.
///
/// Riverpod *is* the dependency injection container here: every collaborator
/// is a provider, so a test can swap any of them with `overrides`.
{{#use_prefs}}

/// Overridden in `main` once the instance has been resolved.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);
{{/use_prefs}}
{{#use_secure_storage}}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(secureStorageProvider)),
);
{{/use_secure_storage}}
{{#use_connectivity}}

final connectionCheckerProvider = Provider<InternetConnectionChecker>(
  (ref) => InternetConnectionChecker(),
);

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectionCheckerProvider)),
);
{{/use_connectivity}}
{{#use_network}}

/// Base url, from the environment when available.
final baseUrlProvider = Provider<String>((ref) {
{{#use_env_network}}
  return dotenv.env['API_BASE_URL'] ?? AppConstants.fallbackBaseUrl;
{{/use_env_network}}
{{^use_env_network}}
  return AppConstants.fallbackBaseUrl;
{{/use_env_network}}
});

/// An interceptor-free client, used for token refresh and retries so that a
/// failing refresh cannot recurse through the auth interceptor.
final plainDioProvider = Provider<Dio>(
  (ref) => ApiClient.create(baseUrl: ref.watch(baseUrlProvider)),
);

/// The client every remote data source should use.
final dioProvider = Provider<Dio>((ref) {
  return ApiClient.create(
    baseUrl: ref.watch(baseUrlProvider),
    interceptors: [
{{#use_localization}}
      HeadersInterceptor(localeResolver: () => AppConstants.defaultLocale),
{{/use_localization}}
{{#use_secure_storage}}
      AuthInterceptor(
        storage: ref.watch(secureStorageServiceProvider),
        refreshDio: ref.watch(plainDioProvider),
      ),
{{/use_secure_storage}}
      RetryInterceptor(dio: ref.watch(plainDioProvider)),
      const ErrorInterceptor(),
    ],
  );
});
{{/use_network}}
''';

  static const String providerObserver = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{#use_logger}}

import 'package:{{project_name}}/core/utils/app.logger.dart';
{{/use_logger}}
{{^use_logger}}
import 'package:flutter/foundation.dart';
{{/use_logger}}

/// Single place to observe the whole provider graph: what was created, what
/// changed and what failed.
///
/// `ProviderObserver` is a `base` class in Riverpod 3, so the subclass must be
/// marked `final`.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    _log('+ ${_name(context)}');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    _log('~ ${_name(context)} -> ${newValue.runtimeType}');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    _log('- ${_name(context)}');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
{{#use_logger}}
    AppLogger.error('${_name(context)} failed', error, stackTrace);
{{/use_logger}}
{{^use_logger}}
    debugPrint('${_name(context)} failed: $error\n$stackTrace');
{{/use_logger}}
  }

  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  void _log(String message) {
{{#use_logger}}
    AppLogger.debug(message);
{{/use_logger}}
{{^use_logger}}
    if (kDebugMode) debugPrint(message);
{{/use_logger}}
  }
}
''';

  static const String result = r'''
import 'package:{{project_name}}/core/error/app.failure.dart';

/// What every repository returns.
///
/// Repositories never throw: they answer with [Ok] or [Err], and the view
/// model decides what that means for the UI.
sealed class Result<T> {
  const Result();

  /// The value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
''';

  static const String exceptions = r'''
/// Errors thrown by the data layer. They never leave a repository - the
/// repository maps them onto an `AppFailure`.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 5xx, or a response the app could not make sense of.
class ServerException extends AppException {
  const ServerException([
    super.message = 'Server error. Please try again.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

/// 401 / 403 - the caller needs to authenticate again.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// 404.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.'])
      : super(statusCode: 404);
}

/// 400 / 422 with a field-level error map.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.errors = const {},
    super.statusCode = 422,
  });

  final Map<String, List<String>> errors;
}

/// Connect, send or receive timeout.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

/// The device is offline or the host is unreachable.
class NoInternetException extends AppException {
  const NoInternetException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// The request was cancelled before it completed.
class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = 'Request cancelled.']);
}

/// Nothing usable is stored locally.
class CacheException extends AppException {
  const CacheException([super.message = 'No cached data available.']);
}

/// Anything the layers above could not classify.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
''';

  static const String failures = r'''
import 'package:{{project_name}}/core/error/app.exception.dart';

/// The UI-facing error type.
///
/// It implements [Exception] so a view model can rethrow it into an
/// `AsyncValue.error`, which is what the views render.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.statusCode});

  /// Maps a data layer [AppException] (or any error) onto its failure.
  factory AppFailure.from(Object error) {
    return switch (error) {
      AppFailure() => error,
      UnauthorizedException() => UnauthorizedFailure(error.message),
      NotFoundException() => NotFoundFailure(error.message),
      ValidationException() =>
        ValidationFailure(error.message, errors: error.errors),
      RequestTimeoutException() => TimeoutFailure(error.message),
      NoInternetException() => NetworkFailure(error.message),
      RequestCancelledException() => CancelledFailure(error.message),
      CacheException() => CacheFailure(error.message),
      ServerException(:final statusCode?) =>
        ServerStatusFailure(error.message, statusCode: statusCode),
      ServerException() => ServerFailure(error.message),
      AppException() => UnknownFailure(error.message),
      _ => UnknownFailure(error.toString()),
    };
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// A server failure that carries the HTTP status it came from.
final class ServerStatusFailure extends AppFailure {
  const ServerStatusFailure(super.message, {required super.statusCode});
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'No cached data available.']);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([
    super.message = 'The request timed out. Please try again.',
  ]);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.errors = const {}});

  final Map<String, List<String>> errors;
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Request cancelled.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}

/// Turns any error caught by an `AsyncValue` back into a message the UI can
/// show, whether it is an [AppFailure] or something unexpected.
extension ErrorMessage on Object {
  String get failureMessage => switch (this) {
        AppFailure(:final message) => message,
        AppException(:final message) => message,
        _ => toString(),
      };
}
''';

  static const String apiClient = r'''
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Builds the shared [Dio] instance.
///
/// Interceptor order matters - they run top to bottom on the way out and
/// bottom to top on the way back:
///
/// 1. headers     - static + per-request headers
/// 2. auth        - attaches the token, refreshes it on 401
/// 3. retry       - retries transient network failures
/// 4. error       - turns DioException into a typed AppException
/// 5. logging     - debug builds only, must stay last to see everything
class ApiClient {
  const ApiClient._();

  static Dio create({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Let the error interceptor decide what counts as a failure.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.addAll(interceptors);

    assert(() {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
      );
      return true;
    }());

    return dio;
  }
}
''';

  static const String errorInterceptor = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/app.exception.dart';

/// Translates transport level failures into the app's [AppException] types,
/// so data sources never have to interpret Dio internals.
///
/// The exception is attached to `DioException.error`; data sources rethrow it
/// unchanged.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        stackTrace: err.stackTrace,
        error: toAppException(err),
      ),
    );
  }

  static AppException toAppException(DioException error) {
    final existing = error.error;
    if (existing is AppException) return existing;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const RequestTimeoutException(),
      DioExceptionType.connectionError =>
        const NoInternetException(),
      DioExceptionType.cancel => const RequestCancelledException(),
      DioExceptionType.badCertificate =>
        const ServerException('Invalid server certificate.'),
      DioExceptionType.badResponse => _fromResponse(error.response),
      DioExceptionType.unknown when error.error is String =>
        ServerException(error.error! as String),
      _ => const UnknownException(),
    };
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final message = _messageOf(response?.data);

    return switch (status) {
      401 || 403 => UnauthorizedException(
          message ?? 'Your session has expired. Please sign in again.',
        ),
      404 => NotFoundException(message ?? 'Not found.'),
      400 || 422 => ValidationException(
          message ?? 'Some of the submitted values are invalid.',
          errors: _fieldErrorsOf(response?.data),
          statusCode: status,
        ),
      _ => ServerException(
          message ?? 'Server error. Please try again.',
          status,
        ),
    };
  }

  /// Reads the message out of the common `{"message": ...}` /
  /// `{"error": ...}` response shapes.
  static String? _messageOf(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    for (final key in const ['message', 'error', 'detail']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Reads `{"errors": {"email": ["is invalid"]}}` style field errors.
  static Map<String, List<String>> _fieldErrorsOf(Object? data) {
    if (data is! Map<String, dynamic>) return const {};
    final errors = data['errors'];
    if (errors is! Map) return const {};

    return {
      for (final entry in errors.entries)
        entry.key.toString(): switch (entry.value) {
          final List<dynamic> list =>
            list.map((value) => value.toString()).toList(),
          final Object value => [value.toString()],
          null => const <String>[],
        },
    };
  }
}
''';

  static const String retryInterceptor = r'''
import 'dart:async';

import 'package:dio/dio.dart';

/// Retries transient failures (timeouts, dropped connections) with a linear
/// backoff. Only safe methods are retried, so a POST is never sent twice.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxAttempts = 3,
    this.backoff = const [
      Duration(milliseconds: 500),
      Duration(seconds: 2),
    ],
  });

  final Dio dio;
  final int maxAttempts;
  final List<Duration> backoff;

  static const String _attemptKey = 'retry_attempt';
  static const Set<String> _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int? ?? 0) + 1;

    if (!_shouldRetry(err) || attempt >= maxAttempts) {
      return handler.next(err);
    }

    await Future<void>.delayed(
      backoff[(attempt - 1).clamp(0, backoff.length - 1)],
    );

    try {
      final response = await dio.fetch<dynamic>(
        options..extra[_attemptKey] = attempt,
      );
      return handler.resolve(response);
    } on DioException catch (error) {
      return handler.next(error);
    }
  }

  bool _shouldRetry(DioException error) {
    if (!_retryableMethods.contains(error.requestOptions.method.toUpperCase())) {
      return false;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        (error.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
''';

  static const String headersInterceptor = r'''
import 'package:dio/dio.dart';

/// Adds headers that every request should carry.
///
/// [localeResolver] is supplied by the app layer so the data layer never has
/// to reach into the widget tree for the current locale.
class HeadersInterceptor extends Interceptor {
  const HeadersInterceptor({
    this.localeResolver,
    this.extraHeaders = const {},
  });

  final String Function()? localeResolver;
  final Map<String, String> extraHeaders;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final locale = localeResolver?.call();
    if (locale != null && locale.isNotEmpty) {
      options.headers['Accept-Language'] = locale;
    }
    options.headers.addAll(extraHeaders);
    handler.next(options);
  }
}
''';

  static const String authInterceptor = r'''
import 'package:dio/dio.dart';

import 'package:{{project_name}}/core/error/app.exception.dart';
import 'package:{{project_name}}/core/storage/secure.storage.service.dart';

/// Attaches the access token and refreshes it once on a 401.
///
/// Extends [QueuedInterceptor] so that parallel requests failing at the same
/// time trigger a single refresh instead of a stampede.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshDio,
    this.onSessionExpired,
  });

  final SecureStorageService storage;

  /// A bare Dio (no auth interceptor) used for the refresh call itself,
  /// otherwise a failing refresh would recurse.
  final Dio refreshDio;

  /// Called when the session cannot be recovered - sign the user out here.
  final Future<void> Function()? onSessionExpired;

  /// TODO: point this at your refresh endpoint.
  static const String refreshPath = '/auth/refresh';
  static const String _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skip_auth'] != true) {
      final token = await storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (status != 401 || alreadyRetried) {
      return handler.next(err);
    }

    final refreshed = await _refresh();
    if (!refreshed) {
      await storage.clear();
      await onSessionExpired?.call();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: const UnauthorizedException(),
        ),
      );
    }

    try {
      final options = err.requestOptions..extra[_retriedKey] = true;
      final token = await storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.resolve(await refreshDio.fetch<dynamic>(options));
    } on DioException catch (error) {
      return handler.next(error);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        refreshPath,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      final access = data?['access_token'] as String?;
      if (access == null || access.isEmpty) return false;

      await storage.writeAccessToken(access);
      final next = data?['refresh_token'] as String?;
      if (next != null && next.isNotEmpty) {
        await storage.writeRefreshToken(next);
      }
      return true;
    } on DioException {
      return false;
    }
  }
}
''';

  static const String networkInfo = r'''
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
''';

  static const String networkInfoImpl = r'''
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:{{project_name}}/core/network/network.info.dart';

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this.connectionChecker);

  final InternetConnectionChecker connectionChecker;

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
''';

  static const String appTheme = r'''
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF2962FF);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
''';

  static const String appLogger = r'''
import 'package:logger/logger.dart';

/// Thin wrapper so the rest of the app never imports `package:logger`
/// directly - swapping the implementation stays a one file change.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
  );

  static void debug(Object? message) => _logger.d(message);

  static void info(Object? message) => _logger.i(message);

  static void warning(Object? message) => _logger.w(message);

  static void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
''';

  static const String secureStorageService = r'''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Typed access to the encrypted key/value store.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> clear() => _storage.deleteAll();
}
''';

  static const String pushNotificationService = r'''
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Requests permission, wires the Firebase handlers and shows foreground
/// messages through a local notification channel.
class PushNotificationService {
  PushNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High importance notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _messaging.requestPermission();

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<String?> get token => _messaging.getToken();

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
''';

  static const String analysisOptions = r'''
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_final_locals
    - prefer_single_quotes
    - require_trailing_commas
    - unawaited_futures
''';

  static const String gitignore = r'''
# Flutter / Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# Secrets
{{#use_env}}
.env
{{/use_env}}
android/key.properties
**/google-services.json
**/GoogleService-Info.plist

# OS
.DS_Store
''';

  static const String envExample = r'''
# Copy to `.env` (git ignored) and adjust per environment.
API_BASE_URL={{base_url}}
''';

  static const String translations = r'''
{
  "app": {
    "name": "{{display_name}}"
  },
  "common": {
    "retry": "Retry",
    "error": "Something went wrong",
    "loading": "Loading..."
  }
}
''';

  static const String appRouter = r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

{{#use_example}}
import 'package:{{project_name}}/features/example/view/example.view.dart';
{{/use_example}}
// mvvm_gen:imports

/// The router is itself a provider, so routes can depend on app state
/// (auth, onboarding, feature flags) by watching other providers here.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
{{#use_example}}
    initialLocation: ExampleView.routePath,
{{/use_example}}
{{^use_example}}
    initialLocation: '/',
{{/use_example}}
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => RouteErrorView(error: state.error),
    routes: [
{{#use_example}}
      GoRoute(
        path: ExampleView.routePath,
        name: ExampleView.routeName,
        builder: (context, state) => const ExampleView(),
      ),
{{/use_example}}
      // mvvm_gen:routes
    ],
  );
});

class RouteErrorView extends StatelessWidget {
  const RouteErrorView({required this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error?.toString() ?? 'That page does not exist.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
''';

  static const String appConstants = r'''
class AppConstants {
  const AppConstants._();

  static const String appName = '{{display_name}}';
  static const String androidPackage = '{{android_package}}';
  static const String iosBundleId = '{{ios_bundle_id}}';
{{#use_network}}
  static const String fallbackBaseUrl = '{{base_url}}';
{{/use_network}}
{{#use_localization}}
  static const String defaultLocale = '{{default_locale}}';
{{/use_localization}}
}
''';

  static const String apiEndpoints = r'''
/// Every path the app calls, in one place.
class ApiEndPoints {
  const ApiEndPoints._();

  static const String examples = '/posts';
  // mvvm_gen:endpoints
}
''';

  static const String appColors = r'''
import 'package:flutter/material.dart';

/// Raw palette. Nothing outside this file should hardcode a colour.
class BaseColors {
  const BaseColors._();

  static const Color primary = Color(0xFF2962FF);
  static const Color secondary = Color(0xFF00BFA5);
  static const Color error = Color(0xFFD32F2F);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);
}

/// Semantic colours, resolved through `context.resources.color`.
class AppColors {
  const AppColors();

  Color get primary => BaseColors.primary;
  Color get secondary => BaseColors.secondary;
  Color get error => BaseColors.error;
  Color get border => BaseColors.lightGrey;
  Color get hint => BaseColors.grey;
}
''';

  static const String appDimensions = r'''
/// Spacing and sizing scale. Keeps magic numbers out of the widgets.
class AppDimension {
  const AppDimension();

  double get tiny => 4;
  double get small => 8;
  double get medium => 16;
  double get large => 24;
  double get huge => 32;

  double get radius => 12;
  double get lightElevation => 2;
  double get elevation => 6;
}
''';

  static const String resources = r'''
import 'package:flutter/material.dart';

import 'package:{{project_name}}/core/res/colors/app.colors.dart';
import 'package:{{project_name}}/core/res/dimensions/app.dimensions.dart';

/// Entry point for design tokens: `context.resources.color.primary`.
class Resources {
  const Resources(this._context);

  // ignore: unused_field
  final BuildContext _context;

  AppColors get color => const AppColors();

  AppDimension get dimension => const AppDimension();

  static Resources of(BuildContext context) => Resources(context);
}
''';

  static const String contextExtension = r'''
import 'package:flutter/material.dart';

import 'package:{{project_name}}/core/res/resources.dart';

extension ContextResources on BuildContext {
  Resources get resources => Resources.of(this);

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
}
''';

  static const String loadingWidget = r'''
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(label!),
          ],
        ],
      ),
    );
  }
}
''';

  static const String errorWidget = r'''
{{#use_localization}}
import 'package:easy_localization/easy_localization.dart';
{{/use_localization}}
import 'package:flutter/material.dart';

/// Shown wherever an `AsyncValue` is in its error state.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget(this.message, {this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
{{#use_localization}}
                child: Text('common.retry'.tr()),
{{/use_localization}}
{{^use_localization}}
                child: const Text('Retry'),
{{/use_localization}}
              ),
            ],
          ],
        ),
      ),
    );
  }
}
''';

  static const String emptyWidget = r'''
import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({required this.message, this.onRefresh, super.key});

  final String message;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
        Center(child: Text(message, textAlign: TextAlign.center)),
      ],
    );

    if (onRefresh == null) return body;
    return RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}
''';

  static const String readme = r'''
# {{display_name}}

{{description}}

Generated with **mvvm_gen**: MVVM + Riverpod, feature-first.

| Setting | Value |
| --- | --- |
| Package name | `{{project_name}}` |
| Android applicationId | `{{android_package}}` |
| iOS bundle id | `{{ios_bundle_id}}` |
| State management | Riverpod (`AsyncNotifier` view models) |
{{#use_localization}}
| Locales | {{default_locale}} (default) |
{{/use_localization}}

## Getting started

```bash
flutter pub get
{{#use_env}}
cp .env.example .env
{{/use_env}}
flutter run
```

## Structure

```
lib
├── app.dart                 MaterialApp, reads the router provider
├── main.dart                bootstrap + ProviderScope
├── core
│   ├── constants            app + endpoint constants
│   ├── error                AppException / AppFailure
│   ├── result               Result<T> = Ok | Err
{{#use_network}}
│   ├── network              ApiClient + interceptors
{{/use_network}}
│   ├── observers            AppProviderObserver
│   ├── providers            app-wide providers (the DI container)
{{#use_resources}}
│   ├── res                  colors, dimensions, context extension
{{/use_resources}}
{{#use_routing}}
│   ├── router               go_router, exposed as a provider
{{/use_routing}}
│   └── widgets              loading / error / empty
└── features
    └── <feature>
        ├── models           data models
        ├── data             remote + local data sources
        ├── repository       contract + implementation
        ├── view_model       AsyncNotifier
        ├── view             screens
        ├── widgets          feature widgets
        └── <feature>.providers.dart
```

## Adding a feature

```bash
mvvm_gen feature <name>
```

It writes the whole slice and registers it{{#use_routing}}, including the
route{{/use_routing}}. Re-running is safe.

## Native identifiers

```bash
mvvm_gen rename --android-package com.acme.app \
  --ios-bundle-id com.acme.app --display-name "Acme"
```
''';
}
