import 'package:kaisel/kaisel.dart';

import '../features/journal/domain/repositories/journal_repository.dart';
import '../features/journal/presentation/screens/journal_screen.dart';
import '../features/journal/presentation/screens/record_detail_screen.dart';
import 'routes.dart';

/// Constructs the top-level Kaisel router configuration with sealed-route pattern matching.
KaiselRouterConfig<AppRoute> createAppRouter({
  required JournalRepository repository,
  AppRoute initial = const JournalRoute(),
}) {
  return KaiselRouterConfig<AppRoute>(
    initial: initial,
    codec: const StackToConfigCodec(AppStackCodec()),
    builder: (context, route) => switch (route) {
      JournalRoute() => const JournalScreen(),
      RecordDetailRoute(:final recordId) => RecordDetailScreen(
        recordId: recordId,
        repository: repository,
      ),
    },
  );
}
