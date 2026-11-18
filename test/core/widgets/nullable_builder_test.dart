import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arca/core/widgets/widgets.dart';

void main() {
  group('NullableBuilder Tests', () {
    testWidgets('renders builder when value is non-null', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NullableBuilder<String>(
            'hello',
            builder: (context, val) => Text(val),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders fallback widget when value is null', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NullableBuilder<String>(
            null,
            builder: (context, val) => Text(val),
            fallback: const Text('fallback'),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
    });

    testWidgets(
      'renders SizedBox.shrink when value is null and fallback omitted',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: NullableBuilder<String>(
              null,
              builder: (context, val) => Text(val),
            ),
          ),
        );

        expect(find.byType(SizedBox), findsOneWidget);
      },
    );
  });
}
