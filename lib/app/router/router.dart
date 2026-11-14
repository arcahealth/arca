import 'package:arca/app/router/onboarding_routes.dart';
import 'package:arca/core/database/database_service.dart';
import 'package:arca/core/di/di.dart';
import 'package:arca/core/onboarding/repositories/onboarding_repository.dart';
import 'package:kaisel/kaisel.dart';

final appRouterWire = Wire.takes<DatabaseService>()
    .takes<OnboardingRepository>()
    .to((deps) => createAppRouter(initial: .onboarding()));

enum AppRoute(final String segment) {
  root('/'),
  onboarding('onboarding');

  String get path {
    if (segment == '/' || segment.isEmpty) return segment;

    return '/$segment';
  }
}

/// Sealed application route hierarchy for Arca.
sealed class const ArcaRoute() extends KaiselRoute {
  const factory onboarding() = OnboardingMount;
}

final class const OnboardingMount() extends ArcaRoute;

/// Constructs the Codec for the entire app, consolidating the top-level and nested routes/modules.
KaiselConfigCodec<ArcaRoute> createAppRouterCodec() =>
    ConfigCodecWithModules<ArcaRoute>(
      baseCodec: const StackToConfigCodec(AppStackCodec()),
      modules: [
        ModuleMount(
          mountRoute: OnboardingMount(),
          prefix: AppRoute.onboarding.path,
          codec: OnboardingModuleCodec(),
        ),
      ],
    );

/// Constructs the top-level Kaisel router configuration with sealed-route pattern matching.
KaiselRouterConfig<ArcaRoute> createAppRouter({required ArcaRoute initial}) {
  return KaiselRouterConfig<ArcaRoute>(
    initial: initial,
    codec: createAppRouterCodec(),
    builder: (context, route) => switch (route) {
      OnboardingMount() => const KaiselModuleMount<OnboardingRoute>(
        module: OnboardingModule(),
      ),
    },
  );
}

/// Stack codec enabling deep linking and restoring multi-frame back stacks.
class const AppStackCodec() extends KaiselStackCodec<ArcaRoute> {
  @override
  Uri encode(List<ArcaRoute> stack) {
    if (stack.isEmpty) return Uri(path: '/');

    return switch (stack.last) {
      OnboardingMount() => Uri(path: AppRoute.onboarding.path),
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
