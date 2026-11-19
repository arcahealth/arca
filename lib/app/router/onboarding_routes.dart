import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:kaisel/kaisel.dart';

import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:arca/features/onboarding/presentation/screens/screens.dart';

/// Sealed application route hierarchy for the onboarding module.
sealed class const OnboardingRoute() extends KaiselRoute {
  const factory welcome() = _OnboardingWelcome;
  const factory documentScan() = _OnboardingDocumentScan;
  const factory extractedReview({
    String extractedName,
    String extractedDob,
    String extractedMedication,
    String extractedAllergy,
  }) = _OnboardingExtractedReview;
  const factory userName({String? initialName}) = _OnboardingUserName;
}

final class const _OnboardingWelcome() extends OnboardingRoute;
final class const _OnboardingDocumentScan() extends OnboardingRoute;
final class const _OnboardingExtractedReview({
  final String extractedName = '',
  final String extractedDob = '',
  final String extractedMedication = '',
  final String extractedAllergy = '',
}) extends OnboardingRoute;

final class const _OnboardingUserName({final String? initialName}) extends OnboardingRoute;

/// Self-contained routing module managing the streamlined scan and manual onboarding flows.
final class const OnboardingModule([
  final OnboardingRepository? onboardingRepo,
  final VoidCallback? onCompleted,
]) extends RouteModule<OnboardingRoute> {
  @override
  List<OnboardingRoute> get initialStack => const [.welcome()];

  @override
  Widget buildPage(BuildContext context, OnboardingRoute route) {
    final repo = onboardingRepo ?? CircuitProvider.of(context).get<OnboardingRepository>();

    return switch (route) {
      _OnboardingWelcome() => WelcomeScreen(
        onScan: () => context.push(const OnboardingRoute.documentScan()),
        onManualEntry: () => context.push(const OnboardingRoute.userName()),
        onSkip: () async {
          await repo.setCompletedOnboarding(true);
          onCompleted?.call();
        },
      ),
      _OnboardingDocumentScan() => DocumentScanScreen(
        onImagesCaptured: (paths) => context.push(
          const OnboardingRoute.extractedReview(
            extractedName: 'Alex Morgan',
            extractedDob: '1988-04-12',
            extractedMedication: 'Amoxicillin 500mg',
            extractedAllergy: 'Penicillin',
          ),
        ),
        onCapture: () => context.push(
          const OnboardingRoute.extractedReview(
            extractedName: 'Alex Morgan',
            extractedDob: '1988-04-12',
            extractedMedication: 'Amoxicillin 500mg',
            extractedAllergy: 'Penicillin',
          ),
        ),
        onSwitchToManual: () => context.push(const OnboardingRoute.userName()),
        onBack: () => context.pop(),
      ),
      _OnboardingUserName(:final initialName) => UserNameScreen(
        initialName: initialName,
        onContinue: (name) => context.push(OnboardingRoute.extractedReview(extractedName: name)),
        onBack: () => context.pop(),
      ),
      _OnboardingExtractedReview(
        :final extractedName,
        :final extractedDob,
        :final extractedMedication,
        :final extractedAllergy,
      ) =>
        ExtractedReviewScreen(
          extractedName: extractedName,
          extractedDob: extractedDob,
          extractedMedication: extractedMedication,
          extractedAllergy: extractedAllergy,
          onConfirm: () async {
            await repo.setCompletedOnboarding(true);
            onCompleted?.call();
          },
          onEditManually: () => context.push(
            OnboardingRoute.userName(initialName: extractedName),
          ),
          onBack: () => context.pop(),
        ),
    };
  }
}

/// Codec serializing and deserializing the onboarding flow routes and deep link stacks.
final class const OnboardingModuleCodec() extends ModuleStackCodec<OnboardingRoute> {
  @override
  List<String> encode(List<OnboardingRoute> stack) => switch (stack.last) {
    _OnboardingWelcome() => const [],
    _OnboardingDocumentScan() => const ['scan'],
    _OnboardingUserName() => const ['manual'],
    _OnboardingExtractedReview() => const ['overview'],
  };

  @override
  List<OnboardingRoute>? decode(List<String> segments) => switch (segments) {
    [] || [''] || ['/'] => const [.welcome()],
    ['scan'] => const [.welcome(), .documentScan()],
    ['manual'] => const [.welcome(), .userName()],
    ['overview'] => const [.welcome(), .documentScan(), .extractedReview()],
    _ => null,
  };
}
