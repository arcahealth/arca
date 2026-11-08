import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Top-level layout container for Arca screens.
///
/// Provides a consistent background surface, safe area insets handling,
/// and optional header pinning without dependencies on Material Scaffold.
class const ArcaScaffold({
  required final Widget body,
  super.key,
  final Widget? header,
  final Color backgroundColor = ArcaColors.background,
  final Widget? bottomBar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .stretch,
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
