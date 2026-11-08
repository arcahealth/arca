import 'package:collection/collection.dart';

import '../../domain/models/journal_entry.dart';

sealed class const JournalState();

final class const JournalInitial() extends JournalState;

final class const JournalLoading() extends JournalState;

final class const JournalLoaded({required final List<JournalEntry> entries})
    extends JournalState {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalLoaded &&
          runtimeType == other.runtimeType &&
          const ListEquality<JournalEntry>().equals(entries, other.entries);

  @override
  int get hashCode => const ListEquality<JournalEntry>().hash(entries);
}

final class const JournalFailure(final String message) extends JournalState {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
