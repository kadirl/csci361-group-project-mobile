import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/linking.dart';
import '../../shared/orders/orders_view.dart';

/// Consumer orders view.
/// Uses the shared OrdersView component.
/// Shows the supplier company that the consumer is linked to.
class ConsumerOrdersView extends ConsumerWidget {
  const ConsumerOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrdersView(
      companyIdToLoad: (Linking linking) => linking.supplierCompanyId,
    );
  }
}

