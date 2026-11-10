import 'package:flutter_test/flutter_test.dart';
import 'package:arca/app/routes.dart';

void main() {
  group('AppStackCodec', () {
    const codec = AppStackCodec();

    test('encodes WelcomeRoute to /', () {
      final uri = codec.encode([const WelcomeRoute()]);
      expect(uri.path, '/');
    });

    test('decodes / to [WelcomeRoute()]', () {
      final stack = codec.decode(Uri.parse('/'));
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<WelcomeRoute>());
    });

    test('decodes /welcome to [WelcomeRoute()]', () {
      final stack = codec.decode(Uri.parse('/welcome'));
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<WelcomeRoute>());
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(Uri.parse('/unknown/deep/link'));
      expect(stack, isNull);
    });
  });
}
