import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/button_sizes.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/models/company.dart';
import '../../../../data/models/linking.dart';
import '../../../../data/repositories/company_repository.dart';
import '../../../../data/repositories/linking_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../consumer/views/company_detail_view.dart';

/// Linking detail view showing full information about a linking.
/// 
/// [showAcceptRejectButtons] - If true, shows accept/reject buttons for pending linkings (supplier view).
/// [companyIdToLoad] - The company ID to load and display (supplierCompanyId for consumer, consumerCompanyId for supplier).
class LinkingDetailView extends ConsumerStatefulWidget {
  const LinkingDetailView({
    super.key,
    required this.linking,
    this.showAcceptRejectButtons = false,
    required this.companyIdToLoad,
  });

  final Linking linking;
  final bool showAcceptRejectButtons;
  final int companyIdToLoad;

  @override
  ConsumerState<LinkingDetailView> createState() => _LinkingDetailViewState();
}

class _LinkingDetailViewState extends ConsumerState<LinkingDetailView> {
  Company? _company;
  AppUser? _salesperson;
  bool _isLoadingCompany = false;
  bool _isLoadingSalesperson = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
    _loadSalespersonData();
  }

  // Load company information.
  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoadingCompany = true;
    });

    try {
      final companyRepo = ref.read(companyRepositoryProvider);
      final company = await companyRepo.getCompany(companyId: widget.companyIdToLoad);
      
      if (mounted) {
        setState(() {
          _company = company;
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompany = false;
        });
      }
    }
  }

  // Load salesperson information if assigned.
  Future<void> _loadSalespersonData() async {
    if (widget.linking.assignedSalesmanUserId == null) {
      return;
    }

    setState(() {
      _isLoadingSalesperson = true;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getUserById(userId: widget.linking.assignedSalesmanUserId!);
      
      if (mounted) {
        setState(() {
          _salesperson = user;
          _isLoadingSalesperson = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSalesperson = false;
        });
      }
    }
  }

  // Format date string to human-readable format.
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

  // Check if current user can unlink (manager or owner).
  bool _canUnlink() {
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;
    
    if (appUser == null) {
      return false;
    }
    
    return appUser.role == UserRole.owner || appUser.role == UserRole.manager;
  }

  // Handle accept action.
  Future<void> _handleAccept() async {
    if (widget.linking.linkingId == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.acceptLinking(linkingId: widget.linking.linkingId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linking accepted')),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting linking: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Handle reject action.
  Future<void> _handleReject() async {
    if (widget.linking.linkingId == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.rejectLinking(linkingId: widget.linking.linkingId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linking rejected')),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting linking: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Handle unlink action with confirmation.
  Future<void> _handleUnlink() async {
    // Show confirmation dialog.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Unlink Companies'),
        content: const Text('Are you sure you want to unlink these companies? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.linking.linkingId == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.unlinkLinking(linkingId: widget.linking.linkingId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companies unlinked')),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Navigate to user profile.
  void _navigateToUserProfile(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileDetailView(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Linking number and status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Linking #${widget.linking.linkingId ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Chip(
                  label: Text(widget.linking.status.name.toUpperCase()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Linking message
            if (widget.linking.message != null) ...[
              Text(
                widget.linking.message!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],

            // Linking date time
            Text(
              'Created: ${_formatDate(widget.linking.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Company card
            Text(
              'Company',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CompanyDetailView(companyId: widget.companyIdToLoad),
                      ),
                    );
                  },
                  child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _isLoadingCompany
                      ? const Center(child: CircularProgressIndicator())
                      : _company == null
                          ? const Text('Failed to load company')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // Company logo at the top
                                if (_company!.logoUrl != null && _company!.logoUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Image.network(
                                          _company!.logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildPlaceholderLogo(),
                                  ),

                                // Company name in bold.
                                Text(
                                  _company!.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),

                                const SizedBox(height: 4),

                                // Location information.
                                Row(
                                  children: <Widget>[
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      _company!.location,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Description if available.
                                if (_company!.description != null && _company!.description!.isNotEmpty)
                                  Text(
                                    _company!.description!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assigned salesperson card (if available)
            if (widget.linking.assignedSalesmanUserId != null) ...[
              Text(
                'Assigned Salesperson',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: _salesperson != null
                      ? () => _navigateToUserProfile(_salesperson!)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoadingSalesperson
                        ? const Center(child: CircularProgressIndicator())
                        : _salesperson == null
                            ? const Text('Failed to load salesperson')
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_salesperson!.firstName} ${_salesperson!.lastName}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _salesperson!.role.name.toUpperCase(),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_salesperson != null)
                                    const Icon(Icons.chevron_right),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      // Bottom buttons (only if showAcceptRejectButtons is true and status is pending, or unlink for accepted)
      bottomNavigationBar: widget.showAcceptRejectButtons && widget.linking.status == LinkingStatus.pending
          ? _buildPendingButtons()
          : widget.linking.status == LinkingStatus.accepted && _canUnlink()
              ? _buildUnlinkButton()
              : null,
    );
  }

  // Build placeholder logo with gray background and icon.
  Widget _buildPlaceholderLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.business,
        size: 32,
        color: Colors.grey,
      ),
    );
  }

  // Build buttons for pending status.
  Widget _buildPendingButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: ButtonSizes.mdFill,
                ),
                onPressed: _isProcessing ? null : _handleReject,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Reject'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: ButtonSizes.mdFill,
                ),
                onPressed: _isProcessing ? null : _handleAccept,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Accept'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build unlink button for accepted status.
  Widget _buildUnlinkButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            minimumSize: ButtonSizes.mdFill,
          ),
          onPressed: _isProcessing ? null : _handleUnlink,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Unlink'),
        ),
      ),
    );
  }
}

/// User profile detail view that accepts a user object.
class UserProfileDetailView extends ConsumerWidget {
  const UserProfileDetailView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userProfileTitle)),
      body: ListView(
        children: <Widget>[
          _InfoTile(label: l10n.firstName, value: user.firstName),
          _InfoTile(label: l10n.lastName, value: user.lastName),
          _InfoTile(label: l10n.email, value: user.email),
          _InfoTile(label: l10n.phoneNumber, value: user.phoneNumber),
          _InfoTile(label: l10n.userRole, value: user.role.name),
          _InfoTile(label: l10n.userLocale, value: user.locale),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isEmpty ? '—' : value),
    );
  }
}

