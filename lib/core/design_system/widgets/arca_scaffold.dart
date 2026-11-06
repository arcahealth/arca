import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Top-level layout container for Arca screens.
///
/// Provides a consistent background surface, safe area insets handling,
/// and optional header pinning without dependencies on Material Scaffold.
class ArcaScaffold extends StatelessWidget {
  const ArcaScaffold({
    required this.body,
    super.key,
    this.header,
    this.backgroundColor = ArcaColors.background,
    this.bottomBar,
  });

  final Widget body;
  final Widget? header;
  final Widget? bottomBar;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Expanded(child: body),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}
