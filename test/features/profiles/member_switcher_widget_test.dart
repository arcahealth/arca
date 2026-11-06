import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/app/app.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';
import 'package:arca/features/profiles/data/repositories/in_memory_profile_repository.dart';
import 'package:arca/features/profiles/domain/models/profile.dart';
import 'package:arca/features/profiles/presentation/widgets/member_switcher_bar.dart';

void main() {
  group('MemberSwitcherBar Widget Tests', () {
    final self = Profile(
      id: 'self',
      name: 'Me (Primary)',
      relationship: ProfileRelationship.self,
      createdAt: DateTime(2026, 1, 1),
    );

    final child = Profile(
      id: 'child_1',
      name: 'Leo',
      relationship: ProfileRelationship.child,
      createdAt: DateTime(2026, 2, 1),
    );

    testWidgets('renders all member pills and handles selection', (
      tester,
    ) async {
      String? selectedId;
      var addCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MemberSwitcherBar(
            profiles: [self, child],
            activeProfile: self,
            onProfileSelected: (id) => selectedId = id,
            onAddProfile: () => addCalled = true,
          ),
        ),
      );

      expect(find.text('Me (Primary)'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('+ Add Member'), findsOneWidget);

      await tester.tap(find.text('Leo'));
      expect(selectedId, 'child_1');

      await tester.tap(find.text('+ Add Member'));
      expect(addCalled, isTrue);
    });

    testWidgets('ArcaApp switches family member and updates timeline filter', (
      tester,
    ) async {
      final fakeProfileRepo = InMemoryProfileRepository(
        initialProfiles: [self, child],
        initialActiveId: 'self',
      );

      final fakeJournalRepo = InMemoryJournalRepository(
        initialEntries: [
          JournalEntry(
            id: 'self-vitals',
            title: 'Self Resting Vitals',
            summary: '60 bpm resting pulse.',
            category: JournalCategory.vital,
            recordedAt: DateTime(2026, 11, 7),
            memberId: 'self',
          ),
          JournalEntry(
            id: 'child-vitals',
            title: 'Leo Pediatric Growth Check',
            summary: 'Height 105 cm, weight 18 kg.',
            category: JournalCategory.vital,
            recordedAt: DateTime(2026, 11, 7),
            memberId: 'child_1',
          ),
        ],
      );

      await tester.pumpWidget(
        ArcaApp(
          profileRepository: fakeProfileRepo,
          journalRepository: fakeJournalRepo,
        ),
      );
      await tester.pumpAndSettle();

      // By default, Self is active
      expect(find.text('Self Resting Vitals'), findsOneWidget);

      // Tap on Leo to switch family member vault
      await tester.tap(find.text('Leo'));
      await tester.pumpAndSettle();

      // Timeline now displays Leo's clinical records
      expect(find.text('Leo Pediatric Growth Check'), findsOneWidget);
      expect(find.text('Leo • Longitudinal Family Vault'), findsOneWidget);
    });
  });
}
