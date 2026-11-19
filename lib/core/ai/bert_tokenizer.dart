import 'package:flutter/services.dart';

import 'model_assets.dart';

/// Container for BERT tokenization and encoding outputs.
final class const BertEncoding(
  final List<int> inputIds,
  final List<int> attentionMask,
  final List<int> tokenTypeIds,
  final List<String> tokens,
  final List<(int, int)> spans,
);

/// WordPiece tokenizer implementation compatible with BERT and MiniLM-L6.
final class BertTokenizer {
  BertTokenizer.fromVocabMap(
    this.vocab, {
    this.doLowerCase = true,
    this.padTokenId = 0,
    this.unkTokenId = 100,
    this.clsTokenId = 101,
    this.sepTokenId = 102,
  }) {
    _invVocab = {for (final entry in vocab.entries) entry.value: entry.key};
  }

  factory BertTokenizer.fromVocabString(
    String vocabContent, {
    bool doLowerCase = true,
    int padTokenId = 0,
    int unkTokenId = 100,
    int clsTokenId = 101,
    int sepTokenId = 102,
  }) {
    final vocab = <String, int>{};
    final lines = vocabContent.split(RegExp(r'\r?\n'));
    var index = 0;
    for (final line in lines) {
      final token = line.trim();
      if (token.isNotEmpty) {
        vocab[token] = index;
        index++;
      }
    }
    return BertTokenizer.fromVocabMap(
      vocab,
      doLowerCase: doLowerCase,
      padTokenId: padTokenId,
      unkTokenId: unkTokenId,
      clsTokenId: clsTokenId,
      sepTokenId: sepTokenId,
    );
  }

  /// Vocabulary mapping from subword string to integer token ID.
  final Map<String, int> vocab;

  /// Whether to lowercase text before tokenization.
  final bool doLowerCase;

  final int padTokenId;
  final int unkTokenId;
  final int clsTokenId;
  final int sepTokenId;

  late final Map<int, String> _invVocab;

  /// Loads the tokenizer from bundled asset vocabulary file.
  static Future<BertTokenizer> fromAsset([
    String assetKey = ArcaModelAssets.piiVocab,
  ]) async {
    final vocabContent = await rootBundle.loadString(assetKey);
    return BertTokenizer.fromVocabString(vocabContent);
  }

  /// Tokenizes [text] into WordPiece subwords.
  List<String> tokenize(String text) {
    return encode(text).tokens;
  }

  /// Encodes [text] into model-ready tensors with offset spans.
  BertEncoding encode(String text, {int maxLength = 512}) {
    final inputIds = <int>[clsTokenId];
    final attentionMask = <int>[1];
    final tokenTypeIds = <int>[0];
    final tokens = <String>['[CLS]'];
    final spans = <(int, int)>[(0, 0)];

    final normalized = doLowerCase ? text.toLowerCase() : text;
    final wordsWithOffsets = _extractWordsWithOffsets(normalized, text);

    for (final (word, start, end) in wordsWithOffsets) {
      if (tokens.length >= maxLength - 1) break;

      if (vocab.containsKey(word)) {
        tokens.add(word);
        inputIds.add(vocab[word]!);
        attentionMask.add(1);
        tokenTypeIds.add(0);
        spans.add((start, end));
        continue;
      }

      // WordPiece subword breakdown
      var subStart = 0;
      var isBad = false;
      final subTokens = <String>[];
      final subSpans = <(int, int)>[];

      while (subStart < word.length) {
        var subEnd = word.length;
        String? curSubstr;

        while (subStart < subEnd) {
          var substr = word.substring(subStart, subEnd);
          if (subStart > 0) {
            substr = '##$substr';
          }

          if (vocab.containsKey(substr)) {
            curSubstr = substr;
            break;
          }
          subEnd--;
        }

        if (curSubstr == null) {
          isBad = true;
          break;
        }

        subTokens.add(curSubstr);
        subSpans.add((start + subStart, start + subEnd));
        subStart = subEnd;
      }

      if (isBad || subTokens.isEmpty) {
        tokens.add('[UNK]');
        inputIds.add(unkTokenId);
        attentionMask.add(1);
        tokenTypeIds.add(0);
        spans.add((start, end));
      } else {
        for (var i = 0; i < subTokens.length; i++) {
          if (tokens.length >= maxLength - 1) break;
          tokens.add(subTokens[i]);
          inputIds.add(vocab[subTokens[i]]!);
          attentionMask.add(1);
          tokenTypeIds.add(0);
          spans.add(subSpans[i]);
        }
      }
    }

    // Add [SEP]
    tokens.add('[SEP]');
    inputIds.add(sepTokenId);
    attentionMask.add(1);
    tokenTypeIds.add(0);
    spans.add((text.length, text.length));

    return BertEncoding(inputIds, attentionMask, tokenTypeIds, tokens, spans);
  }

  /// Decodes [tokenIds] into reconstructed text.
  String decode(List<int> tokenIds, {bool skipSpecialTokens = true}) {
    final buffer = StringBuffer();
    for (final id in tokenIds) {
      if (skipSpecialTokens && (id == padTokenId || id == unkTokenId || id == clsTokenId || id == sepTokenId)) {
        continue;
      }
      final token = _invVocab[id] ?? '';
      if (token.startsWith('##')) {
        buffer.write(token.substring(2));
      } else {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(token);
      }
    }
    return buffer.toString();
  }

  /// Splits [text] into words, numbers, and punctuation with character offsets.
  List<(String, int, int)> _extractWordsWithOffsets(
    String normalized,
    String original,
  ) {
    final result = <(String, int, int)>[];
    final pattern = RegExp(r"[\w]+|[^\s\w]");
    final matches = pattern.allMatches(normalized);

    for (final match in matches) {
      final token = match.group(0)!;
      result.add((token, match.start, match.end));
    }
    return result;
  }
}
