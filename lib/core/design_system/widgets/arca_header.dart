import 'package:flutter/widgets.dart';
import '../tokens/tokens.dart';

/// Clean, accessible header bar for Arca screens.
class ArcaHeader extends StatelessWidget {
  const ArcaHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcaSpacing.md,
        vertical: ArcaSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: ArcaColors.background,
        border: Border(
          bottom: BorderSide(
            color: ArcaColors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: ArcaSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ArcaTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: ArcaSpacing.xxs),
                  Text(
                    subtitle!,
                    style: ArcaTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: ArcaSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
