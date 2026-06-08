import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:front_genapp/app.dart';

void main() {
  testWidgets('App renders login screen when not authenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GeneApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
