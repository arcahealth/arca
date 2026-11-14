# Decisions

## 2026-11-14: Migrate Composition Root to Wire & Circuit Dependency Injection

- **Status:** agreed
- **Request:** Decommission `ArcaContainer` and migrate the application composition root, router, database, and repository wiring to the declarative Wire & Circuit DAG dependency injection engine in `lib/core/di/di.dart`.
- **Scope:** `lib/app/`, `lib/core/database/`, `lib/core/onboarding/`, `test/core/database/`, `docs/`, `README.md`.
- **Choices:**
  - **Decommission `ArcaContainer`:** Removed `ArcaContainer` and its associated enum states in favor of pure declarative `CircuitWire` definitions (`primaryDBWire`, `onboardingRepoWire`, `appRouterWire`) resolved via `Circuit.build(wires)`.
  - **Cached Future in `ArcaApp` Composition Root:** Preserved `StatefulWidget` lifecycle in `ArcaApp` caching `_circuitBuilder = Circuit.build(widget.wires)` in `initState()`, preventing duplicate DAG construction and database pool initialization across widget rebuilds.
  - **Pattern Matching `FutureBuilder` Snapshot:** Pattern match `AsyncSnapshot<Circuit>` with `AsyncSnapshot<Circuit>(connectionState: .done, data: final circuit?)` to seamlessly bind the resolved `circuit`, provide it via `RepositoryProvider<Circuit>.value`, and look up `circuit.get<KaiselRouterConfig>()`.
  - **Colocate `DatabaseManager` into `database_service.dart`:** Merged `DatabaseManager` with the `DatabaseService` abstract interface to keep SQLite connection pool management cohesive alongside `primaryDBWire`.

## 2026-11-14: Wire & Circuit Minimal v1 Dependency Injection Engine

- **Status:** agreed
- **Request:** Replace legacy token-based compiled dependency graph prototype with the Wire & Circuit Minimal v1 specification: pure Dart 3.13+ zero-codegen, graph-based dependency injection engine backed by an internal Directed Acyclic Graph (DAG) in `lib/core/di/di.dart`.
- **Scope:** `lib/core/di/di.dart`, `test/core/di/wire_test.dart`, `test/core/di/circuit_test.dart`, `docs/`, `README.md`.
- **Choices:**
  - **Record Tuple Keys (`WireKey = (Type, Enum?)`):** Identifies wires with Dart 3 record tuples. Untagged wires use `(T, null)`. Tagged wires constrain tags to `Enum` values (`(T, K)` where `K extends Enum`), supporting Dart dot-shorthands (e.g. `.images`, `.prod`) and distinct registrations of the same underlying Dart type without collisions.
  - **Declarative Wire Recipes (`CircuitWire`, `Wire<T>`, `AsyncWire<T>`):**
    - `Wire<T>` defines synchronous lazy singletons, constructed on first access or when demanded by an `AsyncWire` during build.
    - `AsyncWire<T>` defines asynchronous singletons resolved in parallel topological waves during `Circuit.build(wires)`.
  - **Accumulator Chaining Builders (`WireBuilder<Acc>`, `AsyncWireBuilder<Acc>`):**
    - Type-safe accumulator chaining via `takes<Next>()` and `takesTagged<Next, K>(tag)` producing `(Acc, Next)`.
    - Single dependency accumulator passes directly to 1-arg constructor/tear-off (`.to(UserService.new)`).
    - Multi-dependency accumulator unpacks nested record tuples (`(deps) => OrderService(deps.$1, deps.$2)` or `final ((db, cache), auth) = deps`).
  - **DAG Static Validation & Topological Wave Build:**
    - `Circuit.build(wires)` executes full DAG validation before instantiation:
      - Duplicate keys throw `DuplicateWireException`.
      - Missing dependencies throw `MissingWireException` with `missingKey` and `requiredBy`.
      - Circular dependencies throw `CircularDependencyException` with cycle path.
    - Parallel wave resolution of all `AsyncWire`s using `Future.wait` across topological levels. Automatically tears down partially initialized instances in reverse topological order if wave resolution throws.
  - **Synchronous Runtime Reads (`circuit.get<T>()`, `circuit.getTagged<T, K>(tag)`):**
    - Instantaneous $O(1)$ lookups into the singleton cache with initialization inspection (`circuit.isInitialized<T>()`, `circuit.isInitializedTagged<T, K>(tag)`).
    - Sync wires are lazily instantiated and cached on first read.
    - Disposed circuits reject reads with `DisposedCircuitException`. Unregistered lookups throw `WireNotFoundException`.
  - **Reverse Topological Wave Disposal (`Circuit.dispose()`):**
    - Idempotent teardown in reverse topological dependency waves (`leaves -> roots`), ensuring consumers are disposed before their underlying dependencies. Clears instance cache on completion to allow garbage collection.
    - Parallel wave execution of `onDispose` callbacks with error collection into `DisposalException`. Subsequent calls are safe no-ops.

## 2026-11-13: Compiled Dependency Graph System Architecture & Lifecycles

- **Status:** agreed
- **Request:** Implement a self-contained runtime dependency management system in `lib/core/di/di.dart` for Dart 3.13+ without reflection, code generation, mirrors, or `Function.apply`. Deliver immutable compiled topology, typed dependency tokens, explicit declared boundaries, reference-counted ownership (`retain`, `acquire`), deterministic cascading disposal, async resolution deduplication, reverse-topological graph-wide shutdown, and read-only diagnostics.
- **Scope:** `lib/core/di/di.dart`, `test/core/di/dependency_graph_test.dart`, `docs/`, `README.md`.
- **Choices:**
  - **Self-Contained Single File (`lib/core/di/di.dart`):** Encapsulates the entire dependency management system (tokens, registry, compiler, compiled graph, runtime state manager, handles, and diagnostics) into a single cohesive, portable file with zero external dependencies beyond canonical Dart SDK libraries (`dart:async`, `dart:collection`).
  - **Typed Dependency Tokens (`Dependency<T extends Object>`):** Identifies registrations by token identity rather than raw Dart type `T`. Supports const canonicalization and multiple registrations sharing the same Dart type without collisions.
  - **Strict Compilation & Topology Immutability:** Separation of mutable `DependencyRegistry` from immutable `DependencyGraph`. Validates missing dependencies, duplicate registrations, dependency cycles (DFS cycle detection with cycle paths), and sync/async boundary rules (synchronous providers cannot depend on asynchronous providers directly or transitively). Provider factories never execute during compilation.
  - **Restricted Factory Boundary (`Dependencies`):** Factory functions receive a restricted `Dependencies` resolver that strictly enforces access to tokens declared in `requires`. Undeclared lookups throw `UndeclaredDependencyException`.
  - **Lifetime Semantics of Direct Resolution vs. Handles:**
    - `graph.resolve(token)` and `graph.resolveAsync(token)` establish graph-held permanent ownership (`isGraphRetained = true`). Repeated calls return the existing graph-owned instance directly without allocating cumulative ownership claims or inflating reference counts (external ref count remains 0, graph retention contributes a constant 1 to total ref count).
    - `graph.retain(token)` / `graph.retainAsync(token)` allocates a distinct, explicit permanent `DependencyHandle<T>` per call, incrementing `externalRefCount`. Each handle must be released individually.
    - `graph.acquire(token)` / `graph.acquireAsync(token)` allocates a distinct, explicit ephemeral `DependencyHandle<T>` per call, incrementing `externalRefCount`. When all handles and retentions are released, the instance deterministically disposes.
  - **Cascading Reference Counting & Reinitialization:** Ref count combines external handle claims and internal dependency retentions. Releasing the final handle triggers deterministic disposal: running the disposal callback, releasing internal dependency claims, recursively disposing child dependencies whose ref counts reach zero, and resetting runtime state to uninitialized. Disposed nodes can be safely recreated on subsequent acquisitions.
  - **Async Race Handling & Rollback:** Concurrent async resolutions for the same token share a single in-flight Future. If all handles are released while an async factory is in flight, the completed instance is immediately disposed to prevent orphaned alive instances. If factory execution throws, all partially retained dependencies are released and the node resets to uninitialized.
  - **Authoritative Reverse Topological Shutdown & Error Aggregation:** `graph.dispose()` is idempotent and authoritative: invalidates all outstanding handles, rejects new resolutions (`DisposedGraphException`), and disposes all initialized instances in reverse dependency order (consumers before dependencies). Disposal callback exceptions are collected and thrown as `DisposalAggregateException` without blocking cleanup of remaining instances.


## 2026-11-11: Extract `ArcaContainer`, Enum Lifecycle State, and Colocated Onboarding Persistence

- **Status:** agreed
- **Request:** Split the dependency container out of `lib/app/app.dart` into `lib/app/app_container.dart`, replace the sealed `ArcaAppContainerState` hierarchy with a flat `ArcaContainerState` enum, and colocate `SharedPrefsOnboardingRepository` with its `OnboardingRepository` contract behind an `onboarding.dart` barrel.
- **Scope:** `lib/app/`, `lib/core/onboarding/`, `test/core/onboarding/`, `docs/`, `README.md`.
- **Choices:**
  - **Single-Responsibility Files:** `app.dart` now holds only `ArcaApp` (widget/DI edge), while `app_container.dart` owns dependency provisioning and the `init()`/`dispose()` lifecycle.
  - **Enum Lifecycle (`ArcaContainerState { idle, preparing, ready, failure }`):** Replaced the four sealed subclasses with an enum, since no state carries a payload and every consumer only pattern-matches on the discriminant. Enables dot-shorthand matching (`.preparing`, `.ready`). `.preparing` (not `.init`) avoids colliding with the `init()` method name.
  - **Read-Only Lifecycle Observation:** `state` exposes `ValueListenable<ArcaContainerState>`; the `ValueNotifier` stays private so consumers can observe but not drive the lifecycle.
  - **Failure Containment:** Bootstrap is wrapped in `try`/`catch`, transitioning to `.failure` instead of leaving the app wedged in `.preparing`. No payload yet — rendering/retry is deferred until the UI needs it.
  - **Interface/Implementation Colocation:** `SharedPrefsOnboardingRepository` lives beside `OnboardingRepository` in `onboarding_repository.dart` and is exported through `lib/core/onboarding/onboarding.dart`, removing the separate `shared_prefs_onboarding_repository.dart` file.
  - **Rejected — Payload-Carrying Failure State:** A `failure(String message)` variant was dropped for now; error reporting is deferred until the UI needs to render it.

## 2026-11-10: Migrate Onboarding Repository to `SharedPreferencesAsync`

- **Status:** agreed
- **Request:** Migrate `SharedPrefsOnboardingRepository` from legacy synchronous `SharedPreferences` to `SharedPreferencesAsync`, decommission redundant `InMemoryOnboardingRepository`, and introduce test mocking via `MockSharedPreferencesAsync`.
- **Scope:** `lib/core/onboarding/`, `test/core/onboarding/`, `test/test_utils/`, `test/app/router_orchestration_test.dart`, `pubspec.yaml`, `docs/`.
- **Choices:**
  - **Adopt `SharedPreferencesAsync`:** Replaced the legacy `SharedPreferences.getInstance()` pattern with `SharedPreferencesAsync`, removing asynchronous instance caching in `SharedPrefsOnboardingRepository`.
  - **Decommission `InMemoryOnboardingRepository`:** Eliminated the standalone in-memory fake in production code in favor of configuring `SharedPreferencesAsyncPlatform.instance` with `MockSharedPreferencesAsync` in tests.
  - **`MockSharedPreferencesAsync` Test Double:** Created `MockSharedPreferencesAsync` backed by `InMemorySharedPreferencesAsync.empty()` with method call logging, verifying invocations with Flutter's `isMethodCall` matcher.

---

## 2026-11-10: Cleanup of Prototype Feature Modules, Repositories, and Routes

- **Status:** agreed
- **Request:** Remove `journalRoute`, `setupwizard`, `modelDownload`, `vaultSelection`, `recordDetailsRoute`, and associated feature modules and repositories to prepare for clean reimplementation.
- **Scope:** `lib/features/`, `lib/core/`, `lib/app/`, `test/`, `docs/`.
- **Choices:**
  - **Module Removal:** Removed `journal`, `setup_wizard`, `model_downloader`, and `vaults` feature directories and their unit/widget test suites.
  - **Repository & Domain Cleanup:** Removed `lib/core/vault/`, `lib/core/downloader/`, and `lib/core/ai/`.
  - **Router & Route Pruning:** Pruned sealed `AppRoute` down to `WelcomeRoute`, updated `AppStackCodec` and `createAppRouter()`.
  - **Lean Composition Root:** Updated `ArcaAppContainer` and `ArcaApp` to manage only the active infrastructure (`OnboardingRepository`, `DatabaseService`, and `routerConfig`).
  - **Preserved Accessibility Baseline:** Relocated `ArcaButton` touch target and semantics test to `test/core/design_system/accessibility_test.dart`.

---

## 2026-11-10: `ArcaAppContainer` Dependency Container and Asynchronous Bootstrap

- **Status:** agreed
- **Request:**
  - Encapsulate application dependencies and asynchronous setup into a dedicated `ArcaAppContainer`.
  - Simplify `lib/main.dart` entrypoint to `runApp(const ArcaApp())` without imperative bootstrap ceremony.
  - Track lifecycle via sealed `ArcaAppContainerState` (`idle`, `init`, `ready`, `failure`) using `ValueNotifier<ArcaAppContainerState>`.
  - Update test harnesses across widget and router orchestration tests to inject and await `ArcaAppContainer`.
- **Scope:** `lib/app/`, `lib/main.dart`, `test/`, `docs/`.
- **Choices:**
  - **Encapsulated Dependency Container (`ArcaAppContainer`):** Groups `OnboardingRepository`, `VaultRepository`, `JournalRepository`, `DatabaseService`, `DownloadService`, and `routerConfig` into a single container managing asynchronous initialization and lazy default provision.
  - **Stateful Composition Root (`ArcaApp`):** Replaced static parameters in `ArcaApp` with an optional `appContainer` parameter. Uses `ValueListenableBuilder` to render `WidgetsApp.router` when ready and an accessible splash `ArcaScaffold` during initialization.
  - **Test Harness Alignment:** Tests assemble `ArcaAppContainer` with test doubles and in-memory fakes, call `await container.init()`, and pass `ArcaApp(appContainer: container)`.

---

## 2026-11-08: Align Downloader Contract to `DownloadService<K, T>` and Lifecycle Methods

- **Status:** agreed
- **Request:**
  - Align root noun across interface and implementation: rename `DownloaderService` to `DownloadService<K, T>` in `lib/core/downloader/services/download_service.dart`, matching `DownloadManager` and Arca's established `DatabaseService` / `DatabaseManager` pattern.
  - Simplify lifecycle method names to concise primitives: `queue()`, `pause()`, and `resume()`.
  - Fix default key mapper in `DownloadManager` to safely cast argument value `target as R`.
- **Scope:** `lib/core/downloader/`, `lib/app/`, `lib/features/`, `test/`, `docs/`.
- **Choices:**
  - **Symmetric Architecture:** Both interface (`DownloadService`) and implementation (`DownloadManager`) share the `Download*` root stem.
  - **Lean API Surface:** Replaced verbose domain-qualified method names (`queueDownloads`, `pauseDownload`, `resumeDownload`) with clean, generic verbs (`queue`, `pause`, `resume`).
  - **Primary Initializer Cleanliness:** Cleaned up `DownloadManager` declaring parameters and scope in Dart 3.13.

---

## 2026-11-08: Generic Downloader Service Architecture (`DownloadService<K, T>`)

- **Status:** agreed
- **Request:** Refactor the model-specific downloader module (`lib/core/model_downloader/`) into a generic, multi-purpose `downloader` module (`lib/core/downloader/`) featuring `DownloadService<K extends Object, T extends Object>` and `DownloadManager<K extends Object, T extends Object>`, where `K` is the tracking map key and `T` is the payload encapsulated in `DownloadProgress<T>`.
- **Scope:** `lib/core/downloader/`, `lib/app/`, `lib/features/model_downloader/`, `lib/features/setup_wizard/`, `test/`, `docs/`.
- **Choices:**
  - **Type-Safe Generic Contract (`DownloadService<K extends Object, T extends Object>`):** Constrained both key `K` and payload `T` to non-nullable `Object`. Exposes reactive state via `downloads` (`Map<K, DownloadProgress<T>>`) and `downloadsStream`.
  - **Reusable `DownloadManager<K, T>`:** Provides a general-purpose download orchestrator with configurable `keyOf: K Function(T)` (defaulting to identity cast when `K == T`), handling enqueueing, pausing, resuming, and progress tracking across diverse targets (models, images, assets).
  - **Complete Decoupling of Core Domain:** Moved domain definitions (`AIKind`, `AIModel`) to `lib/core/ai/`, leaving `lib/core/downloader/` fully independent of AI concepts.
  - **Composition & Injection:** `ArcaApp`, `SetupWizardBloc`, and `ModelDownloaderBloc` inject and consume `DownloadService<AIKind, AIKind>`.

---

## 2026-11-08: Extract Core AI Domain Models to `lib/core/ai/`

- **Status:** agreed
- **Request:** Relocate `AIKind` and `AIModel` out of `lib/core/model_downloader` into `lib/core/ai/models/ai_model.dart`, as on-device AI models are core domain concepts rather than downloader-specific concerns.
- **Scope:** `lib/core/ai/`, `lib/core/model_downloader/`, `lib/features/`, `test/`, `docs/`.
- **Choices:**
  - **Decoupled Core AI Domain:** Established `lib/core/ai/models/ai_model.dart` for domain entities (`AIKind`, `AIModel`, `defaultAIModels`).
  - **Downloader Primitive Scoping:** Retained generic `DownloadStatus` and `DownloadProgress<T extends Object>` in `lib/core/model_downloader/models/download_progress.dart`.

---

## 2026-11-08: Rename to `ModelKind` and Adopt `ModelDownloadManager`

- **Status:** agreed
- **Request:**
  - Rename `AIKind` to `ModelKind` for consistency across domain models and download manager.
  - Rename `InMemoryModelDownloaderService` to `ModelDownloadManager` (implementing `ModelDownloadService`), mirroring the `DatabaseService` / `DatabaseManager` architectural pattern.
- **Scope:** `lib/core/model_downloader/`, `lib/app/`, `lib/features/`, `test/`, `docs/`.
- **Choices:**
  - **`ModelKind` Identity:** Aligns with `ModelDownloadService` and `AIModel.kind`.
  - **`ModelDownloadManager` Implementation:** Replaces misnomered `InMemory*` label with a concrete manager class, establishing clear separation between the download orchestration lifecycle and the internal transfer implementation.

---

## 2026-11-08: AI Model Domain Simplification & Generic DownloadProgress

- **Status:** agreed
- **Request:** Modernize the model downloader domain models:
  - Rename capability enum to `AIKind` and remove `ner` (leaving `ocr` and `asr`).
  - Make `DownloadStatus` generic (`queued`, `downloading`, `paused`, `ready`, `failed`) and drop non-generic states like `notInstalled`.
  - Make `DownloadProgress<T extends Object>` generic with a non-nullable target.
  - Decouple `AIModel` metadata from hardcoded static catalog definitions.
  - Collapse artificial `ModelDownloadTask` / `ModelDownloadState` separation into `ModelDownloaderService` which directly owns and exposes the download state.
- **Scope:** `lib/core/model_downloader/`, `lib/features/model_downloader/`, `lib/features/setup_wizard/`, `test/`, `docs/`.
- **Choices:**
  - **Lean Discriminant (`AIKind`):** Replaced bloated enum with lean `AIKind { ocr, asr }` carrying no metadata strings.
  - **Generic `DownloadProgress<T extends Object>`:** Unbound from specific AI model types, generic over any non-nullable download target (`target: T`), tracking `status` and `progress`.
  - **Decoupled `AIModel` Data Class:** Representing model metadata (`id`, `kind`, `name`, `description`, `estimatedSize`) independently of static catalogs, allowing mock or upstream sourcing.
  - **Service-Owned Download State:** Eliminated redundant `ModelDownloadTask` and `ModelDownloadState` classes; `ModelDownloaderService` directly exposes `downloads` (`Map<AIKind, DownloadProgress<AIKind>>`) and streams updates via `downloadsStream`.

---

## 2026-11-08: Refactor `ModelDownloaderRepository` to `ModelDownloaderService`

- **Status:** agreed
- **Request:** Transition `ModelDownloaderRepository` to `ModelDownloaderService` to accurately reflect its role as an operational background process and transient event streamer rather than an entity data store.
- **Scope:** `lib/core/model_downloader/`, `lib/features/model_downloader/`, `lib/features/setup_wizard/`, `lib/app/`, `test/`, `docs/`.
- **Choices:**
  - **Service over Repository (Rule 19):** Aligned with the architectural guideline "a repository when it is data, a service when it is behavior." Model download progress, task scheduling, pausing, and resuming represent execution behavior rather than entity CRUD persistence.
  - **Directory & Interface Restructuring:**
    - Moved contracts and implementations from `lib/core/model_downloader/repositories/` to `lib/core/model_downloader/services/`.
    - Renamed `ModelDownloaderRepository` -> `ModelDownloaderService`.
    - Renamed `InMemoryModelDownloaderRepository` -> `InMemoryModelDownloaderService`.
  - **Consumer Alignment:**
    - Updated `ArcaApp`, `SetupWizardBloc`, and `ModelDownloaderBloc` to inject and consume `ModelDownloaderService`.
    - Renamed and modernized corresponding test suites.

---

## 2026-11-08: Migration to `path_manager` and Encapsulated Database Migrations

- **Status:** agreed
- **Request:** Replace `path_provider` with `path_manager` and encapsulate database migration execution.
- **Scope:** `pubspec.yaml`, `lib/core/database/`, `test/`.
- **Choices:**
  - **Adopt `path_manager`:** Replaced `path_provider` with `path_manager: ^0.7.1+1` for locating the application support directory across platforms.
  - **Encapsulate Database Migrations:** Made `ArcaDatabaseMigrations` a `final class` and encapsulated migration execution behind a static `migrate(SqliteConnection db)` method, making `_migrations` private.

---

## 2026-11-08: Complete Removal of Legacy Profile Aliases and Redirections

- **Status:** agreed
- **Request:** Remove all backwards-compatibility aliases, getters, constructor parameters, and function redirections relating to `profile`/`profiles`.
- **Scope:** `lib/core/vault/`, `lib/features/vaults/`, `lib/app/`, `docs/`.
- **Choices:**
  - **Eliminate Model & Type Aliases:**
    - Removed `typedef Profile = Vault;` and `typedef ProfileRelationship = VaultRelationship;` from `lib/core/vault/models/vault.dart`.
    - Removed `typedef ProfileRepository = VaultRepository;`, `typedef InMemoryProfileRepository`, and `typedef SqliteProfileRepository`.
    - Removed `typedef ProfileBloc`, `typedef ProfileEvent` (and event subclasses), and `typedef ProfileState` (and state subclasses).
    - Removed `class MemberSwitcherBar` compatibility wrapper.
  - **Eliminate Method & Getter Redirections:**
    - Removed `getProfiles()`, `getProfileById()`, `addProfile()`, `getActiveProfileId()`, and `setActiveProfileId()` from `VaultRepository`, `InMemoryVaultRepository`, and `SqliteVaultRepository`.
    - Removed `profiles` and `activeProfile` compatibility getters from `VaultLoaded`.
    - Removed `profileRepository` constructor parameter and fallback from `ArcaApp`.
    - Simplified UI labels in `VaultSelectionScreen` (`'Vault Name *'`).

---

## 2026-11-08: Direct Dependency Simplification: Rely Solely on `sqlite_async`

- **Status:** agreed
- **Request:** Clarify why both `sqlite3` and `sqlite_async` were specified in `pubspec.yaml`, remove redundant direct dependencies, and clean up test suite references in documentation.
- **Scope:** `pubspec.yaml`, `README.md`, `docs/architecture.md`, repository implementations in `lib/core/vault/` and `lib/features/journal/`.
- **Choices:**
  - **Eliminate Redundant Direct `sqlite3` Dependency:**
    - `sqlite_async` already brings in `sqlite3` transitively as its underlying engine and provides connection pooling, migrations, and isolate-backed async transaction semantics.
    - Repositories (`SqliteVaultRepository`, `SqliteJournalRepository`) parse rows using `Map<String, dynamic>` semantics (which `Row` natively implements) and type inference, eliminating the need for `import 'package:sqlite3/common.dart'` or declaring `sqlite3` in `dependencies:`.
    - Removed `sqlite3: ^3.9.0` from `pubspec.yaml`.
  - **Documentation Alignment:**
    - Corrected test suite description and count in `README.md` to reflect the 46 genuine application tests (removing outdated DS&A test suite references).

---

## 2026-11-08: Dart 3.13 Primary Constructors, Dot-Shorthands, and Canonical `collection` & `async` Packages

- **Status:** agreed
- **Request:** Modernize the codebase with Dart 3.13 primary constructor syntax and Dart 3.10+ dot-shorthands across domain entities, routes, BLoCs, and UI widgets per Rule 12 of `mobile-conventions`. Add official packages for collections (`collection`) and async/stream primitives (`async`). Avoid unnecessary third-party utility packages.
- **Scope:** Repository-wide modernization across `lib/`, `pubspec.yaml`, `test/`.
- **Choices:**
  - **Syntax Modernization:**
    - Domain models (`Vault`, `JournalEntry`, `AiModelCapability`), BLoC states/events, sealed routes (`AppRoute`), and widgets (`ArcaScaffold`, `ArcaHeader`, `ArcaButton`, `ArcaCard`, `ArcaBadge`, `ArcaTextField`, `ArcaProgressBar`, screens) migrated to Dart 3.13 primary constructor syntax (`class const Foo(...)`, `class Bar(...)`) and semicolon bodies.
    - Adopted leading dot-shorthands (`.primary`, `.ghost`, `.vital`, `.self`, `.stretch`, `.opaque`, `.center`, `.w600`, etc.) eliminating redundant type and enum prefixes.
  - **Canonical Collection & Async Packages:**
    - Added `collection: ^1.19.1` (Canonical Dart collection utilities, priority queues: `PriorityQueue`, `HeapPriorityQueue`, `QueueList`, deep equality: `ListEquality`, `SetEquality`, binary search: `binarySearch`).
    - Added `async: ^2.13.0` (`StreamGroup`, `StreamSplitter`, `CancelableOperation`, `AsyncCache`, `RestartableTimer`).
    - Excluded external third-party collections/DS&A packages (`more`, `data_structures`) to adhere to minimal external dependency footprint while relying strictly on official Dart SDK-supported packages.

---

## 2026-11-08: Interface-Driven Dependency Injection across Repositories, Services, Constructors, and BLoCs

- **Status:** agreed
- **Request:** Ensure dependencies (repositories and services) are provided, injected, and consumed as abstract interfaces rather than concrete implementations across screens, constructors, BLoCs, and service boundaries to guarantee testability and mockability.
- **Scope:** Architecture, DI, composition root (`lib/app/`), core domain interfaces (`lib/core/`), and test harnesses.
- **Choices:**
  - **Interface-First Injection:**
    - All constructors (screens, BLoCs, router config, composition root) accept abstract interfaces (`abstract interface class`), never concrete classes (`Sqlite*`, `InMemory*`, `SharedPrefs*`, or `DatabaseManager`).
    - Interfaces utilized: `JournalRepository`, `VaultRepository`, `OnboardingRepository`, `ModelDownloaderRepository`, and `DatabaseService`.
  - **Provider Typing:**
    - `MultiRepositoryProvider` explicitly registers dependencies under their interface types:
      - `RepositoryProvider<JournalRepository>.value`
      - `RepositoryProvider<VaultRepository>.value`
      - `RepositoryProvider<OnboardingRepository>.value`
      - `RepositoryProvider<ModelDownloaderRepository>.value`
      - `RepositoryProvider<DatabaseService>.value`
    - Resolving dependencies via `context.read<T>()` retrieves the interface contract.
  - **Service Abstractions:**
    - Extracted `DatabaseService` interface for SQLite database lifecycle and migrations (`DatabaseManager implements DatabaseService`).
  - **Testability & Mocking:**
    - Tests declare variables as interface contracts (`final VaultRepository`, `final JournalRepository`, `final DatabaseService`), allowing drop-in substitution of test doubles, in-memory fakes, or mocks.

---

## 2026-11-08: Feature Module Isolation, Zero Cross-Feature Imports, Callback-Driven Route Orchestration, and Core Broadcast Streams

- **Status:** agreed
- **Request:** Restructure onboarding, setup wizard, AI downloader, and vault management into strictly isolated, self-contained feature modules. Remove ambiguous catch-all modules. Forbid cross-module feature dependencies and routing side-effects from UI screens.
- **Scope:** Architecture refactoring across `lib/features/`, `lib/core/`, and `lib/app/`.
- **Choices:**
  - **Zero Cross-Feature Imports:**
    - Feature modules (`welcome`, `setup_wizard`, `model_downloader`, `vaults`, `journal`) must never import each other (`import '../../features/B'` is strictly disallowed).
    - Shared domain contracts, repositories, and models are colocated in `lib/core/` (`lib/core/vault/`, `lib/core/onboarding/`, `lib/core/model_downloader/`).
  - **Callback-Driven Route Orchestration:**
    - Presentation screens must never import `AppRoute`, `routes.dart`, or `package:kaisel/kaisel.dart`.
    - Screens express user navigation intent exclusively via constructor callbacks (`onStartSetup`, `onSkip`, `onBack`, `onComplete`, `onVaultSelected`, `onRecordSelected`).
    - The router (`lib/app/router.dart`) is the single orchestration layer that wires callbacks to route pushes, pops, and route-guard redirections.
    - *Benefits:* Eliminates module leakage, decouples UI from navigation framework, and enables completely isolated widget and accessibility testing without router mocking.
  - **Reactive Data Sharing via Broadcast Streams:**
    - Shared domain state (e.g. active vault switching, dynamic vault list changes, and background AI model download progress) is exposed by core repositories using broadcast streams (`StreamController.broadcast()`).
    - Feature BLoCs subscribe to these streams on initialization, reacting immediately to background updates across the application without tight coupling or peer BLoC communication.

---

## 2026-11-08: Onboarding & Setup Wizard Flow, Terminology ("Vault" vs "Journal"), and AI Capability Downloader

- **Status:** agreed
- **Request:** Introduce first-launch onboarding, setup wizard for multi-member vaults and on-device AI capabilities, post-setup AI model download flow with background resumption, and a route guard redirecting empty or multi-vault states. Address naming clarification between "Journal" and "Vault".
- **Scope:** Feature implementation (Onboarding, Setup Wizard, AI Capabilities Downloader, Vault Selection, and Route Guards).
- **Choices:**
  - **Terminology Shift ("Vault" & "Clinical Records" over "Journal"):**
    - "Journal" connotes personal lifestyle diaries, travel notes, or casual logs, failing to communicate medical rigor, clinical confidentiality, and sovereign custody.
    - We adopt **"Health Vault"** (or simply **"Vault"**) as the primary container for a profile's encrypted medical records. Vault strongly communicates data security, encryption, and portable export/import boundaries.
    - Chronological data inside a Vault is designated as **"Clinical Records"** or **"Health Timeline"**.
  - **Onboarding UX & Setup Wizard Architecture:**
    - First Launch: Routes to `WelcomeRoute`. Users can start guided setup or quick skip.
    - Wizard Step 1 (Vault Setup): Allows creating 0, 1, or multiple vaults with name, relationship, and optional medical details (blood type, allergies, DOB).
    - Wizard Step 2 (On-Device AI Capabilities): Selectable list of edge AI models (Lab OCR, Whisper Dictation ASR, Clinical NER) with download size estimates. Skipping or selecting none bypasses download.
    - Onboarding Completion: Sets persistent flag `has_completed_onboarding` in `SharedPreferences`.
  - **AI Capabilities Download Lifecycle:**
    - Shown in the same first-launch session only if $\ge 1$ capabilities are selected.
    - Users can monitor downloads or tap "Continue to Dashboard" immediately to run downloads in the background.
    - A non-intrusive status indicator bar is placed at the top of the dashboard when background downloads are active, with state persisted so terminated downloads resume on next session.
  - **Route Guard & Initial Route Decision Matrix:**
    - `!hasCompletedOnboarding` $\rightarrow$ `WelcomeRoute`
    - `hasCompletedOnboarding` with:
      - 0 Vaults available $\rightarrow$ `VaultSelectionRoute` in Empty State mode (prompts vault creation before accessing dashboard).
      - 1 Vault available $\rightarrow$ `JournalRoute` (Dashboard) with that vault automatically active.
      - $>1$ Vaults available $\rightarrow$ `VaultSelectionRoute` (in selection mode, allowing the user to select their active vault or switch anytime).

---

## 2026-11-07: Project Foundation and Architectural Choices

- **Status:** agreed
- **Request:** Create a Flutter mobile application for "Arca" (Automated Records & Clinical Archive) — an offline-first, privacy-focused health tracking companion and longitudinal medical journal designed for automated biometric sync and private family medical records processed entirely on-device.
- **Scope:** Scaffold (complete mobile application foundation with core folder structure, BLoC state management, custom foundation design system, kaisel typed navigation, test harness, accessibility baseline, CI workflow, and project documentation).
- **Choices:**
  - **Stack & UI Strategy:** Flutter 3.47.x / Dart 3.13.x. In light of Flutter 3.47+ decoupling of Material and Cupertino from the core framework, Arca avoids monolithic Material/Cupertino framework APIs. Instead, it uses core Flutter primitives (`WidgetsApp`, basic widgets, custom layout, and bespoke design tokens for typography, spacing, and colors) to establish robust functionality first without incurring future framework-decoupling migration debt.
  - **Identity:**
    - App Name: Arca
    - Application / Bundle ID: `health.arca.app`
    - Organization: `health.arca`
  - **Platforms & Minimum OS:** Android (minSdk 26 / Android 8.0, targetSdk 34+ for Google Health Connect) and iOS (iOS 16.0+ for Apple HealthKit).
  - **State Management:** `flutter_bloc` (Bloc / Cubit) for explicit event-driven state transitions, predictable state streams, and deterministic audit trails for clinical calculations and workflows.
    - *Alternatives considered:* Riverpod, Provider (rejected in favor of Bloc's explicit event-driven pipeline and auditability).
  - **Navigation:** `kaisel` for Dart 3-native navigation using sealed classes, exhaustive pattern matching, and a stack-as-state model rather than URL/string-based navigation or code generation.
    - *Alternatives rejected:* `go_router` (URL/string-centric, less idiomatic Dart 3 pattern matching).
  - **Dependency Injection:** Constructor injection with `RepositoryProvider` at the composition root (`lib/app/`).
    - *Alternatives rejected:* Global service locator (`get_it`) pattern (obscures explicit dependency graph and complicates test faking).
  - **Persistence:** `sqlite_async` with `drift` (or modern `sqlite3` without deprecated `sqlite3_flutter_libs`) + `shared_preferences` for key-value preferences. Native background isolates ensure UI thread stays responsive during heavy lab metric queries.
    - *Deprecated packages avoided:* `sqlite3_flutter_libs` is intentionally omitted.
  - **Networking:** None required initially; Arca is strictly offline-first with zero external cloud telemetry or accounts.
  - **Lint & Code Quality:** Standard (`flutter_lints` conforming to canonical Flutter style, `--fatal-infos --fatal-warnings` in CI).
  - **License:** Proprietary (All rights reserved).
  - **Agent Instructions:** Included (`AGENTS.md` at repository root).
  - **README Outline (for Step 9):**
    - Project Overview & Clinical Vision
    - Core Capabilities (Biometrics ingestion, local document intelligence, multi-member vault)
    - Prerequisites & Toolchain setup
    - Build, Run, Test, and Lint commands
    - Directory & Feature architecture
    - Privacy & Security guarantees
    - License notice

### Architecture Sketch

Arca follows a feature-first layered architecture (`lib/features/<name>/{presentation,domain,data}`) alongside shared infrastructure in `lib/core` (design system tokens, basic widgets, database, utilities) and `lib/app` (composition root with `WidgetsApp`, router with `kaisel`, theme). Domain layers contain pure Dart models, use cases, and repository interfaces with no UI or platform imports. Data layers implement these interfaces using local `sqlite_async` / `drift` tables and hardware sensors/platform channels. Presentation layers use immutable view states rendered by const widgets and driven by BLoCs/Cubits. All user data, scans, and clinical metrics remain strictly on-device. For full details, module trees, and dependency directions, see [architecture.md](architecture.md).
