import 'package:sqlite_async/sqlite_async.dart';

import '../../domain/models/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

/// On-device SQLite implementation of [JournalRepository] backed by [SqliteDatabase].
class const SqliteJournalRepository({required final SqliteDatabase db})
    implements JournalRepository {
  @override
  Future<List<JournalEntry>> getEntries({String? memberId}) async {
    final results = memberId != null
        ? await db.getAll(
            '''
        SELECT id, title, summary, category, recorded_at, member_id, is_verified_on_device
        FROM journal_entries
        WHERE member_id = ?
        ORDER BY recorded_at DESC
        ''',
            [memberId],
          )
        : await db.getAll('''
        SELECT id, title, summary, category, recorded_at, member_id, is_verified_on_device
        FROM journal_entries
        ORDER BY recorded_at DESC
        ''');

    return results.map(_rowToEntry).toList(growable: false);
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    final row = await db.getOptional(
      '''
      SELECT id, title, summary, category, recorded_at, member_id, is_verified_on_device
      FROM journal_entries
      WHERE id = ?
      ''',
      [id],
    );

    if (row == null) return null;
    return _rowToEntry(row);
  }

  @override
  Future<void> addEntry(JournalEntry entry) async {
    await db.execute(
      '''
      INSERT OR REPLACE INTO journal_entries (
        id, title, summary, category, recorded_at, member_id, is_verified_on_device
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        entry.id,
        entry.title,
        entry.summary,
        entry.category.name,
        entry.recordedAt.millisecondsSinceEpoch,
        entry.memberId,
        entry.isVerifiedOnDevice ? 1 : 0,
      ],
    );
  }

  static JournalEntry _rowToEntry(Map<String, dynamic> row) {
    final categoryName = row['category'] as String;
    final category = JournalCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => .vital,
    );

    return JournalEntry(
      id: row['id'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String,
      category: category,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        row['recorded_at'] as int,
      ),
      memberId: row['member_id'] as String,
      isVerifiedOnDevice: (row['is_verified_on_device'] as int) == 1,
    );
  }
}
