/// Extracted entity identified by on-device PII/NER and clinical extraction models.
final class const ExtractedEntity({
  required final String label,
  required final String value,
  final double confidence = 1.0,
  final int startIndex = 0,
  final int endIndex = 0,
});
