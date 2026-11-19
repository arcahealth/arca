import 'extracted_entity.dart';

/// Structured health profile and clinical data extracted from document scans.
final class const ExtractedProfileData({
  final String patientName = '',
  final String dateOfBirth = '',
  final List<String> medications = const [],
  final List<String> allergies = const [],
  final String rawText = '',
  final List<ExtractedEntity> entities = const [],
  final double confidence = 0.0,
}) {
  /// Empty profile default when no clinical entities were detected.
  const factory ExtractedProfileData.empty() = ExtractedProfileData;

  /// Returns true if all extracted fields are empty.
  bool get isEmpty => patientName.isEmpty && dateOfBirth.isEmpty && medications.isEmpty && allergies.isEmpty;

  /// Returns true if at least one extracted clinical field is present.
  bool get isNotEmpty => !isEmpty;
}
