import 'package:kaisel/kaisel.dart';

/// Sealed application route hierarchy for Arca.
///
/// Designed with Dart 3 sealed classes to enforce exhaustive switch matching
/// across all screens.
sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

/// First-launch welcome screen introducing Arca.
final class WelcomeRoute extends AppRoute {
  const WelcomeRoute();

  @override
  List<Object?> get props => const [];
}

/// Setup wizard route for configuring initial Health Vaults and AI capabilities.
final class SetupWizardRoute extends AppRoute {
  const SetupWizardRoute();

  @override
  List<Object?> get props => const [];
}

/// On-device AI capability download progress screen.
final class ModelDownloadRoute extends AppRoute {
  const ModelDownloadRoute({this.selectedCapabilityIds = const []});

  final List<String> selectedCapabilityIds;

  @override
  List<Object?> get props => [selectedCapabilityIds];
}

/// Compatibility alias.
typedef AiDownloadRoute = ModelDownloadRoute;

/// Vault switcher and empty-vault creation guard screen.
final class VaultSelectionRoute extends AppRoute {
  const VaultSelectionRoute();

  @override
  List<Object?> get props => const [];
}

/// Primary clinical dashboard and health vault timeline route.
final class JournalRoute extends AppRoute {
  const JournalRoute();

  @override
  List<Object?> get props => const [];
}

/// Detail view for a specific clinical record or biometric scan.
final class RecordDetailRoute extends AppRoute {
  const RecordDetailRoute(this.recordId);

  final String recordId;

  @override
  List<Object?> get props => [recordId];
}

/// Stack codec enabling deep linking and restoring multi-frame back stacks.
class AppStackCodec extends KaiselStackCodec<AppRoute> {
  const AppStackCodec();

  @override
  Uri encode(List<AppRoute> stack) {
    if (stack.isEmpty) return Uri(path: '/');
    return switch (stack.last) {
      WelcomeRoute() => Uri(path: '/welcome'),
      SetupWizardRoute() => Uri(path: '/setup'),
      ModelDownloadRoute() => Uri(path: '/model-download'),
      VaultSelectionRoute() => Uri(path: '/vaults'),
      JournalRoute() => Uri(path: '/'),
      RecordDetailRoute(:final recordId) => Uri(path: '/records/$recordId'),
    };
  }

  @override
  List<AppRoute>? decode(Uri uri) {
    final segments = uri.pathSegments;
    return switch (segments) {
      [] || [''] => const [JournalRoute()],
      ['welcome'] => const [WelcomeRoute()],
      ['setup'] => const [SetupWizardRoute()],
      ['model-download'] || ['ai-download'] => const [ModelDownloadRoute()],
      ['vaults'] => const [VaultSelectionRoute()],
      ['records', final id] => [const JournalRoute(), RecordDetailRoute(id)],
      _ => null,
    };
  }
}
