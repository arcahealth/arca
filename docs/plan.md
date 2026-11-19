# Plan

## Done this release
- Migrate Arca to external `circuitry_flutter` package and decommission `lib/core/di/`.
- Implement `CircuitProvider` and `CircuitState` Flutter bridge for Wire & Circuit DI.
- Combine `DatabaseConfig.wire` and `DatabaseManager.open` static async factory.
- Adopt `SharedPreferencesAsync` in `SharedPrefsOnboardingRepository`.
- Clean up prototype feature modules to isolate `WelcomeScreen` and onboarding router.
- Implement inverted onboarding UI/UX flow with automatic document scan and manual voice/text paths.
- Streamline onboarding to 3-step scan/manual paths leveraging bundled onnxruntime and RapidOCR.
- Bundle recommended PP-OCRv6 OCR and MiniLM-L6 PII ONNX models and companion assets.

## Next

### Multi-member health vault and setup wizard

- **Release:** 0.2.0
- **Goal:** Guide first-launch users through vault setup and establish profile containers for family members.
- **Requirements:**
  - Create multi-step wizard after welcome screen with optional vault configuration.
  - Implement route guard directing empty vaults to setup and multi-vaults to selection.
  - Persist active vault selection and family profiles in local SQLite database.
- **Approach:** Add `setup_wizard` and `vaults` feature modules using BLoC, constructor callbacks, and core SQLite repositories.
- **Acceptance:** User completes wizard, creates a vault, and reaches the health dashboard; tests verify flow and route guard.

### Apple HealthKit & Google Health Connect background sync

- **Release:** 0.3.0
- **Goal:** Ingest biometrics and clinical metrics in the background from native health stores.
- **Requirements:**
  - Request granular health permissions with clear rationale.
  - Periodic background sync workers for steps, heart rate, sleep, and vitals.
  - Normalize HealthKit and Health Connect samples into clinical domain records.
- **Approach:** Native platform method channels feeding background isolates that write directly to local SQLite database.
- **Acceptance:** Biometric records sync into database without UI lag; mocked channels pass integration tests.

### On-device OCR document processing pipeline

- **Release:** 0.4.0
- **Goal:** Transform paper lab reports and prescriptions into structured records on-device.
- **Requirements:**
  - Process camera/document scans using local quantized vision/OCR models.
  - Extract clinical entities (dates, test names, numeric values, reference ranges).
  - Zero network transmission during extraction.
- **Approach:** Dedicated processing service with background isolates and progress streaming to UI.
- **Acceptance:** Scanned lab image parses into structured clinical record in SQLite with confidence scores.

### Longitudinal clinical trend analysis & visualization

- **Release:** 0.5.0
- **Goal:** Render longitudinal trends and charts for lab markers and biometric vitals.
- **Requirements:**
  - Query time-series biometric and lab data efficiently from SQLite indexes.
  - Render accessible, scalable charts using foundation design system primitives.
  - Support range zooming and metric comparisons across family members.
- **Approach:** Domain use cases for time-series aggregation feeding presentation BLoCs and custom canvas widgets.
- **Acceptance:** Charts render under 16ms frame budget across 2+ years of simulated data.

### Encrypted local SQLite backup & export tool

- **Release:** 0.6.0
- **Goal:** Provide secure, sovereign backup and export of entire health vault.
- **Requirements:**
  - Export password-encrypted archive containing database and attached scans.
  - Validate checksum and schema compatibility before restoring backup.
  - Zero external server dependencies for backup creation or restore.
- **Approach:** Stream encrypted zip archive directly to user-selected filesystem destination.
- **Acceptance:** Export and import round-trip restores complete vault state without data corruption.
