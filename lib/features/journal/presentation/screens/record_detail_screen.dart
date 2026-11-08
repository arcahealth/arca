import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

/// Detail screen displaying full diagnostic metadata and on-device clinical audit status.
///
/// Self-contained: forwards back navigation via constructor callback [onBack].
/// Resolves [JournalRepository] interface via constructor injection or [RepositoryProvider].
class const RecordDetailScreen({
  required final String recordId,
  super.key,
  final JournalRepository? repository,
  final VoidCallback? onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = repository ?? context.read<JournalRepository>();

    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Clinical Record Detail',
        subtitle: 'Processed entirely on-device',
        leading: ArcaButton(
          label: '← Back',
          variant: .ghost,
          semanticsLabel: 'Navigate back to journal timeline',
          onPressed: onBack,
        ),
      ),
      body: FutureBuilder<JournalEntry?>(
        future: repo.getEntryById(recordId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Text(
                'Loading on-device clinical record...',
                style: ArcaTypography.bodyMedium,
              ),
            );
          }

          final entry = snapshot.data;
          if (entry == null) {
            return Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  const Text(
                    'Record Not Found',
                    style: ArcaTypography.titleMedium,
                  ),
                  const SizedBox(height: ArcaSpacing.sm),
                  Text(
                    'No local record matched ID: $recordId',
                    style: ArcaTypography.bodyMedium,
                  ),
                  const SizedBox(height: ArcaSpacing.lg),
                  ArcaButton(label: 'Return to Timeline', onPressed: onBack),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    ArcaBadge(
                      label: entry.category.name.toUpperCase(),
                      variant: .info,
                    ),
                    if (entry.isVerifiedOnDevice)
                      const ArcaBadge(
                        label: 'VERIFIED ON-DEVICE',
                        variant: .normal,
                      ),
                  ],
                ),
                const SizedBox(height: ArcaSpacing.md),
                Text(entry.title, style: ArcaTypography.titleLarge),
                const SizedBox(height: ArcaSpacing.xs),
                Text(
                  'Recorded ${entry.recordedAt.toLocal().toString().split('.').first}',
                  style: ArcaTypography.caption,
                ),
                const SizedBox(height: ArcaSpacing.lg),
                ArcaCard(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const Text(
                        'Clinical Findings & Summary',
                        style: ArcaTypography.titleMedium,
                      ),
                      const SizedBox(height: ArcaSpacing.sm),
                      Text(entry.summary, style: ArcaTypography.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: ArcaSpacing.md),
                const ArcaCard(
                  backgroundColor: ArcaColors.surfaceSubtle,
                  borderColor: ArcaColors.borderSubtle,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'Data Sovereignty Guarantee',
                        style: ArcaTypography.caption,
                      ),
                      SizedBox(height: ArcaSpacing.xxs),
                      Text(
                        'This record is encrypted and indexed only in your local SQLite store. No telemetry or server syncing occurred.',
                        style: ArcaTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
