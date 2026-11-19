/// Canonical asset keys for bundled on-device ONNX models and companion files.
abstract final class ArcaModelAssets {
  // PP-OCRv6 Text Detection & Recognition Models (Recommended Medium Suite)
  static const String ocrDict = 'assets/models/ocr/ppocrv6_dict.txt';
  static const String ocrDetMediumInt8 = 'assets/models/ocr/det_v6_medium.slim.int8.onnx';
  static const String ocrRecMediumInt8 = 'assets/models/ocr/rec_v6_medium.slim.int8.onnx';

  // MiniLM-L6 PII Detection & Tokenizer Assets (Recommended Mobile Default)
  static const String piiModelInt8 = 'assets/models/pii/minilm_l6_pii.slim.int8.onnx';
  static const String piiConfig = 'assets/models/pii/config.json';
  static const String piiTokenizer = 'assets/models/pii/tokenizer.json';
  static const String piiVocab = 'assets/models/pii/vocab.txt';
  static const String piiTokenizerConfig = 'assets/models/pii/tokenizer_config.json';
  static const String piiSpecialTokensMap = 'assets/models/pii/special_tokens_map.json';

  /// Bundled OCR model and dictionary asset paths.
  static const List<String> ocrAssets = [
    ocrDict,
    ocrDetMediumInt8,
    ocrRecMediumInt8,
  ];

  /// Bundled PII model, tokenizer, vocabulary, and config asset paths.
  static const List<String> piiAssets = [
    piiModelInt8,
    piiConfig,
    piiTokenizer,
    piiVocab,
    piiTokenizerConfig,
    piiSpecialTokensMap,
  ];

  /// Complete manifest of bundled on-device AI assets.
  static const List<String> allAssets = [
    ...ocrAssets,
    ...piiAssets,
  ];
}
