import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/complaint.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Complaint detail view showing full information about a complaint.
class ComplaintDetailView extends ConsumerStatefulWidget {
  const ComplaintDetailView({
    super.key,
    required this.complaintId,
  });

  final int complaintId;

  @override
  ConsumerState<ComplaintDetailView> createState() => _ComplaintDetailViewState();
}

class _ComplaintDetailViewState extends ConsumerState<ComplaintDetailView> {
  Complaint? _complaint;
  List<ComplaintHistoryEntry> _history = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;
  int? _defaultSalesmanId; // Salesman from linking (default assignment)

  @override
  void initState() {
    super.initState();
    _loadComplaint();
    _loadHistory();
  }

  // Load complaint details
  Future<void> _loadComplaint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final complaintRepo = ref.read(complaintRepositoryProvider);
      final complaint = await complaintRepo.getComplaintDetails(
        complaintId: widget.complaintId,
      );

      // Load order to get linking_id
      final orderRepo = ref.read(orderRepositoryProvider);
      final order = await orderRepo.getOrder(orderId: complaint.orderId);

      // Load linking to get assigned salesman (default assignment)
      int? defaultSalesmanId;
      try {
        final linkingRepo = ref.read(linkingRepositoryProvider);
        final userState = ref.read(userProfileProvider);
        final appUser = userState.value;

        if (appUser?.companyId != null) {
          final linkings = await linkingRepo.getLinkingsByCompany(
            companyId: appUser!.companyId!,
          );
          final linkingList = linkings
              .where((l) => l.linkingId == order.linkingId)
              .toList();
          if (linkingList.isNotEmpty) {
            defaultSalesmanId = linkingList.first.assignedSalesmanUserId;
          }
        }
      } catch (e) {
        debugPrint('ComplaintDetailView -> Error loading linking: $e');
      }

      if (mounted) {
        debugPrint('ComplaintDetailView -> Loaded complaint:');
        debugPrint('  - assignedSalesmanId: ${complaint.assignedSalesmanId}');
        debugPrint('  - assignedManagerId: ${complaint.assignedManagerId}');
        debugPrint('  - defaultSalesmanId (from linking): $defaultSalesmanId');
        setState(() {
          _complaint = complaint;
          _defaultSalesmanId = defaultSalesmanId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Load complaint history
  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final repository = ref.read(complaintRepositoryProvider);
      final history = await repository.getComplaintHistory(
        complaintId: widget.complaintId,
      );

      // Sort history by date (oldest first) for timeline display
      history.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.updatedAt);
          final dateB = DateTime.parse(b.updatedAt);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('ComplaintDetailView -> Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');
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
  String _getStatusDisplayName(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return 'OPEN';
      case ComplaintStatus.escalated:
        return 'ESCALATED';
      case ComplaintStatus.inProgress:
        return 'IN PROGRESS';
      case ComplaintStatus.resolved:
        return 'RESOLVED';
      case ComplaintStatus.closed:
        return 'CLOSED';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${_error ?? 'Complaint not found'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadComplaint,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final complaint = _complaint!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint #${complaint.complaintId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            Row(
              children: [
                Chip(
                  label: Text(_getStatusDisplayName(complaint.status)),
                  backgroundColor: _getStatusColor(complaint.status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(complaint.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Complaint information
            Text(
              'Complaint Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(complaint.createdAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Updated',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(complaint.updatedAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (complaint.resolutionNotes != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Resolution Notes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.resolutionNotes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (complaint.cancelOrder == true) ...[
                      const SizedBox(height: 16),
                      Chip(
                        label: const Text('Order Cancelled'),
                        backgroundColor: Colors.red.withOpacity(0.2),
                        labelStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assigned personnel
            Text(
              'Assigned Personnel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show assigned salesman (from complaint or default from linking)
                    if (complaint.assignedSalesmanId != null ||
                        (_defaultSalesmanId != null &&
                            complaint.status != ComplaintStatus.escalated &&
                            complaint.status != ComplaintStatus.inProgress)) ...[
                      _buildPersonnelRow(
                        context,
                        'Assigned Salesman',
                        complaint.assignedSalesmanId ?? _defaultSalesmanId!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show assigned manager
                    if (complaint.assignedManagerId != null) ...[
                      _buildPersonnelRow(
                        context,
                        'Assigned Manager',
                        complaint.assignedManagerId!,
                      ),
                    ] else if (complaint.status == ComplaintStatus.escalated ||
                        complaint.status == ComplaintStatus.inProgress) ...[
                      Text(
                        'No manager assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                    // Show message if no personnel is assigned at all
                    if (complaint.assignedSalesmanId == null &&
                        _defaultSalesmanId == null &&
                        complaint.assignedManagerId == null &&
                        complaint.status != ComplaintStatus.escalated &&
                        complaint.status != ComplaintStatus.inProgress) ...[
                      Text(
                        'No personnel assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // History timeline
            Text(
              'History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No history available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              )
            else
              ..._history.map((entry) => _buildHistoryEntry(context, entry)),
            const SizedBox(height: 24),

            // Actions section
            if (_canPerformActions()) ...[
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ..._buildActionButtons(context, complaint),
            ],
          ],
        ),
      ),
    );
  }

  // Check if current user can perform actions
  bool _canPerformActions() {
    if (_complaint == null) return false;

    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;
    if (appUser == null) return false;

    final complaint = _complaint!;

    // Salesman can escalate open complaints assigned to them
    if (appUser.role == UserRole.staff &&
        complaint.status == ComplaintStatus.open &&
        complaint.assignedSalesmanId == appUser.id) {
      return true;
    }

    // Salesman can resolve open complaints assigned to them
    if (appUser.role == UserRole.staff &&
        complaint.status == ComplaintStatus.open &&
        complaint.assignedSalesmanId == appUser.id) {
      return true;
    }

    // Manager/Owner can claim escalated complaints
    if ((appUser.role == UserRole.manager || appUser.role == UserRole.owner) &&
        complaint.status == ComplaintStatus.escalated) {
      return true;
    }

    // Manager can resolve/resolve in_progress complaints assigned to them
    if ((appUser.role == UserRole.manager || appUser.role == UserRole.owner) &&
        complaint.status == ComplaintStatus.inProgress &&
        complaint.assignedManagerId == appUser.id) {
      return true;
    }

    return false;
  }

  // Build action buttons based on user role and complaint status
  List<Widget> _buildActionButtons(BuildContext context, Complaint complaint) {
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;
    if (appUser == null) return [];

    final List<Widget> buttons = [];

    // Salesman actions for open complaints
    if (appUser.role == UserRole.staff &&
        complaint.status == ComplaintStatus.open &&
        complaint.assignedSalesmanId == appUser.id) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _handleEscalate(context, complaint),
          icon: const Icon(Icons.arrow_upward),
          label: const Text('Escalate to Manager'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.orange,
          ),
        ),
      );
      buttons.add(const SizedBox(height: 8));
      buttons.add(
        FilledButton.icon(
          onPressed: () => _handleResolve(context, complaint),
          icon: const Icon(Icons.check_circle),
          label: const Text('Resolve'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.green,
          ),
        ),
      );
    }

    // Manager/Owner actions for escalated complaints
    if ((appUser.role == UserRole.manager || appUser.role == UserRole.owner) &&
        complaint.status == ComplaintStatus.escalated) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _handleClaim(context, complaint),
          icon: const Icon(Icons.assignment),
          label: const Text('Claim Complaint'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.blue,
          ),
        ),
      );
    }

    // Manager/Owner actions for in_progress complaints
    if ((appUser.role == UserRole.manager || appUser.role == UserRole.owner) &&
        complaint.status == ComplaintStatus.inProgress &&
        complaint.assignedManagerId == appUser.id) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _handleResolve(context, complaint),
          icon: const Icon(Icons.check_circle),
          label: const Text('Resolve'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.green,
          ),
        ),
      );
      buttons.add(const SizedBox(height: 8));
      buttons.add(
        FilledButton.icon(
          onPressed: () => _handleClose(context, complaint),
          icon: const Icon(Icons.close),
          label: const Text('Close'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.grey,
          ),
        ),
      );
    }

    return buttons;
  }

  // Handle escalate action
  Future<void> _handleEscalate(BuildContext context, Complaint complaint) async {
    final TextEditingController notesController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Escalate Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optional: Add notes explaining why you are escalating:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(complaintRepositoryProvider);
      final request = UpdateComplaintStatusRequest(
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      await repository.escalateComplaint(
        complaintId: complaint.complaintId,
        request: request,
      );

      // Reload complaint
      await _loadComplaint();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint escalated successfully'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error escalating complaint: $error'),
          ),
        );
      }
    }
  }

  // Handle claim action
  Future<void> _handleClaim(BuildContext context, Complaint complaint) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Claim Complaint'),
        content: const Text(
          'Are you sure you want to claim this complaint? You will be responsible for managing it.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(complaintRepositoryProvider);
      await repository.claimComplaint(complaintId: complaint.complaintId);

      // Reload complaint
      await _loadComplaint();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint claimed successfully'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming complaint: $error'),
          ),
        );
      }
    }
  }

  // Handle resolve action
  Future<void> _handleResolve(BuildContext context, Complaint complaint) async {
    final TextEditingController notesController = TextEditingController();
    bool cancelOrder = false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Resolve Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide resolution notes:'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Only managers/owners can cancel orders
              if (ref.read(userProfileProvider).value?.role == UserRole.manager ||
                  ref.read(userProfileProvider).value?.role == UserRole.owner) ...[
                CheckboxListTile(
                  title: const Text('Cancel Order'),
                  value: cancelOrder,
                  onChanged: (value) {
                    setDialogState(() {
                      cancelOrder = value ?? false;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter resolution notes'),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final String notes = notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter resolution notes'),
        ),
      );
      return;
    }

    try {
      final repository = ref.read(complaintRepositoryProvider);
      final request = ResolveComplaintRequest(
        resolutionNotes: notes,
        cancelOrder: cancelOrder,
      );

      await repository.resolveComplaint(
        complaintId: complaint.complaintId,
        request: request,
      );

      // Reload complaint
      await _loadComplaint();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint resolved successfully'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resolving complaint: $error'),
          ),
        );
      }
    }
  }

  // Handle close action
  Future<void> _handleClose(BuildContext context, Complaint complaint) async {
    final TextEditingController notesController = TextEditingController();
    bool cancelOrder = false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Close Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide notes explaining why the complaint is being closed:'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Cancel Order'),
                value: cancelOrder,
                onChanged: (value) {
                  setDialogState(() {
                    cancelOrder = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter resolution notes'),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final String notes = notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter resolution notes'),
        ),
      );
      return;
    }

    try {
      final repository = ref.read(complaintRepositoryProvider);
      final request = ResolveComplaintRequest(
        resolutionNotes: notes,
        cancelOrder: cancelOrder,
      );

      await repository.closeComplaint(
        complaintId: complaint.complaintId,
        request: request,
      );

      // Reload complaint
      await _loadComplaint();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint closed successfully'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing complaint: $error'),
          ),
        );
      }
    }
  }

  // Build personnel row with user info
  Widget _buildPersonnelRow(BuildContext context, String label, int userId) {
    return FutureBuilder<AppUser?>(
      future: ref.read(userRepositoryProvider).getUserById(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final user = snapshot.data;
        if (user == null) {
          return Text(
            '$label: User #$userId',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${user.firstName} ${user.lastName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  // Build history entry
  Widget _buildHistoryEntry(BuildContext context, ComplaintHistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(entry.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Entry details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(_getStatusDisplayName(entry.status)),
                        backgroundColor:
                            _getStatusColor(entry.status).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getStatusColor(entry.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(entry.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (entry.userName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By: ${entry.userName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

