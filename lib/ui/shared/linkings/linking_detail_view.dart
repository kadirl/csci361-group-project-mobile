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
import '../chat/chat_view.dart';

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
  AppUser? _requester;
  bool _isLoadingCompany = false;
  bool _isLoadingSalesperson = false;
  bool _isLoadingRequester = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
    _loadSalespersonData();
    _loadRequesterData();
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

  // Load requester information (consumer side contact person).
  Future<void> _loadRequesterData() async {
    if (widget.linking.requestedByUserId == 0) {
      return;
    }

    setState(() {
      _isLoadingRequester = true;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getUserById(userId: widget.linking.requestedByUserId);
      
      if (mounted) {
        setState(() {
          _requester = user;
          _isLoadingRequester = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRequester = false;
        });
      }
    }
  }

  // Format date string to human-readable format.
  String _formatDate(String? dateString, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dateString == null || dateString.isEmpty) {
      return l10n.commonNA;
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

      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkingsAcceptedSuccess)),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.linkingsAcceptError(error.toString()))),
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

      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkingsRejectedSuccess)),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.linkingsRejectError(error.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.linkingsUnlinkTitle),
        content: Text(l10n.linkingsUnlinkMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.linkingsUnlink),
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
          SnackBar(content: Text(l10n.linkingsUnlinkedSuccess)),
        );
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkingsUnlinkError(error.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.linkingsDetailsTitle),
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
                  '${l10n.orderLinking} #${widget.linking.linkingId ?? l10n.commonNA}',
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
              l10n.linkingsCreated(_formatDate(widget.linking.createdAt, context)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Company card
            Text(
              l10n.companiesCompany,
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
                          ? Text(l10n.linkingsFailedToLoadCompany)
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

            // Consumer side contact person (requester)
            if (widget.linking.requestedByUserId != 0) ...[
              Text(
                l10n.linkingsConsumerContact,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: _requester != null
                      ? () => _navigateToUserProfile(_requester!)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoadingRequester
                        ? const Center(child: CircularProgressIndicator())
                        : _requester == null
                            ? Text(l10n.linkingsFailedToLoadContactPerson)
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_requester!.firstName} ${_requester!.lastName}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _requester!.role.name.toUpperCase(),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_requester != null)
                                    const Icon(Icons.chevron_right),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Supplier side assigned salesperson (if available)
            if (widget.linking.assignedSalesmanUserId != null) ...[
              Text(
                l10n.linkingsSupplierContact,
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
                            ? Text(l10n.linkingsFailedToLoadSalesperson)
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

            // Chat button (only for accepted linkings)
            if (widget.linking.status == LinkingStatus.accepted && widget.linking.linkingId != null) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatView(
                        linkingId: widget.linking.linkingId,
                        linking: widget.linking,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: Text(l10n.linkingsOpenChat),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
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
    final l10n = AppLocalizations.of(context)!;
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
                    : Text(l10n.linkingsReject),
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
                    : Text(l10n.linkingsAccept),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build unlink button for accepted status.
  Widget _buildUnlinkButton() {
    final l10n = AppLocalizations.of(context)!;
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
              : Text(l10n.linkingsUnlink),
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

