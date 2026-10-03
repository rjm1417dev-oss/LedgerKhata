import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/data/khata_repository.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/models/business.dart';
import 'package:my_first_app/widgets/buttons.dart';

import 'support/fake_repository.dart';
import 'support/test_setup.dart';

const _business = Business(name: 'Al-Noor Traders', ownerName: 'Bilal Ahmed', phone: '0300 1122334');

Future<FakeRepository> pumpSignedIn(WidgetTester tester, {Future<void> Function(FakeRepository)? seed}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ignoreFontMetricOverflows();
  final repo = FakeRepository(signedIn: true, business: _business);
  await seed?.call(repo);
  await tester.pumpWidget(KhataApp(repository: repo, splashMinimum: Duration.zero));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> settleToasts(WidgetTester tester) => tester.pump(const Duration(seconds: 4));

void main() {
  testWidgets('tabs switch and each tab shows its content', (tester) async {
    await pumpSignedIn(tester);
    expect(find.text('Total remaining'), findsOneWidget);

    await openTab(tester, 'Khata');
    expect(find.text('No khatas yet'), findsWidgets);
    await openTab(tester, 'Items');
    expect(find.text('No items yet'), findsOneWidget);
    await openTab(tester, 'Customers');
    expect(find.text('No customers yet'), findsOneWidget);
    await openTab(tester, 'Settings');
    expect(find.text('Business account'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);
  });

  testWidgets('add an item from the sheet, with validation', (tester) async {
    await pumpSignedIn(tester);
    await openTab(tester, 'Items');

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the item name'), findsOneWidget);
    expect(find.text('Enter a price greater than 0'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Basmati Rice 5kg');
    await tester.enterText(fields.at(1), '1650');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Basmati Rice 5kg'), findsOneWidget);
    expect(find.text('Rs 1,650 / piece'), findsOneWidget);
    expect(find.text('Basmati Rice 5kg added'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a backend failure shows an error toast and keeps the sheet open', (tester) async {
    final repo = await pumpSignedIn(tester);
    await openTab(tester, 'Customers');

    await tester.tap(find.text('Add customer'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ahmed Raza');
    await tester.enterText(fields.at(1), '0300 1234567');

    repo.failNextWrite = const RepositoryException('No internet connection. Check your network and try again.');
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection. Check your network and try again.'), findsOneWidget);
    expect(find.text('Save customer'), findsOneWidget); // sheet still open, can retry
    await settleToasts(tester);

    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Raza'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('create a khata end to end with the money rules', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      await repo.addItem(name: 'Cooking Oil 1L', price: 560, unit: 'piece');
      await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    });

    await openTab(tester, 'Khata');
    await tester.tap(find.text('New Khata').first);
    await tester.pumpAndSettle();

    // Saving an empty form shows all three section errors.
    await tester.tap(find.text('Save Khata'));
    await tester.pumpAndSettle();
    expect(find.text('Select a customer for this khata'), findsOneWidget);
    expect(find.text('Select at least one item'), findsOneWidget);

    await tester.tap(find.text('Choose a customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahmed Raza'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search by item name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basmati Rice 5kg'));
    await tester.tap(find.text('Cooking Oil 1L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Items total'), findsOneWidget);

    // The payment section is below the fold, so scroll to it first.
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    final count = fields.evaluate().length;
    final discount = fields.at(count - 2);
    final paid = fields.at(count - 1);
    await tester.enterText(discount, '65');
    await tester.enterText(paid, '3000');
    await tester.pumpAndSettle();
    expect(find.textContaining('can’t be more than the items total'), findsOneWidget);
    expect(find.text('−Rs 855'), findsWidgets);

    await tester.enterText(paid, '1500');
    await tester.pumpAndSettle();
    expect(find.text('Rs 645'), findsWidgets);

    await tester.tap(find.text('Save Khata'));
    await tester.pumpAndSettle();
    expect(find.text('Khata saved for Ahmed Raza'), findsOneWidget);
    await settleToasts(tester);

    // Back on the Khata tab the new khata is listed with its balance.
    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    expect(find.text('Rs 645 due'), findsNothing); // due badge is hidden on the Khata tab
  });

  testWidgets('dashboard shows compact recent khatas and View all opens the Khata tab', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final rice = await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      final oil = await repo.addItem(name: 'Cooking Oil 1L', price: 560, unit: 'piece');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(
        customerId: ahmed.id,
        items: [
          KhataItemSelection(itemId: rice.id, quantity: 1),
          KhataItemSelection(itemId: oil.id, quantity: 1),
        ],
        discount: 65,
        paid: 1500,
      );
    });

    // Hero, tiles and the compact recent card.
    expect(find.text('Rs 645'), findsOneWidget);
    expect(find.text('Pending on 1 of 1 khatas'), findsOneWidget);
    expect(find.text('Recent khatas'), findsOneWidget);
    expect(find.text('Rs 645 due'), findsOneWidget);
    expect(find.text('25 Sep 2026 \u00b7 2 items'), findsOneWidget);
    expect(find.text('Paid'), findsNothing); // the item/total breakdown only lives on the Khata tab

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Rs 1,500'), findsOneWidget);
  });

  testWidgets('edit an item from the list', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addItem(name: 'Sugar', price: 100, unit: 'kg');
    });
    await openTab(tester, 'Items');

    await tester.tap(find.text('Sugar'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item'), findsOneWidget);

    final priceField = find.byType(TextField).at(1);
    await tester.enterText(priceField, '150');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Sugar updated'), findsOneWidget);
    expect(find.text('Rs 150 / kg'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('delete an item shows a confirm dialog before removing it', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addItem(name: 'Sugar', price: 100, unit: 'kg');
    });
    await openTab(tester, 'Items');

    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Sugar?'), findsOneWidget);
    expect(find.text('This can’t be undone.'), findsOneWidget);

    // Cancel leaves the item in place.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sugar'), findsOneWidget);

    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Sugar'), findsNothing);
    expect(find.text('Sugar deleted'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('deleting an item used in a khata warns how many khatas reference it', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final sugar = await repo.addItem(name: 'Sugar', price: 100, unit: 'kg');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(
        customerId: ahmed.id,
        items: [KhataItemSelection(itemId: sugar.id, quantity: 2)],
        discount: 0,
        paid: 0,
      );
    });
    await openTab(tester, 'Items');

    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Used in 1 khata'), findsOneWidget);
  });

  testWidgets('edit a customer from their detail page', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    });
    await openTab(tester, 'Customers');

    await tester.tap(find.text('Ahmed Raza'));
    await tester.pumpAndSettle();
    expect(find.text('0300 1234567'), findsOneWidget); // now on the detail page

    // Header icons in order: back, edit, close.
    await tester.tap(find.byType(IconButtonGhost).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Edit customer'), findsOneWidget);

    final nameField = find.byType(TextField).at(0);
    await tester.enterText(nameField, 'Ahmed Khan');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Khan updated'), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('the close icon on the detail page just goes back', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    });
    await openTab(tester, 'Customers');

    await tester.tap(find.text('Ahmed Raza'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButtonGhost).last);
    await tester.pumpAndSettle();

    expect(find.text('1 customer'), findsOneWidget); // back on the list, untouched
    expect(find.text('Ahmed Raza'), findsOneWidget);
  });

  testWidgets('delete a customer with no khatas via the confirm dialog', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
    });
    await openTab(tester, 'Customers');

    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Ahmed Raza?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No customers yet'), findsOneWidget);
    expect(find.text('Ahmed Raza'), findsNothing);
    expect(find.text('Ahmed Raza deleted'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('deleting a customer with khatas is blocked with an explanatory dialog', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final rice = await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(
        customerId: ahmed.id,
        items: [KhataItemSelection(itemId: rice.id, quantity: 1)],
        discount: 0,
        paid: 0,
      );
    });
    await openTab(tester, 'Customers');

    await tester.tap(find.byType(IconButtonGhost).first);
    await tester.pumpAndSettle();
    expect(find.text('Can’t delete Ahmed Raza'), findsOneWidget);
    expect(find.textContaining('has 1 khata on record'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Still on the list, customer untouched.
    expect(find.text('Ahmed Raza'), findsOneWidget);
  });

  testWidgets('customer detail page shows their khata history and clears the khata in one payment', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final rice = await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(
        customerId: ahmed.id,
        items: [KhataItemSelection(itemId: rice.id, quantity: 1)],
        discount: 0,
        paid: 0,
      );
    });
    await openTab(tester, 'Customers');

    await tester.tap(find.text('Ahmed Raza'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Basmati Rice 5kg'), findsWidgets);
    expect(find.text('Rs 1,650 due'), findsNothing); // no per-khata due badge on the detail page
    expect(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButtonSmall, 'Record payment'), findsNothing);

    await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
    await tester.pumpAndSettle();

    // Customer is already known, so there is no picker; the full balance is pre-filled.
    expect(find.text('Total outstanding'), findsOneWidget);
    expect(find.text('Choose a customer'), findsNothing);
    expect(find.text('1650'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
    await tester.pumpAndSettle();

    expect(find.text('Khata cleared for Ahmed Raza'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('Rs 1,650 due'), findsNothing);
    await settleToasts(tester);
  });

  testWidgets('Khata tab clears a khata by choosing the customer first', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final rice = await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(
        customerId: ahmed.id,
        items: [KhataItemSelection(itemId: rice.id, quantity: 1)],
        discount: 0,
        paid: 0,
      );
    });
    await openTab(tester, 'Khata');

    await tester.tap(find.widgetWithText(PrimaryButtonSmall, 'Clear Khata'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahmed Raza · Rs 1,650').last);
    await tester.pumpAndSettle();
    expect(find.text('Total outstanding'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Clear Khata'));
    await tester.pumpAndSettle();

    expect(find.text('Khata cleared for Ahmed Raza'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('edit business details from Settings', (tester) async {
    await pumpSignedIn(tester);
    await openTab(tester, 'Settings');

    expect(find.text('Not set'), findsNWidgets(2)); // Address, Public contact number

    await tester.tap(find.byType(IconButtonGhost));
    await tester.pumpAndSettle();
    expect(find.text('Edit business'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(3), 'Shop 4, Main Bazaar, Lahore');
    await tester.enterText(fields.at(4), '0321 9876543');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Business details updated'), findsOneWidget);
    expect(find.text('Shop 4, Main Bazaar, Lahore'), findsOneWidget);
    expect(find.text('0321 9876543'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('signing out lands on the sign in screen, not register', (tester) async {
    await pumpSignedIn(tester);
    await openTab(tester, 'Settings');

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });

  testWidgets('dashboard shows Clear Khata and New Khata as equal-width buttons', (tester) async {
    await pumpSignedIn(tester, seed: (repo) async {
      final rice = await repo.addItem(name: 'Basmati Rice 5kg', price: 1650, unit: 'piece');
      final ahmed = await repo.addCustomer(name: 'Ahmed Raza', phone: '0300 1234567');
      await repo.createKhata(customerId: ahmed.id, items: [KhataItemSelection(itemId: rice.id, quantity: 1)], discount: 0, paid: 0);
    });

    final clear = find.widgetWithText(PrimaryButtonSmall, 'Clear Khata');
    final add = find.widgetWithText(PrimaryButtonSmall, 'New Khata');
    expect(clear, findsOneWidget);
    expect(add, findsOneWidget);
    expect(tester.getSize(clear).width, tester.getSize(add).width);
    expect(tester.getSize(clear).height, tester.getSize(add).height);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('New Khata'), findsWidgets); // the new khata screen opened
  });
}
