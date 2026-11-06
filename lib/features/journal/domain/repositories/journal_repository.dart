import '../models/journal_entry.dart';

/// Repository interface managing longitudinal medical records and journal entries.
abstract interface class JournalRepository {
  /// Fetches all journal entries for the active member profile.
  Future<List<JournalEntry>> getEntries({String? memberId});

  /// Fetches a specific entry by its unique identifier.
  Future<JournalEntry?> getEntryById(String id);

  /// Saves a new journal entry to local on-device persistence.
  Future<void> addEntry(JournalEntry entry);
}
