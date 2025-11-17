import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'dart:developer';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/providers/user_profile_provider.dart';
import 'staff_member_form_view.dart';

// Provider to load staff (all users of the current company).
final staffListProvider = FutureProvider<List<AppUser>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.listUsers();
});

// Stable family provider to load a specific user by id (avoids recreation loops).
final userByIdProvider = FutureProvider.family<AppUser, int>((ref, userId) async {
  final repo = ref.read(userRepositoryProvider);
  try {
    final user = await repo.getUserById(userId: userId);
    return user;
  } catch (e, st) {
    log('userByIdProvider error for id=$userId -> $e', stackTrace: st);
    rethrow;
  }
});

class StaffManagementView extends ConsumerWidget {
  const StaffManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final staffAsync = ref.watch(staffListProvider);
    final currentUser = ref.watch(userProfileProvider).asData?.value;
    final bool canManageStaff = currentUser != null &&
        (currentUser.role == UserRole.owner ||
            currentUser.role == UserRole.manager);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffManagementTitle)),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(staffListProvider);
                  },
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (users) {
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final user = users[index];
              final String fullName = '${user.firstName} ${user.lastName}'.trim();
              final String roleLiteral = user.role.name; // owner/manager/staff

              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(fullName.isEmpty ? user.email : fullName),
                subtitle: Text(roleLiteral),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (user.id == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _UserDetailByIdView(userId: user.id!),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: canManageStaff
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StaffMemberFormView(),
                  ),
                );
                // Refresh staff list after returning from creation screen.
                ref.invalidate(staffListProvider);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Helper function to check if current user's role is higher than target user's role.
// Role hierarchy: owner > manager > staff
bool _isRoleHigher(UserRole currentRole, UserRole targetRole) {
  if (currentRole == UserRole.owner) {
    return targetRole != UserRole.owner;
  } else if (currentRole == UserRole.manager) {
    return targetRole == UserRole.staff;
  } else {
    return false; // staff cannot manage anyone
  }
}

// Simple wrapper to reuse user profile layout but load by id.
class _UserDetailByIdView extends ConsumerStatefulWidget {
  const _UserDetailByIdView({required this.userId});
  final int userId;

  @override
  ConsumerState<_UserDetailByIdView> createState() => _UserDetailByIdViewState();
}

class _UserDetailByIdViewState extends ConsumerState<_UserDetailByIdView> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userByIdProvider(widget.userId));
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(userProfileProvider).asData?.value;

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        log('User detail load failed for id=${widget.userId}: $e');
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.refresh(userByIdProvider(widget.userId)),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (user) {
        // Minimal detail using the same info tiles style.
        final String fullName = '${user.firstName} ${user.lastName}'.trim();

        // Check if current user can delete this user.
        final bool canDelete = currentUser != null &&
            _isRoleHigher(currentUser.role, user.role) &&
            currentUser.id != user.id; // Cannot delete yourself

        return Scaffold(
          appBar: AppBar(
            title: Text(fullName.isEmpty ? user.email : fullName),
            actions: <Widget>[
              // Delete button - shows confirmation dialog
              if (canDelete)
                IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  onPressed: _isDeleting ? null : () => _handleDelete(context, l10n, user),
                ),
            ],
          ),
          body: ListView(
            children: <Widget>[
              ListTile(title: Text(l10n.firstName), subtitle: Text(user.firstName.isEmpty ? '—' : user.firstName)),
              ListTile(title: Text(l10n.lastName), subtitle: Text(user.lastName.isEmpty ? '—' : user.lastName)),
              ListTile(title: Text(l10n.email), subtitle: Text(user.email.isEmpty ? '—' : user.email)),
              ListTile(title: Text(l10n.phoneNumber), subtitle: Text(user.phoneNumber.isEmpty ? '—' : user.phoneNumber)),
              ListTile(title: Text(l10n.userRole), subtitle: Text(user.role.name)),
              ListTile(title: Text(l10n.userLocale), subtitle: Text(user.locale.isEmpty ? '—' : user.locale)),
            ],
          ),
        );
      },
    );
  }

  // Handle user deletion with confirmation dialog.
  Future<void> _handleDelete(BuildContext context, AppLocalizations l10n, AppUser user) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.staffDeleteUserTitle),
        content: Text(l10n.staffDeleteUserMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    // If user cancelled, do nothing
    if (confirmed != true) {
      return;
    }

    // Ensure user has an ID for deletion
    if (user.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.staffDeleteUserErrorGeneric('User ID is missing')),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final UserRepository repository = ref.read(userRepositoryProvider);

      await repository.deleteUser(userId: user.id!);

      // Invalidate the user detail provider
      ref.invalidate(userByIdProvider(widget.userId));

      // Invalidate the staff list provider to refresh the list
      ref.invalidate(staffListProvider);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.staffDeleteUserSuccess),
          ),
        );

        // Navigate back to previous screen
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.staffDeleteUserErrorGeneric(error.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}


