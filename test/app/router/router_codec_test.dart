import 'package:arca/app/router/onboarding_routes.dart';
import 'package:arca/app/router/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStackCodec', () {
    const codec = AppStackCodec();

    test('encodes OnboardingMount to /onboarding', () {
      final uri = codec.encode([const OnboardingMount()]);
      expect(uri.path, '/onboarding');
    });

    test('decodes /onboarding to [OnboardingMount()]', () {
      final stack = codec.decode(Uri.parse('/onboarding'));
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<OnboardingMount>());
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(Uri.parse('/unknown/deep/link'));
      expect(stack, isNull);
    });
  });

  group('OnboardingModuleCodec', () {
    const codec = OnboardingModuleCodec();

    test('encodes OnboardingWelcome screen to an empty path', () {
      final path = codec.encode([const .welcome()]);
      expect(path.isEmpty, isTrue);
    });

    test('decodes [] to [OnboardingWelcome()]', () {
      final stack = codec.decode([]);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<OnboardingWelcome>());
    });

    test("decodes [''] to [OnboardingWelcome()]", () {
      final stack = codec.decode([]);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<OnboardingWelcome>());
    });

    test("decodes ['/'] to [OnboardingWelcome()]", () {
      final stack = codec.decode([]);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, isA<OnboardingWelcome>());
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(['unknown', 'deep', 'link']);
      expect(stack, isNull);
    });
  });

  group('AppRouterCodec', () {
    final codec = createAppRouterCodec();

    test('encodes OnboardingMount to /onboarding', () {
      final uri = codec.encode(.stackOnly([.onboarding()]));
      expect(uri.path, '/onboarding');
    });

    test('decodes /onboarding to [OnboardingMount()]', () {
      final stack = codec.decode(Uri.parse('/onboarding'));
      expect(stack, isNotNull);
      expect(stack!.mainStack.length, 1);
      expect(stack.mainStack.first, isA<OnboardingMount>());
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(Uri.parse('/unknown/deep/link'));
      expect(stack, isNull);
    });
  });
}
