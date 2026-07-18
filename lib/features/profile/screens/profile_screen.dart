import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<int> _activeListingsCountFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _activeListingsCountFuture = _fetchActiveListingsCount();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<int> _fetchActiveListingsCount() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('listings')
        .select('id')
        .eq('seller_id', userId)
        .eq('status', 'active');
    return (response as List).length;
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You\'ll need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await supabase.auth.signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/profile',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profile = snapshot.data;
                if (profile == null) {
                  return Center(
                    child: Text(
                      'Could not load profile',
                      style: AppTextStyles.body,
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileHeader(profile),
                      const SizedBox(height: 24),
                      _menuSection(context),
                      const SizedBox(height: 24),
                      _logoutButton(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(Map<String, dynamic> profile) {
    final username = profile['username'] ?? 'Unknown';
    final fullName = profile['full_name'] ?? '';
    final bio = profile['bio'] ?? '';
    final rating = (profile['rating'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse(profile['created_at'] ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.divider,
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? Icon(Icons.person, size: 40, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            fullName.isNotEmpty ? fullName : username,
            style: AppTextStyles.title,
          ),
          Text('@$username', style: AppTextStyles.small),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(bio, style: AppTextStyles.small, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (rating != null) ...[
                Icon(Icons.star, size: 16, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (createdAt != null)
                Text(
                  'Joined ${_monthYear(createdAt)}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: _activeListingsCountFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count active listing${count == 1 ? '' : 's'}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.nileBlue,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthYear(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _menuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _menuTile(
            context,
            Icons.storefront_outlined,
            'My Listings',
            () => context.push('/my-listings'),
          ),
          _divider(),
          _menuTile(
            context,
            Icons.favorite_border,
            'Saved Listings',
            () => context.push('/saved'),
          ),
          _divider(),
          _menuTile(
            context,
            Icons.edit_outlined,
            'Edit Profile',
            () => context.push('/edit-profile'),
          ),
          _divider(),
          _menuTile(
            context,
            Icons.settings_outlined,
            'Settings',
            () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.border);
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _logoutButton() {
    return OutlinedButton.icon(
      onPressed: _handleLogout,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Log Out', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
      ),
    );
  }
}
