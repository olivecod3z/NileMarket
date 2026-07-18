import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/utils/formatters.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchMyListings();
  }

  Future<List<Map<String, dynamic>>> _fetchMyListings() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('listings')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  void _refresh() {
    setState(() => _listingsFuture = _fetchMyListings());
  }

  Future<void> _markAsSold(String listingId) async {
    try {
      await supabase
          .from('listings')
          .update({'status': 'sold'})
          .eq('id', listingId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marked as sold')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Future<void> _deleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('listings').delete().eq('id', listingId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/my-listings',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('My Listings', style: AppTextStyles.heading3),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final listings = snapshot.data ?? [];
                      if (listings.isEmpty) {
                        return _emptyState(context);
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: listings.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _listingRow(listings[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No listings yet', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Start selling to see them here', style: AppTextStyles.small),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/create-listing'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Your First Listing'),
          ),
        ],
      ),
    );
  }

  Widget _listingRow(Map<String, dynamic> listing) {
    final id = listing['id'] as String;
    final status = listing['status'] ?? 'active';
    final images = (listing['images'] as List?)?.cast<String>() ?? [];
    final viewCount = listing['view_count'] ?? 0;
    final saveCount = listing['save_count'] ?? 0;
    final contactCount = listing['contact_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: images.isNotEmpty
                ? Image.network(
                    images[0],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AppColors.divider,
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing['title'] ?? '',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency((listing['price'] as num).toDouble()),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.marketplaceGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '👀 $viewCount   ❤️ $saveCount   💬 $contactCount',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.push('/edit-listing/$id'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Edit'),
                    ),
                    if (status == 'active')
                      TextButton(
                        onPressed: () => _markAsSold(id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Mark as Sold'),
                      ),
                    TextButton(
                      onPressed: () => _deleteListing(id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'sold' => AppColors.textSecondary,
      'draft' => AppColors.warning,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
