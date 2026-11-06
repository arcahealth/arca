import 'package:sqlite_async/sqlite_async.dart';

/// Database schema migrations for Arca's on-device SQLite database.
class ArcaDatabaseMigrations {
  static SqliteMigrations get migrations {
    final migrations = SqliteMigrations();

    migrations.add(
      SqliteMigration(1, (tx) async {
        // Table: Family Member Profiles
        await tx.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            relationship TEXT NOT NULL,
            date_of_birth TEXT,
            blood_type TEXT,
            allergies TEXT,
            created_at INTEGER NOT NULL
          );
        ''');

        // Table: Clinical Journal Entries & Biometric Logs
        await tx.execute('''
          CREATE TABLE journal_entries (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT NOT NULL,
            category TEXT NOT NULL,
            recorded_at INTEGER NOT NULL,
            member_id TEXT NOT NULL,
            is_verified_on_device INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(member_id) REFERENCES profiles(id) ON DELETE CASCADE
          );
        ''');

        // Performance Indexes for Longitudinal Timeline Queries
        await tx.execute('''
          CREATE INDEX idx_journal_member_recorded 
          ON journal_entries(member_id, recorded_at DESC);
        ''');

        await tx.execute('''
          CREATE INDEX idx_journal_recorded 
          ON journal_entries(recorded_at DESC);
        ''');

        // Seed default 'Self' profile
        await tx.execute('''
          INSERT INTO profiles (id, name, relationship, created_at)
          VALUES ('self', 'Me (Primary)', 'self', ?);
        ''', [DateTime.now().millisecondsSinceEpoch]);
      }),
    );

    return migrations;
  }
}
