import 'package:kaisel/kaisel.dart';

/// Sealed application route hierarchy for Arca.
sealed class const AppRoute() extends KaiselRoute;

/// First-launch welcome screen introducing Arca.
final class const WelcomeRoute() extends AppRoute {
  @override
  List<Object?> get props => const [];
}

/// Stack codec enabling deep linking and restoring multi-frame back stacks.
class const AppStackCodec() extends KaiselStackCodec<AppRoute> {
  @override
  Uri encode(List<AppRoute> stack) {
    if (stack.isEmpty) return Uri(path: '/');
    return switch (stack.last) {
      WelcomeRoute() => Uri(path: '/'),
    };
  }

  @override
  List<AppRoute>? decode(Uri uri) {
    final segments = uri.pathSegments;
    return switch (segments) {
      [] || [''] || ['welcome'] => const [WelcomeRoute()],
      _ => null,
    };
  }
}
