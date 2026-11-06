import '../../domain/models/profile.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.profiles, required this.activeProfile});

  final List<Profile> profiles;
  final Profile activeProfile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileLoaded &&
          runtimeType == other.runtimeType &&
          activeProfile == other.activeProfile &&
          _listEquals(profiles, other.profiles);

  @override
  int get hashCode => Object.hash(activeProfile, Object.hashAll(profiles));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
