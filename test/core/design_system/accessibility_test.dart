import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/design_system/arca_design_system.dart';

void main() {
  group('Accessibility Baseline Tests', () {
    testWidgets('ArcaButton enforces minimum 48x48 tap target and semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ArcaButton(
              label: 'Test Tap',
              semanticsLabel: 'Test tap action',
              onPressed: () {},
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ArcaButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
        reason: 'Touch target height must meet minimum 48 dp accessibility guideline',
      );
      expect(
        size.width,
        greaterThanOrEqualTo(48.0),
        reason: 'Touch target width must meet minimum 48 dp accessibility guideline',
      );

      // Verify semantics
      expect(
        tester.getSemantics(buttonFinder),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Test tap action',
          hasTapAction: true,
        ),
      );
    });
  });
}
