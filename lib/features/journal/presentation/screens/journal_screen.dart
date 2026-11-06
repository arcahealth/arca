import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaisel/kaisel.dart';

import '../../../../app/routes.dart';
import '../../../../core/design_system/arca_design_system.dart';
import '../../../profiles/domain/models/profile.dart';
import '../../../profiles/presentation/bloc/profile_bloc.dart';
import '../../../profiles/presentation/bloc/profile_event.dart';
import '../../../profiles/presentation/bloc/profile_state.dart';
import '../../../profiles/presentation/widgets/member_switcher_bar.dart';
import '../../domain/models/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';

/// Primary journal timeline screen displaying local clinical and biometric records.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ProfileLoaded? profileLoaded;
    try {
      final state = context.watch<ProfileBloc>().state;
      if (state is ProfileLoaded) {
        profileLoaded = state;
      }
    } catch (_) {
      // ProfileBloc optional fallback for isolated tests
    }

    final activeMember = profileLoaded?.activeProfile;
    final activeMemberId = activeMember?.id ?? 'self';
    final subtitle = activeMember != null
        ? '${activeMember.name} • Longitudinal Family Vault'
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
              memberId: activeMemberId,
            );
            context.read<JournalBloc>().add(JournalEntryAdded(newEntry));
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profileLoaded != null)
            MemberSwitcherBar(
              profiles: profileLoaded.profiles,
              activeProfile: profileLoaded.activeProfile,
              onProfileSelected: (profileId) {
                context.read<ProfileBloc>().add(
                  ProfileActiveSwitched(profileId),
                );
                context.read<JournalBloc>().add(
                  JournalLoadRequested(memberId: profileId),
                );
              },
              onAddProfile: () {
                final now = DateTime.now();
                final count = profileLoaded!.profiles.length;
                final newProfile = Profile(
                  id: 'member-${now.millisecondsSinceEpoch}',
                  name: 'Family Member $count',
                  relationship: ProfileRelationship.child,
                  createdAt: now,
                );
                context.read<ProfileBloc>().add(ProfileAdded(newProfile));
                context.read<JournalBloc>().add(
                  JournalLoadRequested(memberId: newProfile.id),
                );
              },
            ),
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
                            JournalLoadRequested(memberId: activeMemberId),
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
                            'No clinical records found for ${activeMember?.name ?? "this profile"}.',
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
                              onTap: () =>
                                  context.push(RecordDetailRoute(entry.id)),
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
