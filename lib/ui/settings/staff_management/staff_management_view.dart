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

// Simple wrapper to reuse user profile layout but load by id.
class _UserDetailByIdView extends ConsumerWidget {
  const _UserDetailByIdView({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final l10n = AppLocalizations.of(context)!;

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        log('User detail load failed for id=$userId: $e');
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
                    onPressed: () => ref.refresh(userByIdProvider(userId)),
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
        return Scaffold(
          appBar: AppBar(title: Text(fullName.isEmpty ? user.email : fullName)),
          body: ListView(
            children: <Widget>[
              ListTile(title: Text(l10n.firstName), subtitle: Text(user.firstName.isEmpty ? '—' : user.firstName)),
              ListTile(title: Text(l10n.lastName), subtitle: Text(user.lastName.isEmpty ? '—' : user.lastName)),
              ListTile(title: Text(l10n.email), subtitle: Text(user.email.isEmpty ? '—' : user.email)),
              ListTile(title: Text(l10n.phoneNumber), subtitle: Text(user.phoneNumber.isEmpty ? '—' : user.phoneNumber)),
              ListTile(title: Text(l10n.userRole), subtitle: Text(user.role.name)),
              ListTile(title: Text(l10n.userLocale), subtitle: Text(user.locale.isEmpty ? '—' : user.locale)),
              const Divider(height: 0),
              // Placeholder Edit entry point (non-functional for now)
              const ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit (coming soon)'),
              ),
            ],
          ),
        );
      },
    );
  }
}


