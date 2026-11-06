enum ProfileRelationship { self, child, parent, partner, other }

/// A family member profile in Arca's multi-member private archive.
final class Profile {
  const Profile({
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
  final ProfileRelationship relationship;
  final DateTime createdAt;
  final String? dateOfBirth;
  final String? bloodType;
  final String? allergies;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
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
