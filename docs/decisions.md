# Decisions

## 2026-11-07: Project Foundation and Architectural Choices
- **Status:** agreed
- **Choice:** Build offline-first Flutter app with `WidgetsApp` and custom foundation design system (no Material/Cupertino APIs), BLoC state management, `kaisel` navigation, and `sqlite_async` encrypted storage.
- **Reason:** Guarantees absolute on-device data sovereignty and shields the app from future framework decoupling migration debt.
- **Alternative rejected:** Monolithic Material/Cupertino widgets, Riverpod, `go_router`, global `get_it`, and cloud backend.

## 2026-11-08: Onboarding Flow and Terminology ("Vault" and "Clinical Records" over "Journal")
- **Status:** agreed
- **Choice:** Adopt "Health Vault" (or "Vault") as the primary container for personal/family encrypted records and "Clinical Records" for chronological health events, retiring "Journal".
- **Reason:** "Journal" connotes casual diaries, failing to communicate medical rigor, clinical confidentiality, and sovereign custody.
- **Alternative rejected:** Retaining "Journal" / "Diary" terminology.

## 2026-11-08: Feature Module Isolation, Zero Cross-Feature Imports, and Presentation Callback Navigation
- **Status:** agreed
- **Choice:** Enforce strict feature module isolation (`lib/features/A` never imports `lib/features/B`), presentation screens express navigation solely via constructor callbacks, and core repositories expose broadcast streams.
- **Reason:** Eliminates feature coupling, enables isolated widget/accessibility testing without router mocking, and centralizes routing at `lib/app/router/`.
- **Alternative rejected:** Cross-feature imports and screens directly importing navigation routes.

## 2026-11-08: Interface-Driven Dependency Injection across Repositories and Services
- **Status:** agreed
- **Choice:** All constructors, screens, BLoCs, and service consumers accept abstract interfaces (`abstract interface class`), never concrete implementations.
- **Reason:** Decouples high-level policy from low-level storage details, enabling test isolation with mocks and fakes.
- **Alternative rejected:** Direct concrete class coupling and implementation injection.

## 2026-11-08: Dart 3.14 Primary Constructors, Dot-Shorthands, and Canonical Collection & Async Packages
- **Status:** agreed
- **Choice:** Adopt Dart primary constructors and dot-shorthands across domain entities, routes, and widgets; rely exclusively on canonical `collection` and `async` packages.
- **Reason:** Maximizes modern language idioms and avoids unnecessary third-party utility packages.
- **Alternative rejected:** Legacy verbose constructors and third-party utility dependencies (`more`, `data_structures`).

## 2026-11-08: Direct Dependency Simplification: Rely Solely on `sqlite_async`
- **Status:** agreed
- **Choice:** Remove direct `sqlite3` dependency from `pubspec.yaml`, relying entirely on `sqlite_async` which transitively manages SQLite native bindings.
- **Reason:** Eliminates redundant direct dependencies and avoids version skew between low-level bindings and connection pools.
- **Alternative rejected:** Declaring both `sqlite3` and `sqlite_async`.

## 2026-11-08: Adopt `path_manager` and Encapsulated Database Migrations
- **Status:** agreed
- **Choice:** Adopt `path_manager` for resolving local application support directory and encapsulate migration execution in `ArcaDatabaseMigrations.migrate(SqliteConnection db)`.
- **Reason:** Decouples platform directory lookups and guarantees migrations run deterministically inside database initialization.
- **Alternative rejected:** `path_provider`, exposing mutable migration lists.

## 2026-11-10: ArcaAppContainer Dependency Container and Asynchronous Bootstrap
Superseded by 2026-11-11: Extract ArcaContainer, Enum Lifecycle State, and Colocated Onboarding Persistence.

## 2026-11-10: Cleanup of Prototype Feature Modules, Repositories, and Routes
- **Status:** agreed
- **Choice:** Remove prototype feature modules (`journal`, `setup_wizard`, `model_downloader`, `vaults`), domain repositories, and routes to isolate `WelcomeScreen` and onboarding router.
- **Reason:** Eliminates unverified prototype code and establishes a clean baseline for incremental feature delivery.
- **Alternative rejected:** Carrying unverified prototype code forward.

## 2026-11-10: Migrate Onboarding Repository to `SharedPreferencesAsync`
- **Status:** agreed
- **Choice:** Migrate `SharedPrefsOnboardingRepository` to `SharedPreferencesAsync`, colocate implementation with contract, and mock in tests with `MockSharedPreferencesAsync`.
- **Reason:** Replaces legacy synchronous `SharedPreferences.getInstance()` with modern asynchronous platform API.
- **Alternative rejected:** Synchronous `SharedPreferences`, in-memory fake in production code.

## 2026-11-11: Extract ArcaContainer, Enum Lifecycle State, and Colocated Onboarding Persistence
Superseded by 2026-11-14: Migrate Composition Root to Wire & Circuit Dependency Injection.

## 2026-11-13: Compiled Dependency Graph System Architecture & Lifecycles
Superseded by 2026-11-14: Wire & Circuit Minimal v1 Dependency Injection Engine.

## 2026-11-14: Wire & Circuit Minimal v1 Dependency Injection Engine
Superseded by 2026-11-15: Extract DAG-Based Dependency Engine into circuitry Monorepo.

## 2026-11-14: Migrate Composition Root to Wire & Circuit Dependency Injection
Superseded by 2026-11-15: Flutter Bridge (CircuitProvider and CircuitState) for Wire & Circuit Dependency Injection.

## 2026-11-15: Combine Static Async Factory and DAG Wire for Database Initialization
- **Status:** agreed
- **Choice:** Decouple filesystem path resolution into `DatabaseConfig.wire`, and open database via immutable static async factory `DatabaseManager.open(config)` chained via `DatabaseService.wire`.
- **Reason:** Eliminates two-phase initialization and mutable database handles, enabling deterministic DAG-based connection pooling.
- **Alternative rejected:** Two-phase `initialize()` method, mutable `SqliteDatabase? _db`.

## 2026-11-15: Flutter Bridge (`CircuitProvider` and `CircuitState`) for Wire & Circuit Dependency Injection
- **Status:** agreed
- **Choice:** Connect Circuitry DAG engine to Flutter via sealed `CircuitState` hierarchy and `CircuitProvider` widget with unmount disposal and in-flight cancellation.
- **Reason:** Replaces `FutureBuilder` and `MultiRepositoryProvider` with idiomatic Dart 3 pattern matching and lifecycle-safe dependency provision.
- **Alternative rejected:** `FutureBuilder<Circuit>`, service locators, BuildContext extensions.

## 2026-11-15: Extract DAG-Based Dependency Engine into `circuitry` Monorepo
- **Status:** agreed
- **Choice:** Extract DAG dependency injection engine into dedicated standalone package `circuitry_flutter` and decommission in-tree `lib/core/di/`.
- **Reason:** Isolates dependency injection engine into reusable, independently tested packages and keeps Arca focused on clinical domain logic.
- **Alternative rejected:** Maintaining in-tree dependency injection engine inside `lib/core/di/`.

## 2026-11-19: Streamline Onboarding by Bundling onnxruntime & RapidOCR
- **Status:** agreed
- **Choice:** Bundle onnxruntime and RapidOCR directly inside the iOS app bundle and Android APK, eliminating intermediary model download/preparation (`AiPrepScreen`) and setup choice (`SetupChoiceScreen`) steps. The onboarding flow condenses into two symmetric 3-step paths converging at `ExtractedReviewScreen` with edit functionality:
  1. `Welcome` -> `Scan` (bundled OCR) -> `Overview` (with edit) -> `Vault Created`
  2. `Welcome` -> `Manual Entry` (information gathering) -> `Overview` (with edit) -> `Vault Created`
- **Reason:** On-device bundling eliminates network dependency and initialization latency during first launch, reducing user onboarding friction by 40% and unifying review/edit state at a single overview screen.
- **Alternative rejected:** Post-install model downloading, multi-step preparation screens, and separate confirmation screens without edit back-routing.

## 2026-11-19: On-Device Document Scanning, Camera Capture, Photo and File Picker Abstraction
- **Status:** agreed
- **Choice:** Colocate `DocumentCaptureService` interface and `DefaultDocumentCaptureService` implementation within `lib/core/capture/document_capture_service.dart`, integrating `cunning_document_scanner` (VisionKit on iOS, ML Kit on Android) for edge-detected document scanning, `image_picker` for camera snapshots and photo gallery selection, and `file_picker` for PDF/document file import. `DocumentScanScreen` accepts an optional `captureService` parameter defaulting lazily to `DefaultDocumentCaptureService()` on screen mount rather than through Circuitry DI.
- **Reason:** Provides clinical document edge detection, deskewing, camera capture, gallery selection, and PDF file import natively with zero-network, 100% on-device execution. Keeping the interface and default implementation in a single cohesive file simplifies navigation and organization without unnecessary file fragmentation. Lazy screen-level initialization avoids upfront service allocation when users select the manual onboarding flow, while the constructor parameter preserves test isolation via fakes.
- **Alternative rejected:** Building custom CameraX/AVFoundation camera preview widgets; relying exclusively on a single unspecialized photo picker without document border detection; separating interface and single default implementation into separate files; registering capture service eagerly in the global Circuitry DAG.
