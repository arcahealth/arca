import 'package:flutter/widgets.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/features/onboarding/presentation/screens/ai_prep_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/document_scan_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/extracted_review_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/manual_name_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/manual_vitals_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/setup_choice_screen.dart';
import 'package:arca/features/onboarding/presentation/screens/welcome_screen.dart';

/// Sealed application route hierarchy for the onboarding module.
sealed class const OnboardingRoute() extends KaiselRoute {
  const factory welcome() = OnboardingWelcome;
  const factory setupChoice() = OnboardingSetupChoice;
  const factory aiPrep() = OnboardingAiPrep;
  const factory documentScan() = OnboardingDocumentScan;
  const factory extractedReview() = OnboardingExtractedReview;
  const factory manualName({String? initialName}) = OnboardingManualName;
  const factory manualVitals() = OnboardingManualVitals;
}

final class const OnboardingWelcome() extends OnboardingRoute;
final class const OnboardingSetupChoice() extends OnboardingRoute;
final class const OnboardingAiPrep() extends OnboardingRoute;
final class const OnboardingDocumentScan() extends OnboardingRoute;
final class const OnboardingExtractedReview() extends OnboardingRoute;

final class const OnboardingManualName({final String? initialName})
    extends OnboardingRoute;

final class const OnboardingManualVitals() extends OnboardingRoute;

/// Self-contained routing module managing the inverted and manual onboarding flows.
final class const OnboardingModule({
  final OnboardingRepository? onboardingRepo,
  final VoidCallback? onCompleted,
}) extends RouteModule<OnboardingRoute> {
  @override
  List<OnboardingRoute> get initialStack => const [OnboardingWelcome()];

  @override
  Widget buildPage(BuildContext context, OnboardingRoute route) {
    return switch (route) {
      OnboardingWelcome() => WelcomeScreen(
        onStart: () => context.push(const OnboardingSetupChoice()),
        onSkip: () async {
          await onboardingRepo?.setCompletedOnboarding(true);
          onCompleted?.call();
        },
      ),
      OnboardingSetupChoice() => SetupChoiceScreen(
        onChooseAuto: () => context.push(const OnboardingAiPrep()),
        onChooseManual: () => context.push(const OnboardingManualName()),
        onBack: () => context.pop(),
      ),
      OnboardingAiPrep() => AiPrepScreen(
        onReady: () => context.push(const OnboardingDocumentScan()),
        onBack: () => context.pop(),
      ),
      OnboardingDocumentScan() => DocumentScanScreen(
        onCapture: () => context.push(const OnboardingExtractedReview()),
        onSwitchToManual: () => context.push(const OnboardingManualName()),
        onBack: () => context.pop(),
      ),
      OnboardingExtractedReview() => ExtractedReviewScreen(
        onConfirm: () async {
          await onboardingRepo?.setCompletedOnboarding(true);
          onCompleted?.call();
        },
        onEditManually: () => context.push(
          const OnboardingManualName(initialName: 'Alex Morgan'),
        ),
        onBack: () => context.pop(),
      ),
      OnboardingManualName(:final initialName) => ManualNameScreen(
        initialName: initialName,
        onContinue: (name) => context.push(const OnboardingManualVitals()),
        onBack: () => context.pop(),
      ),
      OnboardingManualVitals() => ManualVitalsScreen(
        onFinish: () async {
          await onboardingRepo?.setCompletedOnboarding(true);
          onCompleted?.call();
        },
        onSkip: () async {
          await onboardingRepo?.setCompletedOnboarding(true);
          onCompleted?.call();
        },
        onBack: () => context.pop(),
      ),
    };
  }
}

/// Codec serializing and deserializing the onboarding flow routes and deep link stacks.
final class const OnboardingModuleCodec()
    extends ModuleStackCodec<OnboardingRoute> {
  @override
  List<String> encode(List<OnboardingRoute> stack) => switch (stack.last) {
    OnboardingWelcome() => const [],
    OnboardingSetupChoice() => const ['choice'],
    OnboardingAiPrep() => const ['ai-prep'],
    OnboardingDocumentScan() => const ['scan'],
    OnboardingExtractedReview() => const ['review'],
    OnboardingManualName() => const ['name'],
    OnboardingManualVitals() => const ['vitals'],
  };

  @override
  List<OnboardingRoute>? decode(List<String> segments) => switch (segments) {
    [] || [''] || ['/'] => [const OnboardingWelcome()],
    ['choice'] => [const OnboardingWelcome(), const OnboardingSetupChoice()],
    ['ai-prep'] => [
      const OnboardingWelcome(),
      const OnboardingSetupChoice(),
      const OnboardingAiPrep(),
    ],
    ['scan'] => [
      const OnboardingWelcome(),
      const OnboardingSetupChoice(),
      const OnboardingAiPrep(),
      const OnboardingDocumentScan(),
    ],
    ['review'] => [
      const OnboardingWelcome(),
      const OnboardingSetupChoice(),
      const OnboardingAiPrep(),
      const OnboardingDocumentScan(),
      const OnboardingExtractedReview(),
    ],
    ['name'] => [
      const OnboardingWelcome(),
      const OnboardingSetupChoice(),
      const OnboardingManualName(),
    ],
    ['vitals'] => [
      const OnboardingWelcome(),
      const OnboardingSetupChoice(),
      const OnboardingManualName(),
      const OnboardingManualVitals(),
    ],
    _ => null,
  };
}
