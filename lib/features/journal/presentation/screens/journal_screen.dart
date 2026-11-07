import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../domain/models/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';

/// Primary journal timeline screen displaying local clinical and biometric records.
///
/// Completely self-contained: forwards user intents purely through constructor
/// callbacks [onRecordSelected] and [onManageVaults], and accepts optional slots [topBanner]
/// and [vaultSwitcher] without cross-feature imports or router dependencies.
class JournalScreen extends StatelessWidget {
  const JournalScreen({
    super.key,
    this.onRecordSelected,
    this.onManageVaults,
    this.topBanner,
    this.vaultSwitcher,
    this.activeMemberName,
  });

  final ValueChanged<String>? onRecordSelected;
  final VoidCallback? onManageVaults;
  final Widget? topBanner;
  final Widget? vaultSwitcher;
  final String? activeMemberName;

  @override
  Widget build(BuildContext context) {
    final subtitle = activeMemberName != null
        ? '$activeMemberName • Longitudinal Family Vault'
        : 'On-Device Family Medical Vault';

    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Arca Journal',
        subtitle: subtitle,
        trailing: ArcaButton(
          label: '+ Log Vitals',
          variant: ArcaButtonVariant.primary,
          semanticsLabel: 'Log new on-device biometric reading',
          onPressed: () {
            final now = DateTime.now();
            final newEntry = JournalEntry(
              id: 'vital-${now.millisecondsSinceEpoch}',
              title: 'Blood Pressure & Pulse Log',
              summary:
                  '118/76 mmHg, 68 bpm. Resting measurement recorded manually.',
              category: JournalCategory.vital,
              recordedAt: now,
              memberId: 'self',
            );
            context.read<JournalBloc>().add(JournalEntryAdded(newEntry));
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?topBanner,
          ?vaultSwitcher,
          Expanded(
            child: BlocBuilder<JournalBloc, JournalState>(
              builder: (context, state) => switch (state) {
                JournalInitial() || JournalLoading() => const Center(
                  child: Text(
                    'Accessing local encrypted vault...',
                    style: ArcaTypography.bodyMedium,
                  ),
                ),
                JournalFailure(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ArcaSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Vault Access Error',
                          style: ArcaTypography.titleMedium,
                        ),
                        const SizedBox(height: ArcaSpacing.xs),
                        Text(message, style: ArcaTypography.bodyMedium),
                        const SizedBox(height: ArcaSpacing.md),
                        ArcaButton(
                          label: 'Retry',
                          onPressed: () => context.read<JournalBloc>().add(
                            const JournalLoadRequested(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                JournalLoaded(:final entries) =>
                  entries.isEmpty
                      ? Center(
                          child: Text(
                            'No clinical records found for ${activeMemberName ?? "this vault"}.',
                            style: ArcaTypography.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(ArcaSpacing.md),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: ArcaSpacing.sm),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return ArcaCard(
                              key: ValueKey(entry.id),
                              onTap: () => onRecordSelected?.call(entry.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    runSpacing: ArcaSpacing.xxs,
                                    children: [
                                      ArcaBadge(
                                        label: entry.category.name
                                            .toUpperCase(),
                                        variant: _badgeVariantFor(
                                          entry.category,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(entry.recordedAt),
                                        style: ArcaTypography.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: ArcaSpacing.sm),
                                  Text(
                                    entry.title,
                                    style: ArcaTypography.titleMedium,
                                  ),
                                  const SizedBox(height: ArcaSpacing.xxs),
                                  Text(
                                    entry.summary,
                                    style: ArcaTypography.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              },
            ),
          ),
        ],
      ),
    );
  }

  static ArcaBadgeVariant _badgeVariantFor(JournalCategory category) {
    return switch (category) {
      JournalCategory.vital => ArcaBadgeVariant.info,
      JournalCategory.lab => ArcaBadgeVariant.normal,
      JournalCategory.visit => ArcaBadgeVariant.warning,
      JournalCategory.medication => ArcaBadgeVariant.critical,
    };
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
