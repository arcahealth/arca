import '../../domain/models/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

/// In-memory repository implementation used for testing and offline scaffolding.
class InMemoryJournalRepository implements JournalRepository {
  InMemoryJournalRepository({List<JournalEntry>? initialEntries})
    : _entries = List.of(initialEntries ?? _defaultSeedEntries);

  final List<JournalEntry> _entries;

  static final List<JournalEntry> _defaultSeedEntries = [
    JournalEntry(
      id: 'entry-1',
      title: 'Resting Heart Rate & HRV Baseline',
      summary: 'Biometrics synced locally via health subsystem. Average 62 bpm, HRV 54 ms.',
      category: .vital,
      recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
      memberId: 'self',
    ),
    JournalEntry(
      id: 'entry-2',
      title: 'Annual Physical & Metabolic Panel',
      summary: 'Fasting glucose 92 mg/dL, HbA1c 5.3%. All markers within normal clinical range.',
      category: .lab,
      recordedAt: DateTime.now().subtract(const Duration(days: 2)),
      memberId: 'self',
    ),
  ];

  @override
  Future<List<JournalEntry>> getEntries({String? memberId}) async {
    if (memberId == null) return List.unmodifiable(_entries);
    return List.unmodifiable(_entries.where((e) => e.memberId == memberId));
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    final matches = _entries.where((e) => e.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> addEntry(JournalEntry entry) async {
    _entries.insert(0, entry);
  }
}
