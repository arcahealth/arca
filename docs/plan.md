# Plan

## Done
- [x] Initialized empty Flutter project for Arca targeting Android & iOS (`health.arca.app`)
- [x] Recorded baseline architectural choices in `docs/decisions.md`

## Active: Foundation Scaffold

### Project Scaffold & Architecture Foundation
- **Status:** in progress
- **Release:** 0.1.0-alpha
- **Goal:** Establish a modular, feature-first foundation for Arca with BLoC state management, custom foundation design system (decoupled from Material/Cupertino framework APIs), `kaisel` typed sealed-class routing, dependency injection at the composition root, unit and widget test harnesses, CI workflow, and full documentation.
- **Requirements:**
  - Decoupled foundation design system: Avoid heavy material/cupertino framework styling; provide core design tokens (colors, typography, spacing) and basic widgets.
  - State management: `flutter_bloc` with clear separation of events, states, and logic.
  - Navigation: `kaisel` with typed sealed-class routes and exhaustive pattern matching.
  - Dependency Injection: Constructor injection wired at the composition root with `RepositoryProvider`.
  - Persistence foundation: Interfaces and contracts prepared for `sqlite_async` / `drift` (strictly avoiding deprecated `sqlite3_flutter_libs`).
  - Accessibility: Minimum tap targets (48x48 dp), semantic labeling, and large text scale resilience.
  - Verification: Automated format check, `flutter analyze --fatal-infos --fatal-warnings`, and `flutter test`.
- **Approach:**
  - Step 3: Implement feature-first directory layout (`lib/app`, `lib/core`, `lib/features`).
  - Step 4: Wire dependency injection with domain repository interfaces and test fakes at the edge.
  - Step 5: Configure lint rules and GitHub Actions CI workflow.
  - Step 6: Configure `kaisel` router with typed sealed classes (`HomeRoute`, `VaultRoute`, etc.).
  - Step 7: Create unit and widget tests for BLoC and navigation flows.
  - Step 8: Enforce accessibility baseline with semantically labeled primitives.
  - Step 9: Author comprehensive `README.md` and proprietary license header.
  - Step 10: Complete `docs/architecture.md` and finalize `docs/decisions.md`.
  - Step 11: Create `AGENTS.md` guiding future agent interactions.
- **Alternatives:**
  - *Material 3 standard scaffold:* Rejected due to Flutter 3.47+ framework decoupling and future migration debt.
  - *go_router navigation:* Rejected in favor of `kaisel` Dart 3 sealed class pattern matching.
- **Sub-steps:**
  - [ ] Add dependencies (`flutter_bloc`, `kaisel`) to `pubspec.yaml`
  - [ ] Structure directory tree (`lib/app`, `lib/core/design_system`, `lib/features/journal`, etc.)
  - [ ] Set up DI composition root with clinical repository interface and fake
  - [ ] Add GitHub Actions CI workflow (`.github/workflows/ci.yml`)
  - [ ] Set up `kaisel` typed router configuration and navigable sample screen
  - [ ] Add unit test for BLoC and widget test for the navigation flow
  - [ ] Add accessibility semantics and verify scaling
  - [ ] Generate `README.md` and proprietary license notices
  - [ ] Document architecture in `docs/architecture.md`
  - [ ] Add `AGENTS.md`
- **Acceptance:**
  - App compiles cleanly with `flutter analyze --fatal-infos --fatal-warnings`.
  - All tests pass via `flutter test`.
  - Navigation between two typed routes works as expected.
  - Documentation (`docs/architecture.md`, `docs/decisions.md`, `README.md`, `AGENTS.md`) is complete and aligned.
- **Docs:** `docs/architecture.md`, `docs/decisions.md`, `README.md`, `AGENTS.md`
- **Links:** `docs/decisions.md#2026-11-07-project-foundation-and-architectural-choices`

## Next
- [ ] On-device local database setup (`sqlite_async` / `drift`)
- [ ] Multi-member profile domain model & vault records
- [ ] Health Connect & Apple HealthKit ingestion background workers
- [ ] On-device OCR document processing pipeline
