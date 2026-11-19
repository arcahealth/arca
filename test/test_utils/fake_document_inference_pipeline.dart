import 'package:arca/core/ai/ai.dart';

/// Test fake for [DocumentInferencePipeline].
final class FakeDocumentInferencePipeline implements DocumentInferencePipeline {
  FakeDocumentInferencePipeline({
    this.result = const DocumentInferenceResult.success(
      ExtractedProfileData(
        patientName: 'Alex Morgan',
        dateOfBirth: '1988-04-12',
        medications: ['Amoxicillin 500mg'],
        allergies: ['Penicillin'],
        confidence: 0.95,
      ),
    ),
    this.delay,
  });

  DocumentInferenceResult result;
  Duration? delay;
  int processCalls = 0;
  List<String> lastProcessedFiles = const [];

  @override
  Future<DocumentInferenceResult> processDocuments(
    List<String> filePaths,
  ) async {
    processCalls++;
    lastProcessedFiles = List.unmodifiable(filePaths);

    if (delay != null) {
      await Future<void>.delayed(delay!);
    }

    return result;
  }
}
