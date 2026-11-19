# Arca Architecture

## Current Shape & Feature Layout

Arca is structured around self-contained, isolated feature modules supported by shared domain infrastructure in `lib/core/` and unified at the composition root in `lib/app/`.

Cross-module imports between features are strictly forbidden (`lib/features/A` must NEVER import `lib/features/B`). Data sharing occurs exclusively via core repositories, and route transitions are completely decoupled from presentation screens using constructor callbacks wired at the router.

```
lib/
├── main.dart                      # Clean application entry point running const ArcaApp()
├── app/                           # Composition root & route orchestrator
│   ├── app.dart                   # ArcaApp (CircuitProvider + WidgetsApp.router)
│   └── router/                    # Route orchestration
│       ├── router.dart            # ArcaRouter, ArcaRouteGuards, AppStackCodec & ArcaRouter.wire
│       └── onboarding_routes.dart # OnboardingRoute, OnboardingModule & OnboardingModuleCodec
├── core/                          # Shared domain entities, repository contracts & infrastructure
│   ├── ai/                        # On-device AI assets (ArcaModelAssets for PP-OCRv6 & MiniLM-L6 PII)
│   ├── capture/                   # On-device document scanning, camera, photo & file picking (DocumentCaptureService)
│   ├── database/                  # On-device SQLite infrastructure (DatabaseConfig, DatabaseService, DatabaseManager, migrations)
│   ├── design_system/             # Foundation UI (ArcaScaffold, ArcaHeader, ArcaButton, ArcaCard, ArcaBadge, ArcaTextField, ArcaProgressBar)
│   └── onboarding/                # OnboardingRepository, onboardingRepoWire (onboarding.dart barrel)
└── features/                      # Isolated, self-contained feature modules
    └── onboarding/                # Inverted and manual onboarding flow (Welcome, SetupChoice, AiPrep, DocumentScan, ExtractedReview, UserName)
```

---

## Seams, Layer Boundaries & Decoupling Principles

### 1. Zero Cross-Feature Imports
- Features are completely self-contained. `lib/features/<name>/` can only import `package:flutter/widgets.dart`, third-party packages, and `package:arca/core/...`.
- No feature may import another feature (`import '../../features/other/...'` is strictly forbidden).

### 2. Decoupled Route Orchestration via Constructor Callbacks
- Presentation screens never import `ArcaRoute`, `routes.dart`, or `package:kaisel/kaisel.dart`.
- Screens express navigation intent exclusively through constructor callbacks (`onStartSetup`, `onSkip`).
- The router in `lib/app/router/` is the sole orchestrator wiring these callbacks to `context.push()` / `context.pop()`, preventing navigation leakage and enabling isolated widget testing.

### 3. Reactive Cross-Module Data Sharing via Core Broadcast Streams
- When multiple features need to observe shared domain state, core repositories expose broadcast streams (`StreamController.broadcast()`).
- Feature BLoCs subscribe to these repository streams, achieving reactive synchronization without inter-BLoC dependencies.

### 4. Interface-Driven Dependency Injection
- Screens, BLoCs, router parameters, and service consumers accept abstract interfaces (`abstract interface class`), never concrete implementations.
- Storage configuration (`DatabaseConfig`), repositories (`OnboardingRepository`), services (`DatabaseService`), and routing (`ArcaRouter`) are declared via declarative `CircuitWire` recipes (`DatabaseConfig.wire`, `DatabaseService.wire`, `OnboardingRepository.wire`, `ArcaRouter.wire`) and resolved through `Circuit.build(wires)`.
- The composition root exposes `Circuit` to the widget tree via `CircuitProvider`, forwarding to interface-typed accessors.
- Test suites interact with interfaces, allowing in-memory fakes or mocks without coupling tests to implementation details.

### 5. Circuitry Dependency Injection Engine (`package:circuitry_flutter`)
- Zero-codegen, pure Dart graph-based dependency injection library backed by an internal Directed Acyclic Graph (DAG) and bridged to Flutter via `CircuitProvider`. Consumed as `package:circuitry_flutter`.
- **Flutter Bridge (`CircuitProvider`, `CircuitState`):**
  - Sealed `CircuitState` hierarchy (`CircuitBuilding`, `CircuitReady`, `CircuitFailure`) for pattern-matched UI rendering.
  - `CircuitProvider` manages async DAG compilation (`Circuit.build`), provides the resolved `Circuit` via internal `_CircuitScope extends InheritedWidget`, and automatically disposes the circuit on unmount.
  - `CircuitProvider.value` enables synchronous injection of pre-built circuits without lifecycle disposal.
  - Explicit accessors `CircuitProvider.of(context)` and `CircuitProvider.maybeOf(context)` without `BuildContext` extension pollution.
- **Record Tuple Keys (`WireKey = (Type, Enum?)`):** Identifies wires by record tuple. Untagged wires use `(T, null)`. Tagged wires constrain tags to `Enum` values (`(T, K)` where `K extends Enum`), supporting Dart dot-shorthands (e.g. `.images`, `.prod`) and multiple registrations of the same generic type without collisions.
- **Declarative Wire Recipes (`CircuitWire`, `Wire<T>`, `AsyncWire<T>`):**
  - `Wire<T>` defines synchronous lazy singletons, constructed on first access or when required by an `AsyncWire` during build.
  - `AsyncWire<T>` defines asynchronous singletons resolved in parallel topological waves during `Circuit.build(wires)`.
- **Accumulator Chaining Builders (`WireBuilder<Acc>`, `AsyncWireBuilder<Acc>`):**
  - Type-safe accumulator chaining via `takes<Next>()` and `takesTagged<Next, K>(tag)` producing `(Acc, Next)`.
  - 1-dependency accumulator passes directly to 1-arg constructor/tear-off (`.to(UserService.new)`).
  - Multi-dependency accumulator unpacks nested record tuples (`(deps) => OrderService(deps.$1, deps.$2)`).
- **DAG Static Validation & Topological Wave Build:**
  - `Circuit.build(wires)` executes full DAG validation before instantiation: duplicate keys (`DuplicateWireException`), missing dependencies (`MissingWireException`), and cycles with cycle paths (`CircularDependencyException`).
  - Resolves `AsyncWire`s in parallel topological waves using `Future.wait`. Automatically tears down partially initialized instances in reverse topological order if any wave throws, preventing resource leakage.
- **Synchronous Runtime Reads (`circuit.get<T>()`, `circuit.getTagged<T, K>(tag)`):**
  - Synchronous lookups and initialization state inspection (`circuit.isInitialized<T>()`, `circuit.isInitializedTagged<T, K>(tag)`). Disposed circuits reject reads with `DisposedCircuitException`. Unregistered lookups throw `WireNotFoundException`.
- **Reverse Topological Wave Disposal (`Circuit.dispose()`):**
  - Idempotent teardown in reverse topological dependency waves (`leaves -> roots`), ensuring consumers are disposed before their underlying dependencies. Clears instance cache on completion to allow garbage collection.
  - Parallel wave execution of `onDispose` callbacks with error collection into `DisposalException`. Subsequent calls are safe no-ops.

| Layer | Responsibility | Imports Permitted | Outgoing Boundary / Seam |
| --- | --- | --- | --- |
| **Domain (`lib/core/<domain>`)** | Core business logic, models, repository interfaces | Pure Dart only (`dart:core`, `dart:async`) | No dependencies on UI or platform SDKs. Shared across features. |
| **Data (`lib/core/<domain>` or `features/*/data`)** | Persistence engines (`sqlite_async`, `shared_preferences`) | Domain interfaces, database drivers | Implements domain repository interfaces with broadcast stream notifications. |
| **Presentation (`features/*/presentation`)** | State management (`flutter_bloc`), screen composition | Design system, Flutter `widgets.dart`, core domain | Translates user events to BLoC events; fires constructor callbacks for navigation. |
| **Core Design System** | Visual tokens, layout primitives, accessible widgets | Flutter `widgets.dart`, `dart:ui` | Independent of feature business logic. Zero Material/Cupertino framework imports. |
| **Composition Root (`lib/app`)** | Dependency injection, router wiring & route guards | Core, Features, and Navigation | Injects concrete repositories and wires callbacks to router actions. |

### Dependency Direction

```
Feature Presentation ──► Core Domain / Repositories ◄── Core Data
         │                         ▲                         │
         ▼                         │                         ▼
Core (Design System)               │                  Core (Database)
         ▲                         │                         ▲
         └───────────────── Composition Root ────────────────┘
```

- High-level policy (Domain) does not depend on low-level detail (Data, UI).
- Presentation depends on Domain models and interfaces, never on Data implementations.
- Data depends on Domain interfaces to fulfill contracts.

---

## Navigation: Dart 3 Sealed-Class Routing with Kaisel

Instead of string/URL-based routing or code-generation, Arca uses `kaisel`:
- **Routes as Values**: Routes are immutable sealed classes extending `KaiselRoute`:
  - `ArcaRoute` (`OnboardingMount`): Top-level mount point for onboarding flow.
  - `OnboardingRoute` (`OnboardingWelcome`): First-launch greeting & privacy value pillars (`WelcomeScreen`).
- **Exhaustive Pattern Matching**: The screen builder in `lib/app/router/router.dart` and `lib/app/router/onboarding_routes.dart` uses Dart 3 `switch` expressions over sealed route hierarchies, guaranteeing at compile-time that every route is handled.
- **Deep Linking**: `AppStackCodec` implements `KaiselStackCodec<ArcaRoute>`, decoding incoming deep links (`/onboarding`) into `[OnboardingMount()]`. `OnboardingModuleCodec` decodes nested paths to preserve natural back navigation.

---

## Libraries and Dependencies

| Dependency | Architectural Purpose |
| --- | --- |
| `cunning_document_scanner` | Native on-device document scanning (VisionKit on iOS, ML Kit on Android) with edge detection and deskewing. |
| `image_picker` | Platform photo library selection and fallback camera photo capture. |
| `file_picker` | Platform document and file selection (PDFs, images) from storage. |
| `circuitry_flutter` | Zero-codegen DAG-based dependency injection engine and Flutter bridge (`CircuitProvider`). |
| `circuitry_devtools_extension` | DevTools extension for inspecting Circuitry dependency graphs. |
| `flutter_onnxruntime` | On-device cross-platform ONNX Runtime execution engine for PP-OCRv6 and MiniLM-L6 PII models. |
| `flutter_bloc` | Predictable, event-driven unidirectional state management for clinical records. |
| `kaisel` | Dart 3 native navigation using sealed classes and stack-as-state model. |
| `collection` | Official Dart collection utilities: `PriorityQueue`, `HeapPriorityQueue`, `binarySearch`, `ListEquality`, `SetEquality`. |
| `async` | Asynchronous operations, stream groups/splitters, cancelable operations, and async caches. |
| `sqlite_async` | High-performance asynchronous SQLite database engine with background isolate execution (transitively manages native `sqlite3` bindings). |
| `path_manager` | Locates local app support directory for the encrypted SQLite database file. |
| `path` | Cross-platform file path manipulation. |
| `shared_preferences` | Lightweight key-value persistence for onboarding completion and active vault selection. |
| `flutter_lints` | Standard Dart/Flutter static analysis rule set. |
| `bloc_test` | Streamlined unit testing for BLoC state transitions. |
| `shared_preferences_platform_interface` | Platform interface for mocking asynchronous key-value persistence in test harnesses. |
| `flutter_test` | Widget and accessibility harness for UI validation. |

---

## Shared vs. Native Platform Responsibilities

- **Shared (Dart / Flutter)**:
  - Clinical domain entities and validation rules
  - Vault state machines and diagnostic event handlers
  - Encryption, indexes, and SQLite schema migrations
  - Custom foundation design system and screen rendering
- **Native Platform (Android / iOS)**:
  - Android: Google Health Connect background permission dispatch and sync workers.
  - iOS: Apple HealthKit background clinical record queries.
  - Camera & On-Device ML: Hardware camera access and local neural acceleration (CoreML / NNAPI).

---

## Verification & Commands

```bash
# Inner loop: verify single touched feature
flutter analyze lib/features/welcome
flutter test test/features/welcome/welcome_screen_test.dart

# Outer gate: full check
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```
