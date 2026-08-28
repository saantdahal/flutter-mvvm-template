# mvvm_gen

A Flutter project generator for **MVVM + Riverpod**.

It scaffolds a complete, feature-first Flutter project from a configuration you
control — package name, Android `applicationId`, iOS bundle identifier, display
name and the exact set of packages — then keeps generating features into it
that match those choices.

Written in plain Dart with **zero dependencies**: it only uses `dart:io`, so it
runs (or compiles to a single binary) without fetching anything.

```bash
mvvm_gen create shop_app --org com.acme --android-package com.acme.shop
```

## Install

```bash
git clone <this-repo> mvvm_gen && cd mvvm_gen
dart pub global activate --source path .
```

That puts an `mvvm_gen` command on your PATH. Alternatives:

```bash
dart run bin/mvvm_gen.dart <command>              # straight from the repo
dart compile exe bin/mvvm_gen.dart -o mvvm_gen    # standalone binary
```

Requires the Dart SDK ^3.5 (any Flutter install includes one). `flutter` must be
on the PATH for `create` to produce the native platform folders.

## Commands

| Command | What it does |
| --- | --- |
| `create [name]` | Scaffolds a project. Interactive unless `-y` or `--config`. |
| `feature <name>` | Adds a feature slice to an existing project and wires it up. |
| `rename` | Changes the Android package, iOS bundle id and display name. |
| `config [path]` | Writes an `mvvm_gen.yaml` you can edit and reuse. |
| `packages` | Lists the packages the current configuration selects. |
| `help` | Full option reference. |

Common flags: `-y/--yes` (never prompt), `--dry-run`, `--force`,
`--no-flutter-create`, `--pub-get`.

## Initial setup

`mvvm_gen create` walks through the whole setup interactively. Everything it
asks is also available as a flag:

```bash
mvvm_gen create shop_app -y \
  --org com.acme \
  --display-name "Shop App" \
  --android-package com.acme.shop \
  --ios-bundle-id com.acme.shop \
  --platforms android,ios \
  --min-sdk 23 --ios-target 13.0 \
  --locales en,ne
```

It runs `flutter create` for the chosen platforms, writes the architecture on
top, and rewrites every native identifier:

| Setting | Applied to |
| --- | --- |
| `--name` | pubspec `name`, every `package:` import |
| `--display-name` | `android:label`, `CFBundleDisplayName`, web title, `MaterialApp.title` |
| `--android-package` | `namespace`, `applicationId`, and the `MainActivity` package — the file is moved into its new directory |
| `--ios-bundle-id` | `PRODUCT_BUNDLE_IDENTIFIER` for Runner and RunnerTests, plus the macOS `AppInfo.xcconfig` |
| `--min-sdk` | `minSdk` in `android/app/build.gradle.kts` |
| `--ios-target` | `IPHONEOS_DEPLOYMENT_TARGET` and the Podfile platform |
| `--platforms` | which platform folders `flutter create` produces |

Android and iOS identifiers are independent, because Xcode rejects underscores
in bundle ids. By default `my_app` becomes `com.example.my_app` on Android and
`com.example.myApp` on iOS — the same convention `flutter create` uses.

To change them on an existing project later:

```bash
mvvm_gen rename --android-package com.acme.market \
  --ios-bundle-id com.acme.market --display-name "Acme Market"
```

`rename` reads the current values out of the project first, so it also works on
projects this tool did not generate.

## Package selection

Modules decide which packages land in the pubspec — the generated project never
carries a dependency its code does not use. Disable any of them with
`--no-<name>`:

| Module | Packages | Adds |
| --- | --- | --- |
| `network` | `dio`, `pretty_dio_logger` | `ApiClient`, the interceptor stack, remote data sources |
| `connectivity` | `internet_connection_checker` | `NetworkInfo`, offline handling |
| `env` | `flutter_dotenv` | `.env` + `.env.example`, base-url wiring |
| `routing` | `go_router` | router exposed as a provider |
| `localization` | `easy_localization`, `flutter_localizations`, `intl` | JSON translations per locale |
| `responsive` | `flutter_screenutil` | `ScreenUtilInit` with your design size |
| `resources` | — | `res/` colours, dimensions, `context.resources` |
| `theming` | — | `AppTheme` light/dark Material 3 |
| `logger` | `logger` | `AppLogger` wrapper |
| `prefs` | `shared_preferences` | local data sources, cache-on-failure |
| `secure_storage` | `flutter_secure_storage` | `SecureStorageService` + Dio auth interceptor |
| `firebase` | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | `PushNotificationService` |
| `flavors` | `flutter_flavorizr` | dev/stg/prod flavor config |
| `example_feature` | — | a complete worked feature |
| `tests` | — | unit tests for the generated view models |

Add or pin anything else:

```bash
mvvm_gen create app --add "freezed_annotation:^2.4.4" \
  --add-dev "mocktail:^1.0.4" --pin "dio:^5.7.0"
```

Preview the resolution before generating:

```bash
mvvm_gen packages [--config mvvm_gen.yaml]
```

## Repeatable configuration

```bash
mvvm_gen config mvvm_gen.yaml    # write a config file
# edit it
mvvm_gen create --config mvvm_gen.yaml -y
```

```yaml
project:
  name: shop_app
  display_name: "Shop App"
  org: com.acme
  version: 1.0.0+1

platforms:
  targets: [android, ios]
  android:
    package: com.acme.shop
    min_sdk_version: 23
  ios:
    bundle_id: com.acme.shop
    deployment_target: "13.0"

app:
  base_url: https://api.acme.com
  design_width: 375
  design_height: 812

locales: [en, ne]

modules:
  network: true
  firebase: false
  # ...

dependencies:
  overrides:
    dio: ^5.7.0
  extra:
    freezed_annotation: ^2.4.4
```

`create` also drops an `mvvm_gen.yaml` into the generated project, so
`mvvm_gen feature` later reads it and keeps new slices consistent. Without that
file it infers the settings from `pubspec.yaml` and the existing folders.

## Adding features

Run inside a generated project:

```bash
mvvm_gen feature product
mvvm_gen feature cart --no-local
```

Each run writes the full slice:

```
lib/features/product
├── models              product.model.dart
├── data                product.remote.data.source(.impl).dart
│                       product.local.data.source(.impl).dart
├── repository          base.product.repository.dart
│                       product.repository.dart
├── view_model          product.view.model.dart
├── view                product.view.dart
├── widgets             product.list.item.dart
└── product.providers.dart
test/features/product/product_view_model_test.dart
```

With Riverpod there is no service locator to update — the feature's own
`*.providers.dart` **is** the wiring. The generator only has to add the route
and the translation keys, anchored on `// mvvm_gen:` marker comments. It is
idempotent: re-running skips existing files and never inserts a route twice.

Options: `--no-remote`, `--no-local`, `--no-page`, `--no-tests`, `--no-wire`,
`--path <dir>`.

File names follow this template's dot convention (`product.view.model.dart`).
Tests are the exception — the Dart test runner only discovers `*_test.dart`.

## Generated architecture

```
lib
├── app.dart                 MaterialApp, reads the router provider
├── main.dart                bootstrap + ProviderScope
├── core
│   ├── constants            app + endpoint constants
│   ├── error                AppException / AppFailure
│   ├── result               Result<T> = Ok | Err
│   ├── network
│   │   ├── api.client.dart  Dio factory
│   │   ├── network.info.dart
│   │   └── interceptors     auth / error / retry / headers
│   ├── observers            AppProviderObserver
│   ├── providers            app-wide providers (the DI container)
│   ├── res                  colours, dimensions, context extension
│   ├── router               go_router, exposed as a provider
│   ├── theme                light / dark themes
│   ├── utils                logger
│   └── widgets              loading / error / empty
└── features
    └── <feature>            models · data · repository · view_model · view
```

### How MVVM maps onto Riverpod

| MVVM | Here |
| --- | --- |
| **Model** | `models/*.model.dart` — plain data, plus the repository that produces it |
| **View** | `view/*.view.dart` — a `ConsumerWidget` that watches the view model and renders it |
| **ViewModel** | `view_model/*.view.model.dart` — an `AsyncNotifier` exposing `AsyncValue<T>` |

**Riverpod is the DI container.** There is no `get_it`: every collaborator is a
provider, so any layer can be replaced in a test with a single `override`.

```dart
final productRepositoryProvider = Provider<BaseProductRepository>(
  (ref) => ProductRepository(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);
```

**Errors change shape at the boundary.** Data sources throw typed
`AppException`s; the repository catches them and returns `Result<T>` — `Ok` or
`Err(AppFailure)`; the view model turns an `Err` into an `AsyncError` by
rethrowing the failure, which is what `AsyncValue` renders:

```dart
return switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
```

So the View never catches anything — it just handles three states:

```dart
state.when(
  loading: LoadingWidget.new,
  error: (e, _) => AppErrorWidget(e.failureMessage, onRetry: viewModel.reload),
  data: (products) => ...,
);
```

**`AppProviderObserver`** logs every provider add, update, dispose and failure
in one place, installed on the root `ProviderScope`.

**Automatic retry is turned off.** Riverpod 3 retries a failed provider ten
times with backoff, which would leave the UI spinning instead of showing the
error. The scope passes `retry: (_, __) => null`; transient HTTP failures are
retried a layer down by `RetryInterceptor` instead. Return a `Duration` there to
opt back in.

### The interceptor stack

`ApiClient.create` composes them in order — outbound top to bottom, inbound
bottom to top:

| Interceptor | Responsibility |
| --- | --- |
| `HeadersInterceptor` | `Accept-Language` from the app's locale, plus static headers |
| `AuthInterceptor` | attaches the bearer token; on a 401 refreshes once and replays the request. Extends `QueuedInterceptor`, so parallel 401s trigger a single refresh |
| `RetryInterceptor` | linear backoff for timeouts, dropped connections and 5xx — only on `GET`/`HEAD`/`OPTIONS`, so a `POST` is never sent twice |
| `ErrorInterceptor` | maps `DioException` onto the app's `AppException` types |
| `PrettyDioLogger` | debug builds only (behind an `assert`), last so it sees everything |

The refresh call uses `plainDioProvider`, an interceptor-free client, so a
failing refresh cannot recurse.

## Offline behaviour

With both `network` and `prefs` enabled, repositories cache every successful
remote read and fall back to that cache when the request fails or the device is
offline.

## How it works

| Path | Role |
| --- | --- |
| [bin/mvvm_gen.dart](bin/mvvm_gen.dart) | CLI: argument parsing, prompts, command dispatch |
| [lib/src/config.dart](lib/src/config.dart) | `ProjectConfig` / `FeatureConfig`, validation, YAML I/O |
| [lib/src/packages.dart](lib/src/packages.dart) | module → pub package registry |
| [lib/src/engine.dart](lib/src/engine.dart) | mustache-style renderer (`{{var}}`, `{{#flag}}`) |
| [lib/src/templates/](lib/src/templates/) | project and feature templates |
| [lib/src/project_generator.dart](lib/src/project_generator.dart) | runs `flutter create`, writes the project |
| [lib/src/feature_generator.dart](lib/src/feature_generator.dart) | writes a feature slice and wires it in |
| [lib/src/native.dart](lib/src/native.dart) | rewrites Android/iOS/macOS/web/Linux identifiers |
| [lib/src/detect.dart](lib/src/detect.dart) | recovers the configuration of an existing project |
| [lib/src/writer.dart](lib/src/writer.dart) | file writing, `--dry-run`/`--force`, marker patching |

Templates are embedded as raw Dart strings, so a compiled `mvvm_gen` binary is
fully self-contained.

## License

See [LICENSE](LICENSE).
