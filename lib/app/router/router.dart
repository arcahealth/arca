import 'package:arca/app/router/onboarding_routes.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:kaisel/kaisel.dart';

/// Sealed application route hierarchy for Arca.
sealed class const ArcaRoute() extends KaiselRoute {
  const factory onboarding() = OnboardingMount;
}

final class const OnboardingMount() extends ArcaRoute;

/// Route guard collection for protecting Arca route navigation.
abstract final class ArcaRouteGuards {
  /// Redirects un-onboarded navigation to [OnboardingMount].
  static KaiselGuard<ArcaRoute> onboarding(
    OnboardingRepository onboardingRepo,
  ) {
    return (current, proposed) async {
      final hasOnboarded = await onboardingRepo.hasCompletedOnboarding();
      if (!hasOnboarded && proposed.any((r) => r is! OnboardingMount)) {
        return const [OnboardingMount()];
      }
      return proposed;
    };
  }
}

/// Static namespace configuring the root application router, codecs, and Wire recipe.
abstract final class ArcaRouter {
  /// Declarative Circuitry Wire for the application router.
  static final wire = Wire.takes<OnboardingRepository>().to(create);

  /// Constructs the top-level Kaisel router configuration with route guards and sealed-route pattern matching.
  static KaiselRouterConfig<ArcaRoute> create(
    OnboardingRepository onboardingRepo, {
    ArcaRoute initial = const OnboardingMount(),
  }) {
    return KaiselRouterConfig<ArcaRoute>(
      initial: initial,
      codec: codec(),
      guards: [ArcaRouteGuards.onboarding(onboardingRepo)],
      builder: (context, route) => switch (route) {
        OnboardingMount() => const KaiselModuleMount<OnboardingRoute>(
          module: OnboardingModule(),
        ),
      },
    );
  }

  /// Constructs the Codec for the entire app, consolidating the top-level and nested routes/modules.
  static KaiselConfigCodec<ArcaRoute> codec() =>
      ConfigCodecWithModules<ArcaRoute>(
        baseCodec: const StackToConfigCodec(AppStackCodec()),
        modules: [
          const ModuleMount(
            mountRoute: OnboardingMount(),
            prefix: '/onboarding',
            codec: OnboardingModuleCodec(),
          ),
        ],
      );
}

/// Stack codec enabling deep linking and restoring multi-frame back stacks.
final class const AppStackCodec() extends KaiselStackCodec<ArcaRoute> {
  @override
  Uri encode(List<ArcaRoute> stack) {
    if (stack.isEmpty) return Uri(path: '/');

    return switch (stack.last) {
      OnboardingMount() => Uri(path: '/onboarding'),
    };
  }

  @override
  List<ArcaRoute>? decode(Uri uri) {
    final segments = uri.pathSegments;

    return switch (segments) {
      ['onboarding'] => const [OnboardingMount()],
      _ => null,
    };
  }
}
