# Arca Architecture

## Current Shape & Feature Layout

Arca is structured around a feature-first layered architecture. Code is partitioned by domain capabilities inside `lib/features/<name>/`, supported by shared cross-cutting infrastructure in `lib/core/` and unified at the composition root in `lib/app/`.

```
lib/
├── main.dart                      # Low-level application entry point
├── app/                           # Composition root
│   ├── app.dart                   # ArcaApp: MultiRepositoryProvider + MultiBlocProvider + WidgetsApp.router
│   ├── router.dart                # createAppRouter: KaiselRouterConfig with sealed routes
│   └── routes.dart                # Sealed AppRoute (JournalRoute, RecordDetailRoute) & AppStackCodec
├── core/
│   ├── database/                  # On-device SQLite infrastructure
│   │   ├── database_manager.dart  # Connection pool, path resolution, and lifecycle
│   │   └── migrations.dart        # ArcaDatabaseMigrations: profiles, journal_entries, indexes
│   └── design_system/             # Foundation UI (Decoupled from Material/Cupertino)
│       ├── tokens/                # Colors, Spacing, Radii, Typography
│       └── widgets/               # ArcaScaffold, ArcaHeader, ArcaButton, ArcaCard, ArcaBadge
└── features/
    ├── profiles/                  # Multi-member family archive & vault switcher
    │   ├── domain/                # Profile model (self, child, parent, etc.) & ProfileRepository
    │   ├── data/                  # SqliteProfileRepository & InMemoryProfileRepository
    │   └── presentation/          # ProfileBloc & MemberSwitcherBar
    └── journal/                   # Primary medical journal & clinical vault
        ├── domain/                # Pure Dart models (JournalEntry, JournalCategory) & JournalRepository
        ├── data/                  # SqliteJournalRepository & InMemoryJournalRepository
        └── presentation/          # JournalBloc, JournalScreen, and RecordDetailScreen
```

---

## Seams & Layer Boundaries

| Layer | Responsibility | Imports Permitted | Outgoing Boundary / Seam |
| --- | --- | --- | --- |
| **Domain** | Clinical business logic, models, repository interfaces | Pure Dart only (`dart:core`, `dart:async`) | No dependencies on UI, database drivers, or platform SDKs. |
| **Data** | Persistence engines (`sqlite_async`), file I/O, device health sensor sync | Domain interfaces, database drivers, platform channels | Implements domain repository interfaces. Converts database rows to immutable domain models. |
| **Presentation** | State management (`flutter_bloc`), screen composition, user interaction | Domain models, design system, Flutter `widgets.dart` | Translates user events to BLoC events; renders view state snapshots. Strictly free of direct database calls. |
| **Core (Design & DB)** | Visual tokens, layout primitives, and on-device SQLite database connection pool | Flutter `widgets.dart`, `dart:ui`, `sqlite_async` | Independent of feature business logic. No `package:flutter/material.dart` or `package:flutter/cupertino.dart`. |
| **Composition Root (`lib/app`)**| Service creation, dependency injection, and router wiring | Core, Features, and Navigation | The single location where concrete repository implementations and BLoCs are instantiated. |

### Dependency Direction

```
Presentation ──► Domain ◄── Data
     │              ▲         │
     ▼              │         ▼
Core (Design)       │    Core (Database)
     ▲              │         ▲
     └─────── Composition Root ┘
```

- High-level policy (Domain) does not depend on low-level detail (Data, UI).
- Presentation depends on Domain models and interfaces, never on Data implementations.
- Data depends on Domain interfaces to fulfill contracts.

---

## Navigation: Dart 3 Sealed-Class Routing with Kaisel

Instead of string/URL-based routing or code-generation, Arca uses `kaisel`:
- **Routes as Values**: Routes are immutable sealed classes extending `KaiselRoute`:
  - `JournalRoute()`: Primary timeline
  - `RecordDetailRoute(recordId)`: Clinical detail view
- **Exhaustive Pattern Matching**: The screen builder in `lib/app/router.dart` uses a Dart 3 `switch` expression over the sealed route hierarchy, guaranteeing at compile-time that every route is handled.
- **Deep Linking**: `AppStackCodec` implements `KaiselStackCodec<AppRoute>`, decoding incoming deep links (`/records/:id`) into a multi-frame stack (`[JournalRoute(), RecordDetailRoute(id)]`) to preserve natural back navigation.

---

## Libraries and Dependencies

| Dependency | Version | Architectural Purpose |
| --- | --- | --- |
| `flutter_bloc` | `^9.1.1` | Predictable, event-driven unidirectional state management for clinical records. |
| `kaisel` | `^1.1.0` | Dart 3 native navigation using sealed classes and stack-as-state model. |
| `sqlite_async` | `^0.14.8` | High-performance asynchronous SQLite database engine with background isolate execution. |
| `sqlite3` | `^3.9.0` | Direct SQLite Dart bindings (replacing deprecated `sqlite3_flutter_libs`). |
| `path_provider` | `^2.1.6` | Locates local app support directory for the encrypted SQLite database file. |
| `path` | `^1.9.1` | Cross-platform file path manipulation. |
| `shared_preferences` | `^2.5.6` | Lightweight key-value persistence for active profile selection. |
| `flutter_lints` | `^6.0.0` | Standard Dart/Flutter static analysis rule set. |
| `bloc_test` | `^10.0.0` | Streamlined unit testing for BLoC state transitions. |
| `flutter_test` | SDK | Widget and accessibility harness for UI validation. |

---

## Shared vs. Native Platform Responsibilities

- **Shared (Dart / Flutter)**:
  - Clinical domain entities and validation rules
  - Journal & profile state machines and diagnostic event handlers
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
flutter analyze lib/features/profiles
flutter test test/features/profiles/profile_bloc_test.dart

# Outer gate: full check
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```
