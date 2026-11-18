import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/features/onboarding/presentation/screens/screens.dart';

/// Sealed application route hierarchy for the onboarding module.
sealed class const OnboardingRoute() extends KaiselRoute {
  const factory welcome() = _OnboardingWelcome;
  const factory setupChoice() = _OnboardingSetupChoice;
  const factory aiPrep() = _OnboardingAiPrep;
  const factory documentScan() = _OnboardingDocumentScan;
  const factory extractedReview() = _OnboardingExtractedReview;
  const factory userName({String? initialName}) = _OnboardingUserName;
}

final class const _OnboardingWelcome() extends OnboardingRoute;
final class const _OnboardingSetupChoice() extends OnboardingRoute;
final class const _OnboardingAiPrep() extends OnboardingRoute;
final class const _OnboardingDocumentScan() extends OnboardingRoute;
final class const _OnboardingExtractedReview() extends OnboardingRoute;

final class const _OnboardingUserName({final String? initialName})
    extends OnboardingRoute;

/// Self-contained routing module managing the inverted and manual onboarding flows.
final class const OnboardingModule([
  final OnboardingRepository? onboardingRepo,
  final VoidCallback? onCompleted,
]) extends RouteModule<OnboardingRoute> {
  @override
  List<OnboardingRoute> get initialStack => const [.welcome()];

  @override
  Widget buildPage(BuildContext context, OnboardingRoute route) {
    final repo =
        onboardingRepo ??
        CircuitProvider.of(context).get<OnboardingRepository>();

    return switch (route) {
      _OnboardingWelcome() => WelcomeScreen(
        onStart: () => context.push(const OnboardingRoute.setupChoice()),
        onSkip: () async {
          await repo.setCompletedOnboarding(true);
          onCompleted?.call();
        },
      ),
      _OnboardingSetupChoice() => SetupChoiceScreen(
        onChooseAuto: () => context.push(const OnboardingRoute.aiPrep()),
        onChooseManual: () => context.push(const OnboardingRoute.userName()),
        onBack: () => context.pop(),
      ),
      _OnboardingAiPrep() => AiPrepScreen(
        onReady: () => context.push(const OnboardingRoute.documentScan()),
        onBack: () => context.pop(),
      ),
      _OnboardingDocumentScan() => DocumentScanScreen(
        onCapture: () => context.push(const OnboardingRoute.extractedReview()),
        onSwitchToManual: () => context.push(const OnboardingRoute.userName()),
        onBack: () => context.pop(),
      ),
      _OnboardingExtractedReview() => ExtractedReviewScreen(
        onConfirm: () async {
          await repo.setCompletedOnboarding(true);
          onCompleted?.call();
        },
        onEditManually: () => context.push(const OnboardingRoute.userName()),
        onBack: () => context.pop(),
      ),
      _OnboardingUserName(:final initialName) => UserNameScreen(
        initialName: initialName,
        onContinue: (name) async {
          await repo.setCompletedOnboarding(true);
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
    _OnboardingWelcome() => const [],
    _OnboardingSetupChoice() => const ['choice'],
    _OnboardingAiPrep() => const ['ai-prep'],
    _OnboardingDocumentScan() => const ['scan'],
    _OnboardingExtractedReview() => const ['review'],
    _OnboardingUserName() => const ['name'],
  };

  @override
  List<OnboardingRoute>? decode(List<String> segments) => switch (segments) {
    [] || [''] || ['/'] => const [.welcome()],
    ['choice'] => const [.welcome(), .setupChoice()],
    ['ai-prep'] => const [.welcome(), .setupChoice(), .aiPrep()],
    ['scan'] => const [.welcome(), .setupChoice(), .aiPrep(), .documentScan()],
    ['review'] => const [
      .welcome(),
      .setupChoice(),
      .aiPrep(),
      .documentScan(),
      .extractedReview(),
    ],
    ['name'] => const [.welcome(), .setupChoice(), .userName()],
    _ => null,
  };
}
