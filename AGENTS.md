# Agent Guidelines for Arca

Welcome! Arca is an offline-first, privacy-focused health tracking companion and private family medical vault processed entirely on-device.

- **Stack:** Flutter (Dart 3.14+ / `package:flutter/widgets.dart` with bespoke foundation design system; no `material.dart` or `cupertino.dart`).
- **State & Architecture:** BLoC, feature-first, strict layer seams (UI -> Logic -> Domain <- Data).
- **Conventions:** Invoke the `mobile-conventions` skill before changing or reviewing code, and follow `reference/flutter.md`.

## Project Documents
- [`docs/decisions.md`](docs/decisions.md): Durable architectural choices and reasons; keep decisions that govern the code.
- [`docs/architecture.md`](docs/architecture.md): Current system shape, seams, module layout, dependencies, and architecture commands.
- [`docs/plan.md`](docs/plan.md): Active and next work only; tracked features get a short entry before code. Refactors and fixes do not.
- [`README.md`](README.md): Current shipped behavior, setup, commands, and layout.

## Verification & Commands
- **Inner loop:**
  ```bash
  flutter analyze lib/features/<touched-feature>
  flutter test test/features/<touched-feature>/<test-file>.dart
  ```
- **Verification gate:**
  ```bash
  dart format --output=none --set-exit-if-changed .
  flutter analyze --fatal-infos --fatal-warnings
  flutter test
  ```
- Interactive elements must maintain minimum 48x48 dp touch targets and semantic labels.
