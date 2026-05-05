import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/app.dart';
import 'package:flutter_pos/data/services/local_pos_backend.dart';

void main() {
  testWidgets('renders POS dashboard', (tester) async {
    final backend = await LocalPosBackend.bootstrap();

    await tester.pumpWidget(PosApp(backend: backend));
    await tester.pumpAndSettle();

    expect(find.text('Minimal POS'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });
}
