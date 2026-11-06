enum JournalCategory { vital, visit, lab, medication }

/// A clinical journal entry or biometric milestone in Arca's longitudinal vault.
final class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.recordedAt,
    required this.memberId,
    this.isVerifiedOnDevice = true,
  });

  final String id;
  final String title;
  final String summary;
  final JournalCategory category;
  final DateTime recordedAt;
  final String memberId;
  final bool isVerifiedOnDevice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          summary == other.summary &&
          category == other.category &&
          recordedAt == other.recordedAt &&
          memberId == other.memberId &&
          isVerifiedOnDevice == other.isVerifiedOnDevice;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    summary,
    category,
    recordedAt,
    memberId,
    isVerifiedOnDevice,
  );
}
