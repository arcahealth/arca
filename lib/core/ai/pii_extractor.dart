import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'bert_tokenizer.dart';
import 'model_assets.dart';
import 'models/models.dart';

/// Abstract interface for extracting PII and clinical entities from recognized document text.
abstract interface class PiiExtractor {
  /// Analyzes [text] and returns all detected PII and clinical entities.
  Future<List<ExtractedEntity>> extractEntities(String text);
}

/// Default production implementation of [PiiExtractor] combining MiniLM-L6 ONNX
/// token classification with high-precision clinical entity parsing.
final class DefaultPiiExtractor implements PiiExtractor {
  DefaultPiiExtractor({
    OnnxRuntime? onnxRuntime,
    BertTokenizer? tokenizer,
  }) : _onnxRuntime = onnxRuntime ?? OnnxRuntime(),
       _customTokenizer = tokenizer;

  final OnnxRuntime _onnxRuntime;
  final BertTokenizer? _customTokenizer;
  BertTokenizer? _loadedTokenizer;
  OrtSession? _piiSession;
  Map<String, String>? _id2label;
  bool _initialized = false;

  BertTokenizer? get _tokenizer => _customTokenizer ?? _loadedTokenizer;

  /// Initializes tokenizer, config, and ONNX session.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      if (_customTokenizer == null) {
        _loadedTokenizer = await BertTokenizer.fromAsset(ArcaModelAssets.piiVocab);
      }

      // Load id2label mapping from config.json
      final configJson = await rootBundle.loadString(ArcaModelAssets.piiConfig);
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      final rawId2Label = config['id2label'] as Map<String, dynamic>?;
      if (rawId2Label != null) {
        _id2label = rawId2Label.map((k, v) => MapEntry(k, v.toString()));
      }

      _piiSession = await _onnxRuntime.createSessionFromAsset(
        ArcaModelAssets.piiModelInt8,
      );
      _initialized = true;
    } catch (_) {
      // In headless test environments or platforms where native ONNX runtime
      // binaries are unavailable, gracefully proceed with clinical heuristics.
      _initialized = true;
    }
  }

  @override
  Future<List<ExtractedEntity>> extractEntities(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return const [];

    await _ensureInitialized();

    final entities = <ExtractedEntity>[];

    // 1. Run ONNX BERT Token Classification if session is available
    if (_piiSession != null && _tokenizer != null && _id2label != null) {
      try {
        final onnxEntities = await _runOnnxInference(cleanText);
        entities.addAll(onnxEntities);
      } catch (_) {
        // Fallback to rules if inference fails
      }
    }

    // 2. Run clinical heuristic & regex extraction
    final clinicalEntities = _extractClinicalEntities(cleanText);
    for (final clinical in clinicalEntities) {
      // Avoid duplicate entities if already detected with high confidence
      final alreadyExists = entities.any(
        (e) => e.label == clinical.label && e.value.toLowerCase() == clinical.value.toLowerCase(),
      );
      if (!alreadyExists) {
        entities.add(clinical);
      }
    }

    return entities;
  }

  /// Runs MiniLM-L6 token classification inference on [text].
  Future<List<ExtractedEntity>> _runOnnxInference(String text) async {
    if (_piiSession == null || _tokenizer == null || _id2label == null) {
      return const [];
    }

    final encoding = _tokenizer!.encode(text);
    if (encoding.inputIds.isEmpty) return const [];

    final seqLen = encoding.inputIds.length;
    final inputIdsTensor = await OrtValue.fromList(encoding.inputIds, [
      1,
      seqLen,
    ]);
    final attentionMaskTensor = await OrtValue.fromList(encoding.attentionMask, [
      1,
      seqLen,
    ]);
    final tokenTypeIdsTensor = await OrtValue.fromList(encoding.tokenTypeIds, [
      1,
      seqLen,
    ]);

    final inputs = {
      'input_ids': inputIdsTensor,
      'attention_mask': attentionMaskTensor,
      'token_type_ids': tokenTypeIdsTensor,
    };

    final outputs = await _piiSession!.run(inputs);
    final logitsTensor = outputs['logits'];
    if (logitsTensor == null) return const [];

    final logitsList = await logitsTensor.asList();
    final entities = <ExtractedEntity>[];

    if (logitsList.isNotEmpty && logitsList.first is List) {
      final tokenLogits = logitsList.first as List;

      String? currentLabel;
      final currentSpanTokens = <int>[];
      var startChar = 0;
      var endChar = 0;

      for (var i = 0; i < tokenLogits.length && i < encoding.spans.length; i++) {
        final classScores = List<num>.from(tokenLogits[i] as List);
        var maxIdx = 0;
        var maxScore = classScores.first;
        for (var j = 1; j < classScores.length; j++) {
          if (classScores[j] > maxScore) {
            maxScore = classScores[j];
            maxIdx = j;
          }
        }

        final rawLabel = _id2label![maxIdx.toString()] ?? 'O';
        final span = encoding.spans[i];

        if (rawLabel.startsWith('B-')) {
          if (currentLabel != null && currentSpanTokens.isNotEmpty) {
            final val = text.substring(startChar, endChar).trim();
            if (val.isNotEmpty) {
              entities.add(
                ExtractedEntity(
                  label: currentLabel,
                  value: val,
                  confidence: 0.90,
                  startIndex: startChar,
                  endIndex: endChar,
                ),
              );
            }
          }
          currentLabel = rawLabel.substring(2);
          currentSpanTokens
            ..clear()
            ..add(i);
          startChar = span.$1;
          endChar = span.$2;
        } else if (rawLabel.startsWith('I-') && currentLabel == rawLabel.substring(2)) {
          currentSpanTokens.add(i);
          endChar = span.$2;
        } else {
          if (currentLabel != null && currentSpanTokens.isNotEmpty) {
            final val = text.substring(startChar, endChar).trim();
            if (val.isNotEmpty) {
              entities.add(
                ExtractedEntity(
                  label: currentLabel,
                  value: val,
                  confidence: 0.90,
                  startIndex: startChar,
                  endIndex: endChar,
                ),
              );
            }
            currentLabel = null;
            currentSpanTokens.clear();
          }
        }
      }
    }

    return entities;
  }

  /// Extracts clinical entities (name, date of birth, medications, allergies) using rules and patterns.
  List<ExtractedEntity> _extractClinicalEntities(String text) {
    final entities = <ExtractedEntity>[];

    // 1. Name and decomposed name components
    final nameRegexes = [
      RegExp(
        r'(?:Patient\s+Name|Patient|Full\s+Name|Name)\s*[:=\-]\s*([A-Za-z\s\.\-]+?)(?=\s*(?:\n|\r|DOB|Date|Age|Sex|Gender|Rx|Allerg|$))',
        caseSensitive: false,
      ),
    ];
    for (final regex in nameRegexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        if (name.isNotEmpty && !name.contains(':') && name.split(' ').length <= 4) {
          entities.add(
            ExtractedEntity(
              label: 'name',
              value: name,
              confidence: 0.95,
              startIndex: match.start,
              endIndex: match.end,
            ),
          );

          // Decompose into first, middle, and last name entities when possible
          final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
          if (parts.length == 1) {
            entities.add(ExtractedEntity(label: 'first_name', value: parts[0], confidence: 0.95));
          } else if (parts.length == 2) {
            entities.add(ExtractedEntity(label: 'first_name', value: parts[0], confidence: 0.95));
            entities.add(ExtractedEntity(label: 'last_name', value: parts[1], confidence: 0.95));
          } else if (parts.length == 3) {
            entities.add(ExtractedEntity(label: 'first_name', value: parts[0], confidence: 0.95));
            entities.add(ExtractedEntity(label: 'middle_name', value: parts[1], confidence: 0.95));
            entities.add(ExtractedEntity(label: 'last_name', value: parts[2], confidence: 0.95));
          } else if (parts.length > 3) {
            entities.add(ExtractedEntity(label: 'first_name', value: parts[0], confidence: 0.95));
            entities.add(
              ExtractedEntity(
                label: 'middle_name',
                value: parts.sublist(1, parts.length - 1).join(' '),
                confidence: 0.95,
              ),
            );
            entities.add(ExtractedEntity(label: 'last_name', value: parts.last, confidence: 0.95));
          }
          break;
        }
      }
    }

    // Check for explicit first, middle, and last name fields
    final firstNameMatch = RegExp(
      r'(?:First\s+Name)\s*[:=\-]\s*([A-Za-z\-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (firstNameMatch != null) {
      final val = firstNameMatch.group(1)?.trim() ?? '';
      if (val.isNotEmpty && !entities.any((e) => e.label == 'first_name')) {
        entities.add(ExtractedEntity(label: 'first_name', value: val, confidence: 0.95));
      }
    }

    final middleNameMatch = RegExp(
      r'(?:Middle\s+Name)\s*[:=\-]\s*([A-Za-z\-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (middleNameMatch != null) {
      final val = middleNameMatch.group(1)?.trim() ?? '';
      if (val.isNotEmpty && !entities.any((e) => e.label == 'middle_name')) {
        entities.add(ExtractedEntity(label: 'middle_name', value: val, confidence: 0.95));
      }
    }

    final lastNameMatch = RegExp(
      r'(?:Last\s+Name|Surname)\s*[:=\-]\s*([A-Za-z\-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (lastNameMatch != null) {
      final val = lastNameMatch.group(1)?.trim() ?? '';
      if (val.isNotEmpty && !entities.any((e) => e.label == 'last_name')) {
        entities.add(ExtractedEntity(label: 'last_name', value: val, confidence: 0.95));
      }
    }

    // 2. Date of Birth
    final dobRegexes = [
      RegExp(
        r'(?:DOB|Date\s+of\s+Birth|Birth\s*Date)\s*[:=\-]\s*([0-9\/\-\.A-Za-z]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:Born|DOB)\s*[:=\-]?\s*(\d{4}[-/]\d{2}[-/]\d{2}|\d{2}[-/]\d{2}[-/]\d{4})\b',
        caseSensitive: false,
      ),
    ];
    for (final regex in dobRegexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final dob = match.group(1)?.trim() ?? '';
        if (dob.isNotEmpty) {
          entities.add(
            ExtractedEntity(
              label: 'date_of_birth',
              value: _normalizeDob(dob),
              confidence: 0.95,
              startIndex: match.start,
              endIndex: match.end,
            ),
          );
          break;
        }
      }
    }

    // 3. Medications (explicit Rx and dosage patterns)
    final medExplicitRegex = RegExp(
      r'(?:Rx|Prescriptions?|Medications?)\s*[:=\-]\s*([^\n\r]+)',
      caseSensitive: false,
    );
    final medMatches = medExplicitRegex.allMatches(text);
    for (final match in medMatches) {
      final medLine = match.group(1)?.trim() ?? '';
      if (medLine.isNotEmpty) {
        // May contain comma-separated meds
        final parts = medLine.split(RegExp(r'[,;]'));
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            entities.add(
              ExtractedEntity(
                label: 'medication',
                value: trimmed,
                confidence: 0.90,
                startIndex: match.start,
                endIndex: match.end,
              ),
            );
          }
        }
      }
    }

    // Dosage pattern: [Drug] [Number][mg|mcg|ml|g]
    final dosageRegex = RegExp(
      r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(\d+(?:\.\d+)?\s*(?:mg|mcg|ml|g|tablets?|capsules?))\b',
    );
    final dosageMatches = dosageRegex.allMatches(text);
    for (final match in dosageMatches) {
      final med = match.group(0)?.trim() ?? '';
      final alreadyAdded = entities.any(
        (e) => e.label == 'medication' && e.value.contains(med),
      );
      if (med.isNotEmpty && !alreadyAdded) {
        entities.add(
          ExtractedEntity(
            label: 'medication',
            value: med,
            confidence: 0.88,
            startIndex: match.start,
            endIndex: match.end,
          ),
        );
      }
    }

    // 4. Allergies
    final allergyRegex = RegExp(
      r'(?:Allerg(?:ies|y)|Allergic\s+to)\s*[:=\-]\s*([^\n\r]+)',
      caseSensitive: false,
    );
    final allergyMatches = allergyRegex.allMatches(text);
    for (final match in allergyMatches) {
      final allergyLine = match.group(1)?.trim() ?? '';
      if (allergyLine.isNotEmpty) {
        final parts = allergyLine.split(RegExp(r'[,;]'));
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            entities.add(
              ExtractedEntity(
                label: 'allergy',
                value: trimmed,
                confidence: 0.92,
                startIndex: match.start,
                endIndex: match.end,
              ),
            );
          }
        }
      }
    }

    // Check for common allergen keywords if no explicit header
    if (!entities.any((e) => e.label == 'allergy')) {
      const commonAllergens = [
        'Penicillin',
        'Sulfa',
        'Aspirin',
        'Latex',
        'Peanuts',
        'Codeine',
        'Shellfish',
      ];
      for (final allergen in commonAllergens) {
        if (RegExp('\\b$allergen\\b', caseSensitive: false).hasMatch(text)) {
          entities.add(
            ExtractedEntity(
              label: 'allergy',
              value: allergen,
              confidence: 0.85,
            ),
          );
        }
      }
    }

    return entities;
  }

  /// Normalizes date string into ISO YYYY-MM-DD when possible.
  String _normalizeDob(String rawDob) {
    // Check YYYY-MM-DD
    final isoRegex = RegExp(r'^(\d{4})[-/.](\d{2})[-/.](\d{2})$');
    final isoMatch = isoRegex.firstMatch(rawDob);
    if (isoMatch != null) {
      return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
    }

    // Check MM/DD/YYYY
    final usRegex = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$');
    final usMatch = usRegex.firstMatch(rawDob);
    if (usMatch != null) {
      final month = usMatch.group(1)!.padLeft(2, '0');
      final day = usMatch.group(2)!.padLeft(2, '0');
      final year = usMatch.group(3)!;
      return '$year-$month-$day';
    }

    return rawDob;
  }

  /// Disposes underlying ONNX sessions.
  Future<void> dispose() async {
    await _piiSession?.close();
    _piiSession = null;
    _loadedTokenizer = null;
    _initialized = false;
  }
}
