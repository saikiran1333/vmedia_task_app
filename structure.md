## 1. Architectural Philosophy

Vmedia follows **Feature-First Clean Architecture** combined with modern reactive state management in Flutter. The application is built to scale smoothly across both **iOS and Android** platforms while ensuring high maintainability, strict layer separation, and modular scalability for future real-time media platform features.

### Core Principles
- **Feature Isolation**: Every feature module is self-contained under `lib/src/features/<feature_name>/`.
- **Strict Layer Decoupling**: Data layer, Domain layer, and Presentation layer maintain unidirectional dependency flows (`Presentation -> Domain <- Data`).
- **Single Source of Truth**: UI consumes reactive state through Riverpod `StateNotifier` / `Notifier` ViewModels.
- **Cross-Platform Parity**: Uniform presentation layer targeting both iOS and Android platforms with adaptive, responsive design patterns.

---

## 2. Directory Structure

```text
lib/
├── main.dart                          # App Entrypoint (ProviderScope initialization)
└── src/
    ├── app/
    │   ├── app.dart                   # MaterialApp.router configuration & theme bindings
    │   └── app_router.dart            # Centralized GoRouter navigation definitions
    ├── core/
    │   ├── network/
    │   │   ├── api_endpoints.dart     # API endpoints and base URL configuration
    │   │   ├── app_interceptor.dart   # Dio logging and header injection interceptor
    │   │   ├── dio_client.dart        # Configured Dio HTTP client instance
    │   │   └── network_providers.dart # Riverpod network dependency injection
    │   └── utils/
    │       ├── validators.dart        # Core application validation helpers
    │       └── extensions.dart        # Utility extension methods
    ├── common_widgets/                # Global reusable UI widgets across features
    ├── theme/
    │   ├── vmedia_theme.dart    # Central light/dark Material 3 themes & typography
    │   └── vmedia_responsive.dart # Responsive screen dimensions & device breakpoints
    └── features/
        └── <feature_name>/            # Modular Feature Package
            ├── data/
            │   ├── datasources/       # Remote and local data sources (Dio API calls)
            │   └── repository_impl/   # Concrete repository implementations
            ├── domain/
            │   ├── entities/          # Pure domain business models (Equatable)
            │   └── repositories/      # Abstract repository interfaces
            ├── models/                # DTOs / Data models with json serialization
            └── presentation/
                ├── screens/           # Main feature page widgets
                ├── ui/                # Feature-specific reusable UI components
                ├── utils/             # Feature-specific formatting and validation rules
                └── viewmodels/
                    ├── <feature>_viewmodel.dart # StateNotifier / Notifier logic & providers
                    └── state/
                        └── <feature>_state.dart # Immutable state representation
```

---

## 3. Layer Breakdown & Responsibilities

### Data Layer (`data/`)
- **`datasources/`**: Interacts directly with external APIs or local persistence engines via `Dio` or storage drivers. Always returns data DTOs (`Models`).
- **`repository_impl/`**: Contains concrete repository implementations (`HelloRepositoryImpl`). Implements domain repository interfaces (`domain/repositories/`). Maps data `Models` to domain `Entities` before passing them to the presentation layer.

### Domain Layer (`domain/`)
- **`entities/`**: Core business domain objects using `Equatable` for value comparison. They must remain pure Dart without dependencies on external frameworks or UI libraries.
- **`repositories/`**: Pure abstract classes defining data contracts for feature requirements.

### Data Models (`models/`)
- Contain JSON mapping methods (`fromJson`, `toJson`) and mapper methods (`toEntity()`).

### Presentation Layer (`presentation/`)
- **`screens/`**: Stateful/Stateless screens (`ConsumerStatefulWidget` or `ConsumerWidget`) wired to `GoRouter`.
- **`ui/`**: Specialized components and cards specific to the feature.
- **`utils/`**: Feature-level field validators, form helper tools, and string formatters.
- **`viewmodels/`**: State management logic consuming repositories and mutating immutable state (`HelloState`).
- **`viewmodels/state/`**: State definitions containing explicit status enums (`initial`, `loading`, `success`, `error`), payload data, and error state tracking.

---

## 4. Theme & Responsive Design Standards

All UI components MUST adhere strictly to the central design system defined in `lib/src/theme/`:

1. **Colors & Typography**: Access through `Theme.of(context)`:
   - Primary Accent: `theme.colorScheme.primary`
   - Secondary Color: `theme.colorScheme.secondary`
   - Card/Surface Backgrounds: `theme.colorScheme.surface`
   - Headings & Text: `theme.textTheme.displayMedium`, `theme.textTheme.titleMedium`, `theme.textTheme.bodyMedium`
2. **Responsive Layouts**:
   Initialize `VmediaResponsive.init(context)` or use breakpoints from `VmediaResponsive`:
   - `isSmallPhone`: Width < 360px
   - `isPhone`: Width 360px - 600px
   - `isTablet`: Width 600px - 1024px
   - `isDesktop`: Width >= 1024px

---

## 5. Navigation Guidelines (`GoRouter`)

1. Navigation routing is centralized in `lib/src/app/app_router.dart`.
2. Push screens using type-safe path strings via `context.push('/path')` or `context.go('/path')`.
3. Pop screens using `context.pop()`.
4. When adding new feature routes, declare them inside `app_router.dart` and export screens cleanly.

---

## 6. Cross-Platform Guidelines (iOS & Android)

- **Target Platforms**: Supported and optimized for both iOS and Android devices.
- **Android Configuration**: Managed in `android/app/build.gradle.kts` with namespace `com.vmedia.app`. Minimum SDK version aligned with modern Flutter standards (Min SDK 21+).
- **iOS Configuration**: Configured in `ios/Runner/Info.plist` with `CFBundleDisplayName: Vmedia` and `PRODUCT_BUNDLE_IDENTIFIER: com.vmedia.app`.
- **Platform Insets**: Use `SafeArea` across screens to handle system status bars, notches, and bottom home indicators gracefully on both iOS and Android.

---

## 7. Developer Workflow: Adding a New Feature

When creating a new feature (e.g., `surgery_schedule`):

1. **Create the Folder Structure**:
   `lib/src/features/surgery_schedule/` with `data/datasources`, `data/repository_impl`, `domain/entities`, `domain/repositories`, `models`, and `presentation` folders.
2. **Define Domain Entity**:
   Create `domain/entities/surgery_entity.dart` extending `Equatable`.
3. **Define Model**:
   Create `models/surgery_model.dart` with `fromJson` and `toEntity()`.
4. **Create Datasource & Repository**:
   - `data/datasources/surgery_remote_datasource.dart`
   - `domain/repositories/surgery_repository.dart`
   - `data/repository_impl/surgery_repository_impl.dart`
5. **Create ViewModel & State**:
   - `presentation/viewmodels/state/surgery_state.dart`
   - `presentation/viewmodels/surgery_viewmodel.dart` with Riverpod providers.
6. **Build UI Screens & Widgets**:
   - `presentation/screens/surgery_schedule_screen.dart`
   - `presentation/ui/surgery_card.dart`
7. **Register Route**:
   Add the path and route builder in `lib/src/app/app_router.dart`.
8. **Verify Code Standards**:
   Run `flutter analyze` and `flutter test` to ensure zero errors and valid test coverage.
