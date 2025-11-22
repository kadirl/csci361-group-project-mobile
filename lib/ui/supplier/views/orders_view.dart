import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/linking.dart';
import '../../shared/orders/orders_view.dart';

/// Supplier orders view.
/// Uses the shared OrdersView component.
/// Shows the consumer company that the supplier is linked to.
class SupplierOrdersView extends ConsumerWidget {
  const SupplierOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrdersView(
      companyIdToLoad: (Linking linking) => linking.consumerCompanyId,
    );
  }
}

