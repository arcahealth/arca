import '../models/profile.dart';

/// Repository interface managing family member profiles and the active profile state.
abstract interface class ProfileRepository {
  /// Fetches all registered family member profiles.
  Future<List<Profile>> getProfiles();

  /// Fetches a specific profile by unique identifier.
  Future<Profile?> getProfileById(String id);

  /// Adds a new family member to the on-device vault.
  Future<void> addProfile(Profile profile);

  /// Returns the identifier of the currently active profile.
  Future<String> getActiveProfileId();

  /// Sets the active family member profile.
  Future<void> setActiveProfileId(String id);
}
