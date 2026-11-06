# Arca (Automated Records & Clinical Archive)

> **Automated health tracking and private family medical records—processed entirely on-device.**

Arca is an offline-first, privacy-focused health tracking companion and longitudinal medical journal. It eliminates the friction, fragmentation, and privacy risks of managing personal and family health data by combining background biometrics, scanned medical documents, and visit logs into a single, unified timeline—without routing sensitive health records through third-party cloud servers.

---

## Core Capabilities

- **Zero-Friction Ingestion & Sync**: Automated background aggregation of daily vitals and clinical metrics from Apple HealthKit and Google Health Connect, plus manual logging for visits, active medications, and symptoms.
- **On-Device Document Intelligence**: Local document transformation of paper lab reports and prescriptions into structured data using local OCR and quantized models—processed strictly on-device.
- **Multi-Member Family Archive**: Permanent, longitudinal health vault supporting distinct profiles (e.g., self, children, aging parents) with structured multi-year chronological trends.
- **Extreme Simplicity & Trust**: Clean journal interface with absolute data sovereignty—no remote account requirements, zero server-side telemetry, and total user ownership of exports and local backups.

---

## Architectural Principles

1. **Decoupled Foundation UI**: Arca avoids monolithic Material and Cupertino framework APIs. Built atop core Flutter primitives (`WidgetsApp`, basic widgets, and custom design tokens for typography, spacing, and colors), shielding the app from future framework decoupling migration debt.
2. **Deterministic State Transitions**: Built with `flutter_bloc` for explicit event-driven state handling, testable pipelines, and clear clinical auditability.
3. **Dart 3 Sealed Navigation**: Uses `kaisel` for type-safe routing powered by Dart 3 sealed classes, exhaustive pattern matching, and a stack-as-state model rather than URL strings or code generation.
4. **On-Device Relational Storage**: Local encrypted SQLite database backed by `sqlite_async` (omitting deprecated `sqlite3_flutter_libs`) with background isolate execution for responsive clinical queries.

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
│   ├── main.dart                  # Application entry point
│   ├── app/                       # Composition root, router setup, and sealed routes
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── routes.dart
│   ├── core/                      # Shared design system, database, and utilities
│   │   └── design_system/         # Tokens (colors, typography, spacing) and basic widgets
│   └── features/
│       └── journal/               # Clinical journal feature
│           ├── domain/            # Models (JournalEntry) and repository interface
│           ├── data/              # In-memory and SQLite repository implementations
│           └── presentation/      # JournalBloc, JournalScreen, and RecordDetailScreen
└── test/                          # Unit, widget, and accessibility test suites
```

---

## Prerequisites & Setup

- **Flutter SDK**: `>= 3.47.0`
- **Dart SDK**: `>= 3.13.0`
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
# Run entire test suite (unit, navigation codec, widget, and accessibility)
flutter test
```

### Run Application

```bash
flutter run
```

---

## License

Copyright © 2026 Arca Health. All rights reserved. Proprietary software.
