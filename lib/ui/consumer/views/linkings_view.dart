import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/linking.dart';
import '../../shared/linkings/linkings_view.dart';

/// Consumer linkings view with tabs for different linking statuses.
/// Uses the shared LinkingsView component without accept/reject buttons.
/// Shows the supplier company that the consumer sent the linking to.
class ConsumerLinkingsView extends ConsumerWidget {
  const ConsumerLinkingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LinkingsView(
      showAcceptRejectButtons: false,
      companyIdToLoad: (Linking linking) => linking.supplierCompanyId,
    );
  }
}

