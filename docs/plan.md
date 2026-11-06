# Plan

## Done
- [x] Initialized Flutter project for Arca targeting Android & iOS (`health.arca.app`)
- [x] Recorded baseline architectural choices in `docs/decisions.md`
- [x] Decoupled Foundation Design System: Design tokens (`ArcaColors`, `ArcaSpacing`, `ArcaRadii`, `ArcaTypography`) and basic primitives (`ArcaScaffold`, `ArcaHeader`, `ArcaButton`, `ArcaCard`, `ArcaBadge`) built strictly on `package:flutter/widgets.dart`
- [x] Added core dependencies (`flutter_bloc`, `kaisel`, `sqlite_async`, `shared_preferences`, `bloc_test`)
- [x] Feature-first architecture: `lib/features/journal/` with domain models, repository interfaces, fake implementations, and BLoC
- [x] Dart 3 sealed navigation: `kaisel` router configuration (`AppRoute`, `AppStackCodec`, `JournalRoute`, `RecordDetailRoute`)
- [x] Composition root: `ArcaApp` using `WidgetsApp.router` with `RepositoryProvider` and `BlocProvider`
- [x] Automated test harness: 12 tests spanning BLoC unit tests, deep link codec tests, widget navigation tests, and accessibility tests
- [x] Accessibility baseline: 48x48 dp minimum tap targets, semantic labels, and resilience to 2.0x font scaling without overflow
- [x] CI workflow: `.github/workflows/ci.yml` running formatting checks, linter, and full test suite
- [x] Project documentation: `README.md`, `docs/architecture.md`, `docs/decisions.md`, and `AGENTS.md`

## Next
- [ ] On-device SQLite schema setup using `sqlite_async` for multi-table clinical metrics
- [ ] Multi-member profile domain model & family vault switching
- [ ] Apple HealthKit & Google Health Connect background ingestion sync services
- [ ] On-device OCR document processing pipeline (scanned lab panels and prescriptions)
