import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/widgets/badges.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(
  name: 'Test Store',
  ownerName: 'Ali',
  phone: '0300 0000000',
);

void main() {
  testWidgets(
    'Khata list shows Pending badge on unsettled and Settled on settled',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ignoreFontMetricOverflows();

      final repo = FakeRepository(signedIn: true, business: _business);

      // Create an item
      final rice = await repo.addItem(
        name: 'Basmati Rice 5kg',
        price: 1650,
        unit: 'piece',
      );

      // Customer 1: will have an unsettled khata (paid = 0)
      final ahmed = await repo.addCustomer(
        name: 'Ahmed Raza',
        phone: '0300 1234567',
      );
      await repo.createKhata(
        customerId: ahmed.id,
        items: [KhataItemSelection(itemId: rice.id, quantity: 1)],
        discount: 0,
        paid: 0,
      );

      // Customer 2: will have a settled khata (paid = total)
      final fatima = await repo.addCustomer(
        name: 'Fatima Noor',
        phone: '0300 9876543',
      );
      await repo.createKhata(
        customerId: fatima.id,
        items: [KhataItemSelection(itemId: rice.id, quantity: 1)],
        discount: 0,
        paid: 1650,
      );

      // Use the full app so routing and state initialisation follow the
      // real flow (AuthGate → RootShell → tab bar).
      await tester.pumpWidget(
        KhataApp(repository: repo, splashMinimum: Duration.zero),
      );
      await tester.pumpAndSettle();

      // Navigate to the Khata tab
      await tester.tap(find.text('Khata').last);
      await tester.pumpAndSettle();

      // Ahmed's khata is unsettled → PendingBadge
      expect(find.byType(PendingBadge), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Fatima's khata is settled → SettledBadge
      expect(find.byType(SettledBadge), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);
    },
  );
}
