import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_genapp/ui/core/widgets/loading_button.dart';

void main() {
  group('LoadingButton', () {
    testWidgets('shows label when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              loading: false,
              label: 'Guardar',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Guardar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              loading: true,
              label: 'Guardar',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('is disabled when loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              loading: true,
              label: 'Guardar',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, false);
    });

    testWidgets('is enabled when not loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              loading: false,
              label: 'Guardar',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });
  });
}
