import 'package:kaisel/kaisel.dart';

/// Sealed application route hierarchy for Arca.
///
/// Designed with Dart 3 sealed classes to enforce exhaustive switch matching
/// across all screens.
sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

/// Primary journal timeline route.
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
      JournalRoute() => Uri(path: '/'),
      RecordDetailRoute(:final recordId) => Uri(path: '/records/$recordId'),
    };
  }

  @override
  List<AppRoute>? decode(Uri uri) {
    final segments = uri.pathSegments;
    return switch (segments) {
      [] || [''] => const [JournalRoute()],
      ['records', final id] => [const JournalRoute(), RecordDetailRoute(id)],
      _ => null,
    };
  }
}
