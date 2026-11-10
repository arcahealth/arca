import 'package:arca/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:kaisel/kaisel.dart';

sealed class const OnboardingRoute() extends KaiselRoute {
  const factory welcome() = OnboardingWelcome;
}

final class const OnboardingWelcome() extends OnboardingRoute;

final class const OnboardingModule() extends RouteModule<OnboardingRoute> {
  @override
  List<OnboardingRoute> get initialStack => const [OnboardingWelcome()];

  @override
  Widget buildPage(BuildContext context, OnboardingRoute route) {
    return switch (route) {
      OnboardingWelcome() => const WelcomeScreen(),
    };
  }
}

final class const OnboardingModuleCodec()
    extends ModuleStackCodec<OnboardingRoute> {
  @override
  List<String> encode(List<OnboardingRoute> stack) => switch (stack.last) {
    OnboardingWelcome() => const [],
  };

  @override
  List<OnboardingRoute>? decode(List<String> segments) => switch (segments) {
    [] || [''] || ['/'] => [const OnboardingWelcome()],
    _ => null,
  };
}
