import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// In-memory profile repository for testing and offline development.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({
    List<Profile>? initialProfiles,
    String initialActiveId = 'self',
  }) : _profiles = List.of(initialProfiles ?? _defaultProfiles),
       _activeProfileId = initialActiveId;

  final List<Profile> _profiles;
  String _activeProfileId;

  static final List<Profile> _defaultProfiles = [
    Profile(
      id: 'self',
      name: 'Me (Primary)',
      relationship: ProfileRelationship.self,
      createdAt: DateTime(2026, 1, 1),
    ),
    Profile(
      id: 'child_1',
      name: 'Leo',
      relationship: ProfileRelationship.child,
      createdAt: DateTime(2026, 2, 1),
    ),
    Profile(
      id: 'parent_1',
      name: 'Eleanor',
      relationship: ProfileRelationship.parent,
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  @override
  Future<List<Profile>> getProfiles() async => List.unmodifiable(_profiles);

  @override
  Future<Profile?> getProfileById(String id) async {
    final matches = _profiles.where((p) => p.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> addProfile(Profile profile) async {
    _profiles.add(profile);
  }

  @override
  Future<String> getActiveProfileId() async => _activeProfileId;

  @override
  Future<void> setActiveProfileId(String id) async {
    _activeProfileId = id;
  }
}
