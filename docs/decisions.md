# Decisions

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
