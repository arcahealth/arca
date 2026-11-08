enum JournalCategory { vital, visit, lab, medication }

/// A clinical journal entry or biometric milestone in Arca's longitudinal vault.
final class const JournalEntry({
  required final String id,
  required final String title,
  required final String summary,
  required final JournalCategory category,
  required final DateTime recordedAt,
  required final String memberId,
  final bool isVerifiedOnDevice = true,
}) {
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
