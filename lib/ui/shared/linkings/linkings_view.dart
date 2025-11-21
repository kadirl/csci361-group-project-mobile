import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/user_profile_provider.dart';
import '../../../../data/models/company.dart';
import '../../../../data/models/linking.dart';
import '../../../../data/repositories/company_repository.dart';
import '../../../../data/repositories/linking_repository.dart';
import 'linking_detail_view.dart';

/// Shared linkings view with tabs for different linking statuses.
///
/// [showAcceptRejectButtons] - If true, shows accept/reject buttons in cards and detail view (supplier view).
/// [companyIdToLoad] - Function that returns the company ID to load for each linking (supplierCompanyId for consumer, consumerCompanyId for supplier).
class LinkingsView extends ConsumerStatefulWidget {
  const LinkingsView({
    super.key,
    this.showAcceptRejectButtons = false,
    required this.companyIdToLoad,
  });

  final bool showAcceptRejectButtons;
  final int Function(Linking linking) companyIdToLoad;

  @override
  ConsumerState<LinkingsView> createState() => _LinkingsViewState();
}

class _LinkingsViewState extends ConsumerState<LinkingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cache the loaded linkings to avoid reloading on every rebuild.
  List<Linking>? _cachedLinkings;
  bool _isLoadingLinkings = false;
  String? _linkingsError;

  // Cache company objects by company ID to avoid repeated fetches.
  final Map<int, Company> _companiesCache = {};

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with 4 tabs for the 4 statuses.
    _tabController = TabController(length: 4, vsync: this);

    // Load linkings once when widget initializes.
    _loadLinkings();
  }

  @override
  void dispose() {
    // Dispose the tab controller to avoid memory leaks.
    _tabController.dispose();
    super.dispose();
  }

  // Load linkings from the repository.
  Future<void> _loadLinkings() async {
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;

    if (appUser?.companyId == null) {
      return;
    }

    setState(() {
      _isLoadingLinkings = true;
      _linkingsError = null;
    });

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      final linkings = await linkingRepo.getLinkingsByCompany(
        companyId: appUser!.companyId!,
      );

      // Load companies for all unique companies.
      await _loadCompanies(linkings);

      if (mounted) {
        setState(() {
          _cachedLinkings = linkings;
          _isLoadingLinkings = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _linkingsError = error.toString();
          _isLoadingLinkings = false;
        });
      }
    }
  }

  // Load companies for all unique companies in the linkings.
  Future<void> _loadCompanies(List<Linking> linkings) async {
    final companyRepo = ref.read(companyRepositoryProvider);
    final Set<int> uniqueCompanyIds = linkings
        .map((linking) => widget.companyIdToLoad(linking))
        .where((id) => id > 0 && !_companiesCache.containsKey(id))
        .toSet();

    for (final companyId in uniqueCompanyIds) {
      try {
        final company = await companyRepo.getCompany(companyId: companyId);
        _companiesCache[companyId] = company;
      } catch (e) {
        // If fetching fails, we can't cache a partial company easily without a proper model,
        // but we can handle the missing company in the UI.
        debugPrint('Failed to load company $companyId: $e');
      }
    }
  }

  // Get company from cache.
  Company? _getCompany(int companyId) {
    return _companiesCache[companyId];
  }

  // Filter linkings by status.
  List<Linking> _filterLinkingsByStatus(LinkingStatus status) {
    if (_cachedLinkings == null) {
      return [];
    }
    return _cachedLinkings!
        .where((linking) => linking.status == status)
        .toList();
  }

  // Format date string to human-readable format.
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      // Try parsing ISO 8601 format first
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar at the top of the body
        TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            Tab(
              child: Badge(
                alignment: Alignment.centerRight,
                offset: const Offset(8, -7),
                backgroundColor: Colors.grey,
                isLabelVisible: _filterLinkingsByStatus(
                  LinkingStatus.pending,
                ).isNotEmpty,
                label: Text(
                  '${_filterLinkingsByStatus(LinkingStatus.pending).length}',
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Pending'),
                ),
              ),
            ),
            Tab(
              child: Badge(
                alignment: Alignment.centerRight,
                offset: const Offset(8, -7),
                backgroundColor: Colors.grey,
                isLabelVisible: _filterLinkingsByStatus(
                  LinkingStatus.accepted,
                ).isNotEmpty,
                label: Text(
                  '${_filterLinkingsByStatus(LinkingStatus.accepted).length}',
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Accepted'),
                ),
              ),
            ),
            Tab(
              child: Badge(
                alignment: Alignment.centerRight,
                offset: const Offset(8, -7),
                backgroundColor: Colors.grey,
                isLabelVisible: _filterLinkingsByStatus(
                  LinkingStatus.rejected,
                ).isNotEmpty,
                label: Text(
                  '${_filterLinkingsByStatus(LinkingStatus.rejected).length}',
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Rejected'),
                ),
              ),
            ),
            Tab(
              child: Badge(
                alignment: Alignment.centerRight,
                offset: const Offset(8, -7),
                backgroundColor: Colors.grey,
                isLabelVisible: _filterLinkingsByStatus(
                  LinkingStatus.unlinked,
                ).isNotEmpty,
                label: Text(
                  '${_filterLinkingsByStatus(LinkingStatus.unlinked).length}',
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Unlinked'),
                ),
              ),
            ),
          ],
        ),
        // Content area with TabBarView
        Expanded(
          child: _isLoadingLinkings
              ? const Center(child: CircularProgressIndicator())
              : _linkingsError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_linkingsError'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLinkings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLinkingsList(
                      _filterLinkingsByStatus(LinkingStatus.pending),
                    ),
                    _buildLinkingsList(
                      _filterLinkingsByStatus(LinkingStatus.accepted),
                    ),
                    _buildLinkingsList(
                      _filterLinkingsByStatus(LinkingStatus.rejected),
                    ),
                    _buildLinkingsList(
                      _filterLinkingsByStatus(LinkingStatus.unlinked),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // Build a list of linkings for a specific status.
  Widget _buildLinkingsList(List<Linking> linkings) {
    if (linkings.isEmpty) {
      return const Center(child: Text('No linkings found'));
    }

    return ListView.builder(
      itemCount: linkings.length,
      itemBuilder: (context, index) {
        final linking = linkings[index];
        return _buildLinkingCard(linking);
      },
    );
  }

  // Build a card widget for a single linking.
  Widget _buildLinkingCard(Linking linking) {
    final companyId = widget.companyIdToLoad(linking);
    debugPrint('DEBUG: LinkingsView _buildLinkingCard');
    debugPrint(
      'DEBUG: Linking: id=${linking.linkingId}, consumer=${linking.consumerCompanyId}, supplier=${linking.supplierCompanyId}',
    );
    debugPrint('DEBUG: companyIdToLoad returned: $companyId');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          // Navigate to detail view and refresh if needed
          final result = await Navigator.of(context).push(
            MaterialPageRoute<bool>(
              builder: (_) => LinkingDetailView(
                linking: linking,
                showAcceptRejectButtons: widget.showAcceptRejectButtons,
                companyIdToLoad: companyId,
              ),
            ),
          );

          // If result is true, refresh the linkings
          if (result == true && mounted) {
            _loadLinkings();
          }
        },
        child: ListTile(
          leading: _buildCompanyLogo(_getCompany(companyId)),
          title: Text(_getCompany(companyId)?.name ?? 'Company #$companyId'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (linking.message != null) ...[
                const SizedBox(height: 4),
                Text('Message: ${linking.message}'),
              ],
              if (linking.createdAt != null) ...[
                const SizedBox(height: 4),
                Text('Created: ${_formatDate(linking.createdAt)}'),
              ],
            ],
          ),
          trailing: widget.showAcceptRejectButtons
              ? _buildActionButtons(linking)
              : null,
          isThreeLine: true,
        ),
      ),
    );
  }

  // Build action buttons based on linking status (only for supplier view).
  Widget? _buildActionButtons(Linking linking) {
    // Only show actions for pending linkings (supplier can accept/reject).
    if (linking.status != LinkingStatus.pending) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _handleAcceptLinking(linking),
          tooltip: 'Accept',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _handleRejectLinking(linking),
          tooltip: 'Reject',
        ),
      ],
    );
  }

  // Handle accepting a linking.
  Future<void> _handleAcceptLinking(Linking linking) async {
    if (linking.linkingId == null) {
      return;
    }

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.acceptLinking(linkingId: linking.linkingId!);

      // Reload linkings to reflect the change.
      await _loadLinkings();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Linking accepted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting linking: $error')),
        );
      }
    }
  }

  // Handle rejecting a linking.
  Future<void> _handleRejectLinking(Linking linking) async {
    if (linking.linkingId == null) {
      return;
    }

    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.rejectLinking(linkingId: linking.linkingId!);

      // Reload linkings to reflect the change.
      await _loadLinkings();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Linking rejected')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting linking: $error')),
        );
      }
    }
  }

  // Build company logo or placeholder.
  Widget _buildCompanyLogo(Company? company) {
    if (company?.logoUrl != null && company!.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              company.logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
            ),
          ),
        ),
      );
    }
    return _buildPlaceholderLogo();
  }

  // Build placeholder logo with gray background and icon.
  Widget _buildPlaceholderLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.business, size: 28, color: Colors.grey),
    );
  }
}

