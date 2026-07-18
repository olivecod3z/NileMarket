import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/widgets/listing_card.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _listingsFuture = _fetchSellerListings();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    return await supabase
        .from('profiles')
        .select()
        .eq('id', widget.sellerId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> _fetchSellerListings() async {
    final response = await supabase
        .from('listings')
        .select()
        .eq('seller_id', widget.sellerId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 2;
    final cardAspectRatio = isDesktop ? 0.74 : 0.62;

    return AppShell(
      currentRoute: '/seller/${widget.sellerId}',
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileSnapshot.hasError || profileSnapshot.data == null) {
            return _notFoundState(context);
          }

          final profile = profileSnapshot.data!;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _backButton(context), // now outside the centered constraint
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _profileHeader(profile)),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Text(
                                'Active Listings',
                                style: AppTextStyles.title,
                              ),
                            ),
                          ),
                          _listingsGrid(crossAxisCount, cardAspectRatio),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notFoundState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('Seller not found', style: AppTextStyles.title),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }

  Widget _profileHeader(Map<String, dynamic> profile) {
    final username = profile['username'] ?? 'Unknown';
    final fullName = profile['full_name'] ?? '';
    final bio = profile['bio'] ?? '';
    final rating = (profile['rating'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse(profile['created_at'] ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.divider,
                child: Icon(
                  Icons.person,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : username,
                      style: AppTextStyles.title,
                    ),
                    Text('@$username', style: AppTextStyles.small),
                    const SizedBox(height: 4),
                    Row(
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
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(bio, style: AppTextStyles.body),
          ],
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

  Widget _listingsGrid(int crossAxisCount, double childAspectRatio) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('No active listings', style: AppTextStyles.body),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final listing = listings[index];
              final id = listing['id'] as String;
              return ListingCard(
                imageUrl: (listing['images'] as List?)?.isNotEmpty == true
                    ? listing['images'][0]
                    : '',
                title: listing['title'] ?? '',
                price: (listing['price'] as num).toDouble(),
                category: listing['category'],
                condition: listing['condition'],
                createdAt: DateTime.tryParse(listing['created_at'] ?? ''),
                onTap: () => context.push('/listing/$id'),
              );
            }, childCount: listings.length),
          ),
        );
      },
    );
  }
}
