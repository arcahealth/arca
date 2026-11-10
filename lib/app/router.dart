import 'package:kaisel/kaisel.dart';

import '../features/welcome/presentation/screens/welcome_screen.dart';
import 'routes.dart';

/// Constructs the top-level Kaisel router configuration with sealed-route pattern matching.
KaiselRouterConfig<AppRoute> createAppRouter({
  AppRoute initial = const WelcomeRoute(),
}) {
  return KaiselRouterConfig<AppRoute>(
    initial: initial,
    codec: const StackToConfigCodec(AppStackCodec()),
    builder: (context, route) => switch (route) {
      WelcomeRoute() => const WelcomeScreen(),
    },
  );
}
