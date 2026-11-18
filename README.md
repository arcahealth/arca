# Arca (Automated Records & Clinical Archive)

> **Automated health tracking and private family medical records—processed entirely on-device.**

Arca is an offline-first, privacy-focused health tracking companion and longitudinal medical journal. It eliminates the friction, fragmentation, and privacy risks of managing personal and family health data by processing records strictly on-device without routing sensitive data through third-party servers.

---

## Current Capabilities

- **First-Launch Onboarding**: Welcome flow introducing Arca's core privacy guarantees and clinical vault principles (`WelcomeScreen`).
- **Decoupled Foundation Design System**: Bespoke design system built strictly atop `package:flutter/widgets.dart` with custom tokens (colors, typography, spacing, radii) and accessible primitive widgets (`ArcaScaffold`, `ArcaHeader`, `ArcaButton`, `ArcaCard`, `ArcaBadge`, `ArcaTextField`, `ArcaProgressBar`).
- **On-Device SQLite Storage**: Local encrypted SQLite database backed by `sqlite_async` with background isolate query execution and schema migrations (`ArcaDatabaseMigrations`).
- **Onboarding Persistence**: Key-value persistence for onboarding status backed by `SharedPreferencesAsync`.
- **DAG Dependency Injection**: Zero-codegen graph-based dependency injection engine bridged to Flutter via `CircuitProvider` (`circuitry_flutter`).
- **Type-Safe Sealed Navigation**: Stack-as-state routing powered by `kaisel` with exhaustive Dart 3 pattern matching and URL stack codecs.

Planned capabilities (background biometrics sync, on-device OCR, multi-member family archive) are tracked in [`docs/plan.md`](docs/plan.md).

---

## Architectural Principles

1. **Decoupled Foundation UI**: Arca avoids monolithic Material and Cupertino framework APIs. Built atop core Flutter primitives (`WidgetsApp`, basic widgets, and custom design tokens for typography, spacing, and colors), shielding the app from future framework decoupling migration debt.
2. **Deterministic State Transitions**: Built with `flutter_bloc` for explicit event-driven state handling, testable pipelines, and clear clinical auditability across family profiles.
3. **Dart 3 Sealed Navigation**: Uses `kaisel` for type-safe routing powered by Dart 3 sealed classes, exhaustive pattern matching, and a stack-as-state model rather than URL strings or code generation.
4. **On-Device Relational Storage**: Local encrypted SQLite database backed by `sqlite_async` (omitting deprecated `sqlite3_flutter_libs`) with background isolate execution and schema migrations for responsive clinical queries.
5. **Modern Language Idioms & Collections/Async Baseline**: Built with Dart 3.14 primary constructors and dot-shorthands across domain entities, routes, and widgets. Backed by canonical packages (`collection` and `async`) for priority queues, binary search, deep equality, and cancelable asynchronous pipelines.

---

## Project Structure

```
arca/
├── .github/workflows/ci.yml       # Automated formatting, lint, and test verification
├── android/                       # Android host project (namespace & appId: health.arca.app)
├── ios/                           # iOS host project (bundleId: health.arca.app)
├── docs/
│   ├── decisions.md               # Architectural decision records
│   ├── architecture.md            # Detailed system architecture, seams, and module tree
│   └── plan.md                    # Active roadmap and implementation checklist
├── lib/
│   ├── main.dart                  # Clean application entry point running const ArcaApp()
│   ├── app/                       # Composition root, dependency container, and router setup
│   │   ├── app.dart               # ArcaApp: CircuitProvider + WidgetsApp.router
│   │   └── router/                # ArcaRouter, sealed ArcaRoute/OnboardingRoute, stack codecs & ArcaRouter.wire
│   ├── core/                      # Shared design system, database, and domain infrastructure
│   │   ├── database/              # DatabaseConfig, DatabaseService, DatabaseManager, migrations, SQLite connection pool
│   │   ├── design_system/         # Tokens (colors, typography, spacing) and basic widgets
│   │   └── onboarding/            # OnboardingRepository, onboardingRepoWire (SharedPrefsOnboardingRepository)
│   └── features/                  # Self-contained feature modules
│       └── welcome/               # First-launch welcome & privacy value pillars (WelcomeScreen)
└── test/                          # Unit, SQLite, router, widget, and accessibility tests
```

---

## Prerequisites & Setup

- **Flutter SDK**: `>= 3.50.0`
- **Dart SDK**: `>= 3.14.0`
- **Android**: Min SDK 26 (Android 8.0), Target SDK 34+
- **iOS**: Min iOS 16.0+

### Install Dependencies

```bash
flutter pub get
```

---

## Verification & Commands

### Code Formatting

```bash
# Check formatting
dart format --output=none --set-exit-if-changed .

# Apply formatting
dart format .
```

### Static Analysis

```bash
# Run strict linter (fatal warnings and infos)
flutter analyze --fatal-infos --fatal-warnings
```

### Run Tests

```bash
# Run entire test suite
flutter test
```

### Run Application

```bash
flutter run
```

---

## License

Copyright © 2026 Arca Health. All rights reserved. Proprietary software.
