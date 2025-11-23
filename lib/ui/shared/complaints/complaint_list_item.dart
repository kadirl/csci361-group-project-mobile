import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/complaint.dart';
import '../../../data/models/company.dart';
import '../../../l10n/app_localizations.dart';

/// Widget for displaying a complaint in a list.
class ComplaintListItem extends StatelessWidget {
  const ComplaintListItem({
    super.key,
    required this.complaint,
    this.consumerCompany,
    this.onTap,
    this.showQuickAction = false,
    this.quickActionLabel,
    this.onQuickAction,
  });

  final Complaint complaint;
  final Company? consumerCompany;
  final VoidCallback? onTap;
  final bool showQuickAction;
  final String? quickActionLabel;
  final VoidCallback? onQuickAction;

  // Format date string
  String _formatDate(String? dateString, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dateString == null || dateString.isEmpty) {
      return l10n.commonNA;
    }

    try {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('MMM dd, yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  // Get status color
  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return Colors.orange;
      case ComplaintStatus.escalated:
        return Colors.red;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  // Get status display name
  String _getStatusDisplayName(ComplaintStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ComplaintStatus.open:
        return l10n.complaintStatusOpen;
      case ComplaintStatus.escalated:
        return l10n.complaintStatusEscalated;
      case ComplaintStatus.inProgress:
        return l10n.complaintStatusInProgress;
      case ComplaintStatus.resolved:
        return l10n.complaintStatusResolved;
      case ComplaintStatus.closed:
        return l10n.complaintStatusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Order # and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.orderDetailsTitle.split(' ').first} #${complaint.orderId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text(_getStatusDisplayName(complaint.status, context)),
                    backgroundColor: _getStatusColor(complaint.status).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getStatusColor(complaint.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Consumer company name
              if (consumerCompany != null) ...[
                Text(
                  consumerCompany!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
              ],
              // Description (truncated)
              Text(
                complaint.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Footer row: Date and quick action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(complaint.createdAt, context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  if (showQuickAction && quickActionLabel != null && onQuickAction != null)
                    TextButton(
                      onPressed: onQuickAction,
                      child: Text(quickActionLabel!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

