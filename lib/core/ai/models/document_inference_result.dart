import 'extracted_profile_data.dart';

/// Sealed outcome returned by the on-device document AI inference pipeline.
sealed class const DocumentInferenceResult() {
  const factory success(ExtractedProfileData data) = DocumentInferenceSuccess;

  const factory failure(String message, [Object? error]) = DocumentInferenceFailure;
}

/// Inference succeeded and yielded structured profile data.
final class const DocumentInferenceSuccess(final ExtractedProfileData data) extends DocumentInferenceResult;

/// Inference failed due to an unrecoverable model or file reading error.
final class const DocumentInferenceFailure(
  final String message, [
  final Object? error,
]) extends DocumentInferenceResult;
