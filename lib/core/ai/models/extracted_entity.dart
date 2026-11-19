/// Extracted entity identified by on-device PII/NER and clinical extraction models.
final class const ExtractedEntity({
  required final String label,
  required final String value,
  final double confidence = 1.0,
  final int startIndex = 0,
  final int endIndex = 0,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedEntity &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value &&
          confidence == other.confidence &&
          startIndex == other.startIndex &&
          endIndex == other.endIndex;

  @override
  int get hashCode => Object.hash(label, value, confidence, startIndex, endIndex);
}
