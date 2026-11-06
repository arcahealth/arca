# Plan

## Done
- [x] Initialized Flutter project for Arca targeting Android & iOS (`health.arca.app`)
- [x] Recorded baseline architectural choices in `docs/decisions.md`
- [x] Decoupled Foundation Design System: Design tokens (`ArcaColors`, `ArcaSpacing`, `ArcaRadii`, `ArcaTypography`) and basic primitives (`ArcaScaffold`, `ArcaHeader`, `ArcaButton`, `ArcaCard`, `ArcaBadge`) built strictly on `package:flutter/widgets.dart`
- [x] Added core dependencies (`flutter_bloc`, `kaisel`, `sqlite_async`, `sqlite3`, `path_provider`, `path`, `shared_preferences`, `bloc_test`)
- [x] Feature-first architecture: `lib/features/journal/` with domain models, repository interfaces, fake implementations, and BLoC
- [x] Dart 3 sealed navigation: `kaisel` router configuration (`AppRoute`, `AppStackCodec`, `JournalRoute`, `RecordDetailRoute`)
- [x] Composition root: `ArcaApp` using `WidgetsApp.router` with `MultiRepositoryProvider` and `MultiBlocProvider`
- [x] On-Device SQLite Storage Layer: `DatabaseManager` and `ArcaDatabaseMigrations` via `sqlite_async` with background isolate execution and `SqliteJournalRepository`
- [x] Multi-Member Family Archive: `Profile` domain model, `SqliteProfileRepository`, `ProfileBloc`, and `MemberSwitcherBar` with active profile switching and timeline filtering
- [x] Automated test harness: 24 tests spanning unit tests, SQLite integration tests, route codec tests, widget navigation, profile switching, and accessibility baseline tests
- [x] Accessibility baseline: 48x48 dp minimum tap targets, semantic labels, and resilience to 2.0x font scaling without overflow
- [x] CI workflow: `.github/workflows/ci.yml` running formatting checks, linter, and full test suite
- [x] Project documentation: `README.md`, `docs/architecture.md`, `docs/decisions.md`, and `AGENTS.md`

## Next
- [ ] Apple HealthKit & Google Health Connect background ingestion sync services
- [ ] On-device OCR document processing pipeline (scanned lab panels and prescriptions)
- [ ] Longitudinal clinical trend analysis & chart visualization
- [ ] Encrypted local SQLite backup & export tool
