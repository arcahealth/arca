import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/arca_design_system.dart';
import '../bloc/model_downloader_bloc.dart';
import '../bloc/model_downloader_state.dart';

/// Non-intrusive persistent status banner displayed on Dashboard/Settings
/// when background on-device AI model downloads are active.
///
/// Self-contained: forwards tap action via [onTap] callback.
class const ModelDownloadIndicatorBar({super.key, final VoidCallback? onTap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelDownloaderBloc, ModelDownloaderUIState>(
      builder: (context, state) {
        if (!state.isDownloading && !state.allCompleted) {
          return const SizedBox.shrink();
        }

        if (state.allCompleted) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: ArcaColors.successSubtle,
              borderRadius: ArcaRadii.md,
              border: Border.all(
                color: ArcaColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('✓', style: TextStyle(color: ArcaColors.success)),
                const SizedBox(width: ArcaSpacing.xs),
                Expanded(
                  child: Text(
                    'All On-Device AI Capabilities Ready & Offline',
                    style: ArcaTypography.caption.copyWith(
                      color: ArcaColors.success,
                      fontWeight: .w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final percentage = (state.totalProgress * 100).round();

        return GestureDetector(
          onTap: onTap,
          behavior: .opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ArcaSpacing.md,
              vertical: ArcaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: ArcaColors.surfaceElevated,
              borderRadius: ArcaRadii.md,
              border: Border.all(color: ArcaColors.border),
            ),
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: .min,
                      children: [
                        const Text('⬇️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: ArcaSpacing.xs),
                        Text(
                          'Background AI Download ($percentage%)',
                          style: ArcaTypography.caption.copyWith(
                            fontWeight: .w600,
                            color: ArcaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const ArcaBadge(label: 'OFFLINE EDGE', variant: .info),
                  ],
                ),
                const SizedBox(height: ArcaSpacing.xs),
                ArcaProgressBar(
                  value: state.totalProgress,
                  height: 4.0,
                  semanticsLabel: 'Background AI model download progress',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
