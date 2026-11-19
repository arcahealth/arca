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

    test('encodes and decodes all onboarding flow sub-routes dynamically', () {
      expect(codec.encode([const .documentScan()]), ['scan']);
      expect(codec.encode([const .userName()]), ['manual']);
      expect(codec.encode([const .extractedReview()]), ['overview']);

      final scanStack = codec.decode(['scan']);
      expect(scanStack, isNotNull);
      expect(scanStack!.length, 2);
      expect(scanStack.last, const OnboardingRoute.documentScan());

      final nameStack = codec.decode(['manual']);
      expect(nameStack, isNotNull);
      expect(nameStack!.length, 2);
      expect(nameStack.last, const OnboardingRoute.userName());

      final reviewStack = codec.decode(['overview']);
      expect(reviewStack, isNotNull);
      expect(reviewStack!.length, 3);
      expect(reviewStack.last, const OnboardingRoute.extractedReview());
    });

    test('decodes [] to [OnboardingRoute.welcome()]', () {
      final stack = codec.decode([]);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, const OnboardingRoute.welcome());
    });

    test("decodes [''] to [OnboardingRoute.welcome()]", () {
      final stack = codec.decode(['']);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, const OnboardingRoute.welcome());
    });

    test("decodes ['/'] to [OnboardingRoute.welcome()]", () {
      final stack = codec.decode(['/']);
      expect(stack, isNotNull);
      expect(stack!.length, 1);
      expect(stack.first, const OnboardingRoute.welcome());
    });

    test('decodes unrecognised path to null', () {
      final stack = codec.decode(['unknown', 'deep', 'link']);
      expect(stack, isNull);
    });
  });

  group('ArcaRouter.codec', () {
    final codec = ArcaRouter.codec();

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
