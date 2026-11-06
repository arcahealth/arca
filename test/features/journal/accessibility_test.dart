import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/app/app.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';

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

    testWidgets(
      'JournalScreen adapts to 2.0x text scaling without clipping or overflow',
      (tester) async {
        final fakeRepo = InMemoryJournalRepository(
          initialEntries: [
            JournalEntry(
              id: 'a11y-test-1',
              title: 'Diagnostic Lab Summary with Extensive Clinical Notes',
              summary: 'Hemoglobin A1c is within target threshold at 5.4%. Next panel scheduled in 6 months.',
              category: JournalCategory.lab,
              recordedAt: DateTime(2026, 11, 7),
              memberId: 'self',
            ),
          ],
        );

        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;

        await tester.pumpWidget(ArcaApp(journalRepository: fakeRepo));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Arca Journal'), findsOneWidget);

        // Reset test view
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      },
    );
  });
}
