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

    test('encodes and decodes all onboarding flow sub-routes', () {
      expect(codec.encode([const .setupChoice()]), ['choice']);
      expect(codec.encode([const .aiPrep()]), ['ai-prep']);
      expect(codec.encode([const .documentScan()]), ['scan']);
      expect(codec.encode([const .extractedReview()]), ['review']);
      expect(codec.encode([const .manualName()]), ['name']);
      expect(codec.encode([const .manualVitals()]), ['vitals']);

      final choiceStack = codec.decode(['choice']);
      expect(choiceStack, isNotNull);
      expect(choiceStack!.last, isA<OnboardingSetupChoice>());

      final aiPrepStack = codec.decode(['ai-prep']);
      expect(aiPrepStack, isNotNull);
      expect(aiPrepStack!.last, isA<OnboardingAiPrep>());

      final scanStack = codec.decode(['scan']);
      expect(scanStack, isNotNull);
      expect(scanStack!.last, isA<OnboardingDocumentScan>());

      final reviewStack = codec.decode(['review']);
      expect(reviewStack, isNotNull);
      expect(reviewStack!.last, isA<OnboardingExtractedReview>());

      final nameStack = codec.decode(['name']);
      expect(nameStack, isNotNull);
      expect(nameStack!.last, isA<OnboardingManualName>());

      final vitalsStack = codec.decode(['vitals']);
      expect(vitalsStack, isNotNull);
      expect(vitalsStack!.last, isA<OnboardingManualVitals>());
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
