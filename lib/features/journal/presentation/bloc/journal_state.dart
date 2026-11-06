import '../../domain/models/journal_entry.dart';

sealed class JournalState {
  const JournalState();
}

final class JournalInitial extends JournalState {
  const JournalInitial();
}

final class JournalLoading extends JournalState {
  const JournalLoading();
}

final class JournalLoaded extends JournalState {
  const JournalLoaded({required this.entries});
  final List<JournalEntry> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalLoaded &&
          runtimeType == other.runtimeType &&
          _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hashAll(entries);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final class JournalFailure extends JournalState {
  const JournalFailure(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
