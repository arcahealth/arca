import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/core/design_system/arca_design_system.dart';

void main() {
  group('NullableBuilder Tests', () {
    testWidgets('renders builder when value is non-null', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NullableBuilder<String>(
            value: 'hello',
            builder: (context, val) => Text(val),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders fallback when value is null', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NullableBuilder<String>(
            value: null,
            builder: (context, val) => Text(val),
            fallback: (context) => const Text('fallback'),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
    });

    test('orNull returns widget when non-null and null when null', () {
      final widget = NullableBuilder.orNull<String>(
        'active',
        (val) => Text(val),
      );
      expect(widget, isA<Text>());

      final nullWidget = NullableBuilder.orNull<String>(
        null,
        (val) => Text(val),
      );
      expect(nullWidget, isNull);

      final fallbackWidget = NullableBuilder.orNull<String>(
        null,
        (val) => Text(val),
        () => const SizedBox(),
      );
      expect(fallbackWidget, isA<SizedBox>());
    });
  });
}
