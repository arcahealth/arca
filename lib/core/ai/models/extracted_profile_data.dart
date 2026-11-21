import 'package:arca/core/utils/utils.dart';

import 'extracted_entity.dart';

/// Structured health profile and clinical data extracted from document scans.
final class const ExtractedProfileData({
  final String firstName = '',
  final String middleName = '',
  final String lastName = '',
  final String dateOfBirth = '',
  final List<String> medications = const [],
  final List<String> allergies = const [],
  final String rawText = '',
  final List<ExtractedEntity> entities = const [],
  final double confidence = 0.0,
}) {
  /// Constant empty profile singleton when no clinical entities were detected.
  static const empty = ExtractedProfileData();

  /// Full combined name assembled from first, middle, and last names.
  String get name => [firstName, middleName, lastName].where((part) => part.isNotEmpty).join(' ');

  /// Returns true if no extracted clinical profile fields are present.
  bool get isEmpty =>
      firstName.isEmpty &&
      middleName.isEmpty &&
      lastName.isEmpty &&
      dateOfBirth.isEmpty &&
      medications.isEmpty &&
      allergies.isEmpty;

  /// Returns true if at least one extracted clinical field is present.
  bool get isNotEmpty => !isEmpty;

  /// Returns a copy of this [ExtractedProfileData] with updated fields.
  ExtractedProfileData copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? dateOfBirth,
    List<String>? medications,
    List<String>? allergies,
    String? rawText,
    List<ExtractedEntity>? entities,
    double? confidence,
  }) => ExtractedProfileData(
    firstName: firstName ?? this.firstName,
    middleName: middleName ?? this.middleName,
    lastName: lastName ?? this.lastName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    medications: medications ?? this.medications,
    allergies: allergies ?? this.allergies,
    rawText: rawText ?? this.rawText,
    entities: entities ?? this.entities,
    confidence: confidence ?? this.confidence,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedProfileData &&
          runtimeType == other.runtimeType &&
          firstName == other.firstName &&
          middleName == other.middleName &&
          lastName == other.lastName &&
          dateOfBirth == other.dateOfBirth &&
          CollectionEquality.stringList.equals(medications, other.medications) &&
          CollectionEquality.stringList.equals(allergies, other.allergies) &&
          rawText == other.rawText &&
          CollectionEquality.list.equals(entities, other.entities) &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(
    firstName,
    middleName,
    lastName,
    dateOfBirth,
    CollectionEquality.stringList.hash(medications),
    CollectionEquality.stringList.hash(allergies),
    rawText,
    CollectionEquality.list.hash(entities),
    confidence,
  );
}
