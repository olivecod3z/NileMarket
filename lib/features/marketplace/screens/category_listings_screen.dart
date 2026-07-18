import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/widgets/listing_card.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class CategoryListingsScreen extends StatefulWidget {
  final String category;
  const CategoryListingsScreen({super.key, required this.category});

  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchListings();
  }

  Future<List<Map<String, dynamic>>> _fetchListings() async {
    final response = await supabase
        .from('listings')
        .select('*, profiles(username, rating)')
        .eq('status', 'active')
        .eq('category', widget.category)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 2;
    final cardAspectRatio = isDesktop ? 0.7 : 0.56;

    return AppShell(
      currentRoute: '/category/${widget.category}',
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/categories');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(widget.category, style: AppTextStyles.heading3),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final listings = snapshot.data ?? [];
                      if (listings.isEmpty) {
                        return Center(
                          child: Text(
                            'No listings in this category yet',
                            style: AppTextStyles.body,
                          ),
                        );
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
}
