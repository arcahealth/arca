import 'package:flutter_test/flutter_test.dart';
import 'package:arca/app/routes.dart';

void main() {
  group('AppStackCodec', () {
    const codec = AppStackCodec();

    test('encodes JournalRoute to /', () {
      final uri = codec.encode([const JournalRoute()]);
      expect(uri.path, '/');
    });

    test('encodes RecordDetailRoute to /records/:id', () {
      final uri = codec.encode([
        const JournalRoute(),
        const RecordDetailRoute('vital-123'),
      ]);
      expect(uri.path, '/records/vital-123');
    });

    test('decodes / to [JournalRoute()]', () {
      final stack = codec.decode(Uri.parse('/'));
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<JournalRoute>());
    });

    test('decodes deep link /records/vital-123 to multi-frame stack', () {
      final stack = codec.decode(Uri.parse('/records/vital-123'));
      expect(stack, isNotNull);
      expect(stack!.length, 2);
      expect(stack.first, isA<JournalRoute>());
      expect(stack.last, isA<RecordDetailRoute>());
      expect((stack.last as RecordDetailRoute).recordId, 'vital-123');
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(Uri.parse('/unknown/deep/link'));
      expect(stack, isNull);
    });
  });
}
