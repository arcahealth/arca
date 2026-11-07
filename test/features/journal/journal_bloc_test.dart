import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/features/journal/data/repositories/in_memory_journal_repository.dart';
import 'package:arca/features/journal/domain/models/journal_entry.dart';
import 'package:arca/features/journal/domain/repositories/journal_repository.dart';
import 'package:arca/features/journal/presentation/bloc/journal_bloc.dart';
import 'package:arca/features/journal/presentation/bloc/journal_event.dart';
import 'package:arca/features/journal/presentation/bloc/journal_state.dart';

void main() {
  group('JournalBloc', () {
    late JournalRepository repository;
    final testEntry = JournalEntry(
      id: 'test-1',
      title: 'Lab Blood Panel',
      summary: 'Lipid panel results within normal ranges.',
      category: JournalCategory.lab,
      recordedAt: DateTime(2026, 11, 7),
      memberId: 'self',
    );

    setUp(() {
      repository = InMemoryJournalRepository(initialEntries: [testEntry]);
    });

    test('initial state is JournalInitial', () {
      final bloc = JournalBloc(repository: repository);
      expect(bloc.state, isA<JournalInitial>());
      bloc.close();
    });

    blocTest<JournalBloc, JournalState>(
      'emits [JournalLoading, JournalLoaded] when JournalLoadRequested is added',
      build: () => JournalBloc(repository: repository),
      act: (bloc) => bloc.add(const JournalLoadRequested()),
      expect: () => [
        isA<JournalLoading>(),
        isA<JournalLoaded>().having(
          (s) => s.entries.length,
          'entries.length',
          1,
        ),
      ],
    );

    blocTest<JournalBloc, JournalState>(
      'emits updated JournalLoaded when JournalEntryAdded is added',
      build: () => JournalBloc(repository: repository),
      act: (bloc) {
        final newEntry = JournalEntry(
          id: 'test-2',
          title: 'Heart Rate Log',
          summary: 'Resting pulse 65 bpm.',
          category: JournalCategory.vital,
          recordedAt: DateTime(2026, 11, 7, 10),
          memberId: 'self',
        );
        bloc.add(JournalEntryAdded(newEntry));
      },
      expect: () => [
        isA<JournalLoaded>().having(
          (s) => s.entries.length,
          'entries.length',
          2,
        ),
      ],
    );
  });
}
