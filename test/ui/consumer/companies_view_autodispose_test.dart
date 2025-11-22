import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swe_mobile/data/models/company.dart';
import 'package:swe_mobile/data/repositories/company_repository.dart';
import 'package:swe_mobile/ui/consumer/consumer_shell.dart';
import 'package:swe_mobile/ui/consumer/views/companies_view.dart';

class FakeCompanyRepository implements CompanyRepository {
  int callCount = 0;

  @override
  Future<List<Company>> getAllCompanies() async {
    callCount++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Companies view disposes provider when navigating away', (tester) async {
    final fakeRepo = FakeCompanyRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ConsumerShell(),
        ),
      ),
    );

    // Initially on Orders tab (index 0)
    expect(find.text('Orders'), findsWidgets);
    expect(fakeRepo.callCount, 0);

    // Navigate to Companies tab (index 1)
    await tester.tap(find.text('Companies'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsumerCompaniesView), findsOneWidget);
    expect(fakeRepo.callCount, 1);

    // Navigate to Cart tab (index 3)
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsumerCompaniesView), findsNothing);

    // Navigate back to Companies tab
    await tester.tap(find.text('Companies'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsumerCompaniesView), findsOneWidget);
    // Should be called again if autoDispose works
    expect(fakeRepo.callCount, 2);
  });
}
