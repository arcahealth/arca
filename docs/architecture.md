# Arca Architecture

## Current Shape & Feature Layout

Arca is structured around self-contained, isolated feature modules supported by shared domain infrastructure in `lib/core/` and unified at the composition root in `lib/app/`.

Cross-module imports between features are strictly forbidden (`lib/features/A` must NEVER import `lib/features/B`). Data sharing occurs exclusively via core repositories, and route transitions are completely decoupled from presentation screens using constructor callbacks wired at the router.

```
lib/
├── main.dart                      # Clean application entry point running const ArcaApp()
├── app/                           # Composition root & route orchestrator
│   ├── app.dart                   # ArcaApp (ValueListenableBuilder + MultiRepositoryProvider + WidgetsApp.router)
│   ├── app_container.dart         # ArcaContainer (dependency lifecycle) + ArcaContainerState
│   └── router/                    # Route orchestration
│       ├── router.dart            # createAppRouter: top-level ArcaRoute tree & AppStackCodec
│       └── onboarding_routes.dart # OnboardingRoute, OnboardingModule & OnboardingModuleCodec
├── core/                          # Shared domain entities, repository contracts & infrastructure
│   ├── database/                  # On-device SQLite infrastructure (DatabaseManager, ArcaDatabaseMigrations)
│   ├── design_system/             # Foundation UI (ArcaScaffold, ArcaHeader, ArcaButton, ArcaCard, ArcaBadge, ArcaTextField, ArcaProgressBar)
│   └── onboarding/                # OnboardingRepository + SharedPrefsOnboardingRepository (onboarding.dart barrel)
└── features/                      # Isolated, self-contained feature modules
    └── welcome/                   # First-launch welcome & privacy value pillars (WelcomeScreen)
```

---

## Seams, Layer Boundaries & Decoupling Principles

### 1. Zero Cross-Feature Imports
- Features are completely self-contained. `lib/features/<name>/` can only import `package:flutter/widgets.dart`, third-party packages, and `package:arca/core/...`.
- No feature may import another feature (`import '../../features/other/...'` is strictly forbidden).

### 2. Decoupled Route Orchestration via Constructor Callbacks
- Presentation screens never import `AppRoute`, `routes.dart`, or `package:kaisel/kaisel.dart`.
- Screens express navigation intent exclusively through constructor callbacks (`onStartSetup`, `onSkip`, `onBack`, `onComplete`, `onVaultSelected`, `onRecordSelected`).
- The router in `lib/app/router.dart` is the sole orchestrator wiring these callbacks to `context.push()` / `context.pop()`, preventing navigation leakage and enabling isolated widget testing.

### 3. Reactive Cross-Module Data Sharing via Core Broadcast Streams
- When multiple features need to observe shared domain state (such as active vault changes or model download progress), core repositories expose broadcast streams (`StreamController.broadcast()`).
- Feature BLoCs subscribe to these repository streams, achieving reactive synchronization without inter-BLoC dependencies.

### 4. Interface-Driven Dependency Injection
- Screens, BLoCs, router parameters, and service consumers accept abstract interfaces (`abstract interface class`), never concrete implementations.
- Repositories (`JournalRepository`, `VaultRepository`, `OnboardingRepository`) and services (`DatabaseService`, `DownloadService<AIKind, AIKind>`) are injected through `ArcaContainer` and exposed to the widget tree by the composition root (`RepositoryProvider<ArcaContainer>`), which forwards to interface-typed accessors.
- Test suites interact with interfaces, allowing in-memory fakes or mocks without coupling tests to implementation details.

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
  - `WelcomeRoute()`: First-launch greeting & privacy value pillars
  - `SetupWizardRoute()`: Multi-step vault and edge AI capability setup
  - `AiDownloadRoute(selectedCapabilityIds)`: First-session AI model download progress
  - `VaultSelectionRoute()`: Vault switcher & empty-vault route guard
  - `JournalRoute()`: Primary timeline & health vault dashboard
  - `RecordDetailRoute(recordId)`: Clinical detail view
- **Exhaustive Pattern Matching**: The screen builder in `lib/app/router.dart` uses a Dart 3 `switch` expression over the sealed route hierarchy, guaranteeing at compile-time that every route is handled.
- **Deep Linking**: `AppStackCodec` implements `KaiselStackCodec<AppRoute>`, decoding incoming deep links (`/records/:id`, `/welcome`, `/setup`, `/ai-download`, `/vaults`) into a multi-frame stack (`[JournalRoute(), RecordDetailRoute(id)]`) to preserve natural back navigation.

---

## Libraries and Dependencies

| Dependency | Version | Architectural Purpose |
| --- | --- | --- |
| `flutter_bloc` | `^9.1.1` | Predictable, event-driven unidirectional state management for clinical records. |
| `kaisel` | `^1.1.0` | Dart 3 native navigation using sealed classes and stack-as-state model. |
| `collection` | `^1.19.1` | Official Dart collection utilities: `PriorityQueue`, `HeapPriorityQueue`, `binarySearch`, `ListEquality`, `SetEquality`. |
| `async` | `^2.13.0` | Asynchronous operations, stream groups/splitters, cancelable operations, and async caches. |
| `sqlite_async` | `^0.14.8` | High-performance asynchronous SQLite database engine with background isolate execution (transitively manages native `sqlite3` bindings). |
| `path_manager` | `^0.7.1+1` | Locates local app support directory for the encrypted SQLite database file. |
| `path` | `^1.9.1` | Cross-platform file path manipulation. |
| `shared_preferences` | `^2.5.6` | Lightweight key-value persistence for active vault selection. |
| `flutter_lints` | `^6.0.0` | Standard Dart/Flutter static analysis rule set. |
| `bloc_test` | `^10.0.0` | Streamlined unit testing for BLoC state transitions. |
| `shared_preferences_platform_interface` | `^2.4.2` | Platform interface for mocking asynchronous key-value persistence in test harnesses. |
| `flutter_test` | SDK | Widget and accessibility harness for UI validation. |

---

## Shared vs. Native Platform Responsibilities

- **Shared (Dart / Flutter)**:
  - Clinical domain entities and validation rules
  - Journal & vault state machines and diagnostic event handlers
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
flutter analyze lib/features/vaults
flutter test test/features/vaults/vault_bloc_test.dart

# Outer gate: full check
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```
