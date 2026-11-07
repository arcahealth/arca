enum VaultRelationship { self, child, parent, partner, other }

/// A personal or family medical vault in Arca's on-device private archive.
final class Vault {
  const Vault({
    required this.id,
    required this.name,
    required this.relationship,
    required this.createdAt,
    this.dateOfBirth,
    this.bloodType,
    this.allergies,
  });

  final String id;
  final String name;
  final VaultRelationship relationship;
  final DateTime createdAt;
  final String? dateOfBirth;
  final String? bloodType;
  final String? allergies;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vault &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          relationship == other.relationship &&
          dateOfBirth == other.dateOfBirth &&
          bloodType == other.bloodType &&
          allergies == other.allergies &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relationship,
    dateOfBirth,
    bloodType,
    allergies,
    createdAt,
  );
}

/// Backward compatibility alias during architecture transition.
typedef Profile = Vault;
typedef ProfileRelationship = VaultRelationship;
