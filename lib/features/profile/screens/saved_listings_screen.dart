import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/widgets/listing_card.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';
import 'package:nilemarket/core/supabase/saved_listings_repository.dart';

class SavedListingsScreen extends StatefulWidget {
  const SavedListingsScreen({super.key});

  @override
  State<SavedListingsScreen> createState() => _SavedListingsScreenState();
}

class _SavedListingsScreenState extends State<SavedListingsScreen> {
  late Future<List<Map<String, dynamic>>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _savedFuture = _fetchSavedListings();
  }

  Future<List<Map<String, dynamic>>> _fetchSavedListings() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('saved_listings')
        .select('listing_id, listings(*, profiles(username, rating))')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return (response as List)
        .where(
          (row) => row['listings'] != null,
        ) // guard against a deleted listing
        .map((row) => row['listings'] as Map<String, dynamic>)
        .toList();
  }

  Future<void> _unsave(String listingId) async {
    await SavedListingsRepository.unsave(listingId);
    setState(() => _savedFuture = _fetchSavedListings());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 2;
    final cardAspectRatio = isDesktop ? 0.7 : 0.56;

    return AppShell(
      currentRoute: '/saved',
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Saved Listings', style: AppTextStyles.heading3),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _savedFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final listings = snapshot.data ?? [];
                      if (listings.isEmpty) {
                        return _emptyState(context);
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: cardAspectRatio,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          final listing = listings[index];
                          final id = listing['id'] as String;
                          return ListingCard(
                            imageUrl:
                                (listing['images'] as List?)?.isNotEmpty == true
                                ? listing['images'][0]
                                : '',
                            title: listing['title'] ?? '',
                            price: (listing['price'] as num).toDouble(),
                            sellerName: listing['profiles']?['username'],
                            sellerRating:
                                (listing['profiles']?['rating'] as num?)
                                    ?.toDouble(),
                            category: listing['category'],
                            condition: listing['condition'],
                            createdAt: DateTime.tryParse(
                              listing['created_at'] ?? '',
                            ),
                            isSaved: true,
                            onSaveTap: () => _unsave(id),
                            onTap: () => context.push('/listing/$id'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No saved listings', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Items you save will show up here', style: AppTextStyles.small),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Browse Listings'),
          ),
        ],
      ),
    );
  }
}
