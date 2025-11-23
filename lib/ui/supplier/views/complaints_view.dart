import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/complaint.dart';
import '../../../data/models/company.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/complaints/complaint_detail_view.dart';
import '../../shared/complaints/complaint_list_item.dart';

/// Supplier complaints view - shows different content based on user role.
class SupplierComplaintsView extends ConsumerStatefulWidget {
  const SupplierComplaintsView({super.key});

  @override
  ConsumerState<SupplierComplaintsView> createState() => _SupplierComplaintsViewState();
}

class _SupplierComplaintsViewState extends ConsumerState<SupplierComplaintsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  // Salesman data
  List<Complaint> _assignedComplaints = [];

  // Manager data
  List<Complaint> _escalatedComplaints = [];
  List<Complaint> _managedComplaints = [];
  List<Complaint> _allComplaints = [];
  List<Complaint> _linkingsComplaints = [];

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;
    // 4 tabs for managers/owners: Escalated, My Managed, All Complaints, My Linkings
    final tabCount = (appUser?.role == UserRole.manager || appUser?.role == UserRole.owner) ? 4 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(complaintRepositoryProvider);
      final userState = ref.read(userProfileProvider);
      final appUser = userState.value;

      if (appUser == null) {
        throw Exception('User not found');
      }

      if (appUser.role == UserRole.staff) {
        // Salesman: load assigned complaints
        _assignedComplaints = await repository.getAssignedComplaints();
      } else if (appUser.role == UserRole.manager || appUser.role == UserRole.owner) {
        // Manager/Owner: load escalated and managed complaints
        try {
          _escalatedComplaints = await repository.getEscalatedComplaints();
        } catch (e) {
          debugPrint('Error loading escalated complaints: $e');
        }
        try {
          _managedComplaints = await repository.getMyManagedComplaints();
        } catch (e) {
          debugPrint('Error loading managed complaints: $e');
        }
        // Load all company complaints
        try {
          _allComplaints = await repository.getCompanyComplaints();
        } catch (e) {
          debugPrint('Error loading all company complaints: $e');
        }
        // Load complaints for orders from user's linkings
        try {
          _linkingsComplaints = await _loadLinkingsComplaints();
        } catch (e) {
          debugPrint('Error loading linkings complaints: $e');
        }
      }

      // Note: Owner can see escalated and managed complaints like managers
      // If needed, we can add a separate owner view later

      if (mounted) {
        setState(() {
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

  // Load complaints for orders from user's linkings
  Future<List<Complaint>> _loadLinkingsComplaints() async {
    try {
      final userState = ref.read(userProfileProvider);
      final appUser = userState.value;
      if (appUser?.companyId == null) return [];

      final linkingRepo = ref.read(linkingRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);
      final complaintRepo = ref.read(complaintRepositoryProvider);

      // Get all linkings for the user's company
      final linkings = await linkingRepo.getLinkingsByCompany(
        companyId: appUser!.companyId!,
      );

      // Get all orders from these linkings
      final List<int> orderIds = [];
      for (final linking in linkings) {
        if (linking.linkingId == null) continue;
        try {
          final orders = await orderRepo.getOrdersByLinking(
            linkingId: linking.linkingId!,
          );
          orderIds.addAll(orders.map((o) => o.orderId));
        } catch (e) {
          debugPrint('Error loading orders for linking ${linking.linkingId}: $e');
        }
      }

      // Get complaints for these orders
      final List<Complaint> complaints = [];
      for (final orderId in orderIds) {
        try {
          final complaint = await complaintRepo.getComplaintByOrderId(
            orderId: orderId,
          );
          if (complaint != null) {
            complaints.add(complaint);
          }
        } catch (e) {
          // Order might not have a complaint, which is fine
          debugPrint('No complaint for order $orderId or error: $e');
        }
      }

      return complaints;
    } catch (e) {
      debugPrint('Error loading linkings complaints: $e');
      return [];
    }
  }

  // Load consumer company for a complaint
  Future<Company?> _loadConsumerCompany(Complaint complaint) async {
    try {
      // First get the order to find linking_id
      final orderRepo = ref.read(orderRepositoryProvider);
      final order = await orderRepo.getOrder(orderId: complaint.orderId);

      // Get linking to find consumer company
      final linkingRepo = ref.read(linkingRepositoryProvider);
      final userState = ref.read(userProfileProvider);
      final appUser = userState.value;

      if (appUser?.companyId == null) return null;

      final linkings = await linkingRepo.getLinkingsByCompany(
        companyId: appUser!.companyId!,
      );
      final linkingList = linkings
          .where((l) => l.linkingId == order.linkingId)
          .toList();

      if (linkingList.isEmpty) return null;

      final linking = linkingList.first;
      final companyRepo = ref.read(companyRepositoryProvider);
      return await companyRepo.getCompany(companyId: linking.consumerCompanyId);
    } catch (e) {
      debugPrint('Error loading consumer company: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final appUser = userState.value;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${l10n.commonError}: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComplaints,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (appUser == null) {
      return Center(child: Text(l10n.supplierComplaintsUserNotFound));
    }

    // Salesman view
    if (appUser.role == UserRole.staff) {
      return _buildSalesmanView();
    }

    // Manager/Owner view with tabs
    if (appUser.role == UserRole.manager || appUser.role == UserRole.owner) {
      return _buildManagerView();
    }

    return Center(child: Text(l10n.supplierComplaintsUnknownRole));
  }

  // Build salesman view
  Widget _buildSalesmanView() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: _assignedComplaints.isEmpty
          ? Center(
              child: Text(l10n.supplierComplaintsNoAssigned),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _assignedComplaints.length,
              itemBuilder: (context, index) {
                final complaint = _assignedComplaints[index];
                return FutureBuilder<Company?>(
                  future: _loadConsumerCompany(complaint),
                  builder: (context, snapshot) {
                    return ComplaintListItem(
                      complaint: complaint,
                      consumerCompany: snapshot.data,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ComplaintDetailView(
                              complaintId: complaint.complaintId,
                            ),
                          ),
                        );
                        // Refresh list when returning from detail view
                        _loadComplaints();
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  // Build manager view with tabs
  Widget _buildManagerView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.supplierComplaintsEscalated),
            Tab(text: l10n.supplierComplaintsMyManaged),
            Tab(text: l10n.supplierComplaintsAllComplaints),
            Tab(text: l10n.supplierComplaintsMyLinkings),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Escalated complaints tab
              RefreshIndicator(
                onRefresh: _loadComplaints,
                child: _escalatedComplaints.isEmpty
                    ? Center(
                        child: Text(l10n.supplierComplaintsNoEscalated),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _escalatedComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _escalatedComplaints[index];
                          return FutureBuilder<Company?>(
                            future: _loadConsumerCompany(complaint),
                            builder: (context, snapshot) {
                              return ComplaintListItem(
                                complaint: complaint,
                                consumerCompany: snapshot.data,
                                showQuickAction: true,
                                quickActionLabel: l10n.supplierComplaintsClaim,
                                onQuickAction: () async {
                                  // Navigate to detail view where they can claim
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ComplaintDetailView(
                                        complaintId: complaint.complaintId,
                                      ),
                                    ),
                                  );
                                  // Refresh list when returning
                                  _loadComplaints();
                                },
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ComplaintDetailView(
                                        complaintId: complaint.complaintId,
                                      ),
                                    ),
                                  );
                                  // Refresh list when returning
                                  _loadComplaints();
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              // My managed complaints tab
              RefreshIndicator(
                onRefresh: _loadComplaints,
                child: _managedComplaints.isEmpty
                    ? Center(
                        child: Text(l10n.supplierComplaintsNoManaged),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _managedComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _managedComplaints[index];
                          return FutureBuilder<Company?>(
                            future: _loadConsumerCompany(complaint),
                            builder: (context, snapshot) {
                              return ComplaintListItem(
                                complaint: complaint,
                                consumerCompany: snapshot.data,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ComplaintDetailView(
                                        complaintId: complaint.complaintId,
                                      ),
                                    ),
                                  );
                                  // Refresh list when returning
                                  _loadComplaints();
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              // All complaints tab
              RefreshIndicator(
                onRefresh: _loadComplaints,
                child: _allComplaints.isEmpty
                    ? Center(
                        child: Text(l10n.supplierComplaintsNoComplaints),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _allComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _allComplaints[index];
                          return FutureBuilder<Company?>(
                            future: _loadConsumerCompany(complaint),
                            builder: (context, snapshot) {
                              return ComplaintListItem(
                                complaint: complaint,
                                consumerCompany: snapshot.data,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ComplaintDetailView(
                                        complaintId: complaint.complaintId,
                                      ),
                                    ),
                                  );
                                  // Refresh list when returning
                                  _loadComplaints();
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              // My linkings complaints tab
              RefreshIndicator(
                onRefresh: _loadComplaints,
                child: _linkingsComplaints.isEmpty
                    ? Center(
                        child: Text(l10n.supplierComplaintsNoLinkingsComplaints),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _linkingsComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _linkingsComplaints[index];
                          return FutureBuilder<Company?>(
                            future: _loadConsumerCompany(complaint),
                            builder: (context, snapshot) {
                              return ComplaintListItem(
                                complaint: complaint,
                                consumerCompany: snapshot.data,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ComplaintDetailView(
                                        complaintId: complaint.complaintId,
                                      ),
                                    ),
                                  );
                                  // Refresh list when returning
                                  _loadComplaints();
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

