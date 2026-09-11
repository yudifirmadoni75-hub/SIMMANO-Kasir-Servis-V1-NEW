import 'package:flutter_test/flutter_test.dart';
import 'package:simmano_kasir_servis/src/services/app_store.dart';
import 'package:simmano_kasir_servis/src/app.dart';

void main() {
  testWidgets('empat bottom navigation tersedia', (tester) async {
    await store.init();
    await tester.pumpWidget(const SimmanoApp());
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Kasir'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
  });
}
