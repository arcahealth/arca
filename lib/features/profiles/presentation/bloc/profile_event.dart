import '../../domain/models/profile.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

final class ProfileActiveSwitched extends ProfileEvent {
  const ProfileActiveSwitched(this.profileId);
  final String profileId;
}

final class ProfileAdded extends ProfileEvent {
  const ProfileAdded(this.profile);
  final Profile profile;
}
