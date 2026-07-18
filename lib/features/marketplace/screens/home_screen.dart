import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/constants/app_categories.dart';
import 'package:nilemarket/core/supabase/saved_listings_repository.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/listing_card.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;
  String _selectedType = 'goods'; // 'goods' or 'services'
  String? _selectedCategory;
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  Set<String> _savedListingIds = {};

  List<CategoryItem> get _currentCategories => _selectedType == 'goods'
      ? homeFeaturedGoodsCategories
      : homeFeaturedServicesCategories;

  // Placeholder ad banners — real ad/promo system is a later feature
  final List<Map<String, String>> _banners = [
    {
      'title': 'Welcome to NileMarket',
      'subtitle': 'Buy & sell within your campus',
    },
    {
      'title': 'List your first item',
      'subtitle': 'Tap the + button to get started',
    },
    {
      'title': 'Verified students only',
      'subtitle': 'Trade safely with your peers',
    },
  ];

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchListings();
    _loadSavedIds();
    _startBannerAutoScroll();
  }

  Future<void> _loadSavedIds() async {
    final ids = await SavedListingsRepository.fetchSavedIds();
    if (mounted) setState(() => _savedListingIds = ids);
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final next = _currentBanner < _banners.length - 1
          ? _currentBanner + 1
          : 0;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchListings() async {
    var query = supabase
        .from('listings')
        .select('*, profiles(username, rating)')
        .eq('status', 'active')
        .eq('listing_type', _selectedType);

    if (_selectedCategory != null) {
      query = query.eq('category', _selectedCategory!);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  void _refreshListings() {
    setState(() => _listingsFuture = _fetchListings());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 2;
    final cardAspectRatio = isDesktop ? 0.74 : 0.62;

    return AppShell(
      currentRoute: '/home',
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/create-listing'),
              backgroundColor: AppColors.nileBlue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: () async => _refreshListings(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _searchBar(context)),
                  SliverToBoxAdapter(child: _bannerCarousel(context)),
                  SliverToBoxAdapter(child: _typeToggle()),
                  SliverToBoxAdapter(child: _categoriesHeader(context)),
                  SliverToBoxAdapter(child: _categoryChips()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Recent Listings',
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
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text('Search for anything...', style: AppTextStyles.small),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerCarousel(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final bannerHeight = isDesktop ? 140.0 : 100.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: bannerHeight,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (index) =>
                    setState(() => _currentBanner = index),
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(isDesktop ? 20 : 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF003D99), Color(0xFF0057D9)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner['title']!,
                          style:
                              (isDesktop
                                      ? AppTextStyles.title
                                      : AppTextStyles.subtitle)
                                  .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['subtitle']!,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final isActive = index == _currentBanner;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.nileBlue : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _toggleOption(
                'goods',
                'Goods',
                Icons.shopping_bag_outlined,
              ),
            ),
            Expanded(
              child: _toggleOption(
                'services',
                'Services',
                Icons.handyman_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleOption(String value, String label, IconData icon) {
    final isActive = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
          _selectedCategory = null;
        });
        _refreshListings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.activeBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 4),
          border: Border.all(
            color: isActive ? AppColors.nileBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.nileBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: isActive ? AppColors.nileBlue : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChips() {
    final categories = _currentCategories;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = categories[index];
            final isSelected = _selectedCategory == item.label;

            return GestureDetector(
              onTap: () {
                setState(
                  () => _selectedCategory = isSelected ? null : item.label,
                );
                _refreshListings();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.nileBlue.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.nileBlue : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.label,
                  style: AppTextStyles.small.copyWith(
                    color: isSelected
                        ? AppColors.nileBlue
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text('No listings yet', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to sell something!',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
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
                sellerName: listing['profiles']?['username'],
                sellerRating: (listing['profiles']?['rating'] as num?)
                    ?.toDouble(),
                category: listing['category'],
                condition: listing['condition'],
                createdAt: DateTime.tryParse(listing['created_at'] ?? ''),
                isSaved: _savedListingIds.contains(id),
                onSaveTap: () async {
                  final wasSaved = _savedListingIds.contains(id);
                  setState(() {
                    if (wasSaved) {
                      _savedListingIds.remove(id);
                    } else {
                      _savedListingIds.add(id);
                    }
                  });
                  try {
                    if (wasSaved) {
                      await SavedListingsRepository.unsave(id);
                    } else {
                      await SavedListingsRepository.save(id);
                    }
                  } catch (e) {
                    // revert on failure
                    if (mounted) {
                      setState(() {
                        if (wasSaved) {
                          _savedListingIds.add(id);
                        } else {
                          _savedListingIds.remove(id);
                        }
                      });
                    }
                  }
                },

                onTap: () => context.push('/listing/$id'),
              );
            }, childCount: listings.length),
          ),
        );
      },
    );
  }
}

Widget _categoriesHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Categories', style: AppTextStyles.title),
        TextButton(
          onPressed: () => context.push('/categories'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          child: Text(
            'See all →',
            style: AppTextStyles.body.copyWith(
              color: AppColors.nileBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
