import 'package:flutter_test/flutter_test.dart';
import 'package:arca/app/app.dart';
import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';

void main() {
  group('JournalScreen Widget Tests', () {
    late InMemoryJournalRepository fakeRepository;
    final testEntry = JournalEntry(
      id: 'entry-test-1',
      title: 'Resting Heart Rate & HRV Baseline',
      summary: 'Biometrics synced locally via health subsystem.',
      category: JournalCategory.vital,
      recordedAt: DateTime(2026, 11, 7),
      memberId: 'self',
    );

    setUp(() {
      fakeRepository = InMemoryJournalRepository(initialEntries: [testEntry]);
    });

    testWidgets('renders header, badges, and clinical journal entry', (
      tester,
    ) async {
      await tester.pumpWidget(ArcaApp(journalRepository: fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Arca Journal'), findsOneWidget);
      expect(find.text('On-Device Family Medical Vault'), findsOneWidget);
      expect(find.text('Resting Heart Rate & HRV Baseline'), findsOneWidget);
      expect(find.text('VITAL'), findsOneWidget);
    });

    testWidgets('tapping an entry navigates to RecordDetailScreen and back', (
      tester,
    ) async {
      await tester.pumpWidget(ArcaApp(journalRepository: fakeRepository));
      await tester.pumpAndSettle();

      // Tap on the card
      final cardFinder = find.byType(ArcaCard);
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify we arrived at the detail screen
      expect(find.text('Clinical Record Detail'), findsOneWidget);
      expect(find.text('Clinical Findings & Summary'), findsOneWidget);
      expect(find.text('VERIFIED ON-DEVICE'), findsOneWidget);

      // Tap the back button
      final backButton = find.text('← Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we returned to the journal timeline
      expect(find.text('Arca Journal'), findsOneWidget);
    });
  });
}
