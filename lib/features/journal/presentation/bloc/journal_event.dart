import '../../domain/models/journal_entry.dart';

sealed class const JournalEvent();

final class const JournalLoadRequested({final String? memberId})
    extends JournalEvent;

final class const JournalEntryAdded(final JournalEntry entry)
    extends JournalEvent;
