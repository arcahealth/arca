import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../../../../core/model_downloader/models/ai_model_capability.dart';
import '../bloc/model_downloader_bloc.dart';
import '../bloc/model_downloader_state.dart';

/// Screen displaying the download of selected on-device AI capabilities during first launch.
///
/// Self-contained: forwards user continuation via [onContinue] callback.
class const ModelDownloadScreen({
  super.key,
  final List<String> selectedCapabilityIds = const [],
  final VoidCallback? onContinue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelDownloaderBloc, ModelDownloaderUIState>(
      builder: (context, state) {
        final totalPct = (state.totalProgress * 100).round();

        return ArcaScaffold(
          header: ArcaHeader(
            title: 'Downloading Edge AI',
            subtitle: state.allCompleted
                ? 'All models ready for offline processing'
                : 'Downloading quantized neural weights locally ($totalPct%)',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                ArcaCard(
                  backgroundColor: ArcaColors.surfaceElevated,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          const Text(
                            'Overall Progress',
                            style: ArcaTypography.titleMedium,
                          ),
                          Text(
                            '$totalPct%',
                            style: ArcaTypography.titleMedium.copyWith(
                              color: ArcaColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ArcaSpacing.sm),
                      ArcaProgressBar(
                        value: state.totalProgress,
                        height: 10.0,
                        semanticsLabel: 'Overall AI download progress',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ArcaSpacing.lg),
                const Text(
                  'Active Model Bundles',
                  style: ArcaTypography.titleMedium,
                ),
                const SizedBox(height: ArcaSpacing.sm),
                for (final type in AiModelCapabilityType.values)
                  if (selectedCapabilityIds.isEmpty ||
                      selectedCapabilityIds.contains(type.id)) ...[
                    _buildCapabilityItem(type, state.capabilities[type]),
                    const SizedBox(height: ArcaSpacing.sm),
                  ],
                const SizedBox(height: ArcaSpacing.md),
                Container(
                  padding: const EdgeInsets.all(ArcaSpacing.md),
                  decoration: BoxDecoration(
                    color: ArcaColors.surface,
                    borderRadius: ArcaRadii.md,
                    border: Border.all(color: ArcaColors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      const Text('ℹ️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: ArcaSpacing.sm),
                      Expanded(
                        child: Text(
                          'You do not need to wait for downloads to complete. Tapping "Continue to App" runs the downloader seamlessly in the background with a live indicator.',
                          style: ArcaTypography.caption.copyWith(
                            color: ArcaColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomBar: Container(
            padding: const EdgeInsets.all(ArcaSpacing.md),
            decoration: const BoxDecoration(
              color: ArcaColors.background,
              border: Border(
                top: BorderSide(color: ArcaColors.borderSubtle, width: 1.0),
              ),
            ),
            child: ArcaButton(
              label: state.allCompleted
                  ? 'Open Health Dashboard →'
                  : 'Continue to App (Background Download) →',
              variant: .primary,
              semanticsLabel: 'Proceed to Arca application',
              onPressed: onContinue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapabilityItem(
    AiModelCapabilityType type,
    AiModelCapability? capability,
  ) {
    final status = capability?.status ?? .queued;
    final progress = capability?.progress ?? 0.0;
    final pct = (progress * 100).round();

    final statusBadge = switch (status) {
      .ready => const ArcaBadge(label: 'READY', variant: .normal),
      .downloading => ArcaBadge(label: '$pct%', variant: .info),
      .queued => const ArcaBadge(label: 'QUEUED', variant: .neutral),
      .paused => const ArcaBadge(label: 'PAUSED', variant: .warning),
      .failed => const ArcaBadge(label: 'ERROR', variant: .critical),
      .notInstalled => const ArcaBadge(label: 'OFF', variant: .neutral),
    };

    return ArcaCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.name,
                  style: ArcaTypography.titleMedium.copyWith(fontSize: 15),
                ),
              ),
              statusBadge,
            ],
          ),
          const SizedBox(height: ArcaSpacing.xxs),
          Text(
            type.description,
            style: ArcaTypography.caption.copyWith(
              color: ArcaColors.textSecondary,
            ),
          ),
          const SizedBox(height: ArcaSpacing.sm),
          ArcaProgressBar(
            value: progress,
            height: 6.0,
            semanticsLabel: '${type.name} download progress',
          ),
        ],
      ),
    );
  }
}
