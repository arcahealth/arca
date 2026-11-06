import '../../domain/models/journal_entry.dart';

sealed class JournalEvent {
  const JournalEvent();
}

final class JournalLoadRequested extends JournalEvent {
  const JournalLoadRequested({this.memberId});
  final String? memberId;
}

final class JournalEntryAdded extends JournalEvent {
  const JournalEntryAdded(this.entry);
  final JournalEntry entry;
}
