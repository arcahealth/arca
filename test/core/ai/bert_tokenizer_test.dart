import 'package:flutter_test/flutter_test.dart';
import 'package:arca/core/ai/bert_tokenizer.dart';

void main() {
  group('BertTokenizer Tests', () {
    late BertTokenizer tokenizer;

    setUp(() {
      final sampleVocab = {
        '[PAD]': 0,
        '[UNK]': 100,
        '[CLS]': 101,
        '[SEP]': 102,
        '[MASK]': 103,
        'patient': 104,
        'name': 105,
        'alex': 106,
        'morgan': 107,
        'amox': 108,
        '##ici': 109,
        '##llin': 110,
        '500': 111,
        '##mg': 112,
        ':': 113,
      };
      tokenizer = BertTokenizer.fromVocabMap(sampleVocab);
    });

    test('tokenizes known words cleanly with [CLS] and [SEP]', () {
      final encoding = tokenizer.encode('patient name: alex');

      expect(encoding.tokens, ['[CLS]', 'patient', 'name', ':', 'alex', '[SEP]']);
      expect(encoding.inputIds, [101, 104, 105, 113, 106, 102]);
      expect(encoding.attentionMask, [1, 1, 1, 1, 1, 1]);
      expect(encoding.tokenTypeIds, [0, 0, 0, 0, 0, 0]);
    });

    test('breaks down composite words into WordPiece subwords with ##', () {
      final encoding = tokenizer.encode('amoxicillin 500mg');

      expect(encoding.tokens, [
        '[CLS]',
        'amox',
        '##ici',
        '##llin',
        '500',
        '##mg',
        '[SEP]',
      ]);
      expect(encoding.inputIds, [101, 108, 109, 110, 111, 112, 102]);
    });

    test('handles unknown words with [UNK] token', () {
      final encoding = tokenizer.encode('xyzunknown');

      expect(encoding.tokens, ['[CLS]', '[UNK]', '[SEP]']);
      expect(encoding.inputIds, [101, 100, 102]);
    });

    test('tracks character offset spans accurately for tokens', () {
      const text = 'alex morgan';
      final encoding = tokenizer.encode(text);

      expect(encoding.tokens, ['[CLS]', 'alex', 'morgan', '[SEP]']);
      expect(encoding.spans[1], (0, 4));
      expect(text.substring(encoding.spans[1].$1, encoding.spans[1].$2), 'alex');
      expect(encoding.spans[2], (5, 11));
      expect(text.substring(encoding.spans[2].$1, encoding.spans[2].$2), 'morgan');
    });

    test('decodes token IDs back into text representation', () {
      final decoded = tokenizer.decode([108, 109, 110, 111, 112]);
      expect(decoded, 'amoxicillin 500mg');
    });

    test('parses vocabulary content string line by line', () {
      const vocabStr = '[PAD]\n[UNK]\n[CLS]\n[SEP]\nhealth\nvault';
      final tok = BertTokenizer.fromVocabString(
        vocabStr,
        padTokenId: 0,
        unkTokenId: 1,
        clsTokenId: 2,
        sepTokenId: 3,
      );

      final enc = tok.encode('health vault');
      expect(enc.tokens, ['[CLS]', 'health', 'vault', '[SEP]']);
      expect(enc.inputIds, [2, 4, 5, 3]);
    });
  });
}
