import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/linking.dart';
import '../../shared/linkings/linkings_view.dart';

/// Supplier linkings view with tabs for different linking statuses.
/// Uses the shared LinkingsView component with accept/reject buttons enabled.
class SupplierLinkingsView extends ConsumerWidget {
  const SupplierLinkingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LinkingsView(
      showAcceptRejectButtons: true,
      companyIdToLoad: (Linking linking) => linking.consumerCompanyId,
    );
  }
}
