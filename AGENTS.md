# Agent Guidelines for Arca

Welcome! Arca is an offline-first, privacy-focused health tracking companion and private family medical vault processed entirely on-device.

When working on this repository, follow these conventions:

## 1. Required Reading Before Changing Code
Always read these four core project documents before proposing or implementing changes:
- [`docs/decisions.md`](docs/decisions.md): Architectural decisions, history, agreed choices, and rejected alternatives.
- [`docs/architecture.md`](docs/architecture.md): Current system shape, seams, module layout, dependencies, and command references.
- [`docs/plan.md`](docs/plan.md): Active goals, sub-step checklists, and project roadmap.
- [`README.md`](README.md): Project overview, developer prerequisites, and run commands.

## 2. Follow Mobile Conventions
- Invoke the `mobile-conventions` skill before changing or reviewing code, and follow the Flutter stack reference.
- Maintain layer boundaries: **UI** renders and forwards user intent; **Logic** (BLoC) manages state transitions; **Domain** owns business rules and models; **Data** handles local SQLite storage and hardware sensors.
- Never import UI or Data into the Domain layer.
- Never import `package:flutter/material.dart` or `package:flutter/cupertino.dart`. Use `package:flutter/widgets.dart` and Arca's foundation design system in `lib/core/design_system/`.

## 3. Plan First & Move Docs with Code
- Start every feature, bug fix, or refactor with an explicit entry in [`docs/plan.md`](docs/plan.md) with requirements, approach, sub-steps, and acceptance criteria.
- Update [`docs/architecture.md`](docs/architecture.md) and [`README.md`](README.md) in the **same atomic commit** whenever module shape, dependencies, commands, or behavior change.
- Record any new architectural choices or rejected options in [`docs/decisions.md`](docs/decisions.md).
- A change is considered incomplete while code and documents disagree.

## 4. Verification & Testing
- Work in the inner loop during implementation:
  ```bash
  flutter analyze lib/features/<touched-feature>
  flutter test test/features/<touched-feature>/<test-file>.dart
  ```
- Run the full verification gate before completing work:
  ```bash
  dart format --output=none --set-exit-if-changed .
  flutter analyze --fatal-infos --fatal-warnings
  flutter test
  ```
- Ensure every new interactive element includes semantic accessibility labels and maintains a minimum 48x48 dp touch target.
