import 'package:arca/core/ai/ai.dart';

/// Test fake for [OcrEngine].
final class FakeOcrEngine implements OcrEngine {
  FakeOcrEngine({this.text = 'Patient: Alex Morgan\nDOB: 1988-04-12'});

  String text;
  int recognizeCalls = 0;
  List<String> lastFilePaths = const [];

  @override
  Future<String> recognizeText(String filePath) async {
    recognizeCalls++;
    lastFilePaths = [filePath];
    return text;
  }

  @override
  Future<String> recognizeAll(List<String> filePaths) async {
    recognizeCalls++;
    lastFilePaths = List.unmodifiable(filePaths);
    return text;
  }
}

/// Test fake for [PiiExtractor].
final class FakePiiExtractor implements PiiExtractor {
  FakePiiExtractor({this.entities = const []});

  List<ExtractedEntity> entities;
  int extractCalls = 0;
  String? lastExtractedText;

  @override
  Future<List<ExtractedEntity>> extractEntities(String text) async {
    extractCalls++;
    lastExtractedText = text;
    return entities;
  }
}
