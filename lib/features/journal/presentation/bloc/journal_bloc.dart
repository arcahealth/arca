import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/journal_repository.dart';
import 'journal_event.dart';
import 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc({required this.repository}) : super(const JournalInitial()) {
    on<JournalLoadRequested>(_onLoadRequested);
    on<JournalEntryAdded>(_onEntryAdded);
  }

  final JournalRepository repository;

  Future<void> _onLoadRequested(
    JournalLoadRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());
    try {
      final entries = await repository.getEntries(memberId: event.memberId);
      emit(JournalLoaded(entries: entries));
    } catch (e) {
      emit(JournalFailure('Failed to load clinical records: $e'));
    }
  }

  Future<void> _onEntryAdded(
    JournalEntryAdded event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await repository.addEntry(event.entry);
      final entries = await repository.getEntries();
      emit(JournalLoaded(entries: entries));
    } catch (e) {
      emit(JournalFailure('Failed to persist clinical record: $e'));
    }
  }
}
