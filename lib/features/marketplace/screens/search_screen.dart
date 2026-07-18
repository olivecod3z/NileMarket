import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/widgets/listing_card.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // In-memory only — resets on refresh. Persisting this (e.g. shared_preferences)
  // is a reasonable future improvement, not done here to keep scope tight.
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await supabase
          .from('listings')
          .select('*, profiles(username, rating)')
          .eq('status', 'active')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() => _results = List<Map<String, dynamic>>.from(response));
        _addToRecentSearches(query);
      }
    } catch (e) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToRecentSearches(String query) {
    _recentSearches.remove(query); // avoid duplicates
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 6) _recentSearches.removeLast();
  }

  void _searchFromRecent(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 2;
    final cardAspectRatio = isDesktop ? 0.7 : 0.56;

    return AppShell(
      currentRoute: '/search',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(),
                Expanded(child: _content(crossAxisCount, cardAspectRatio)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for anything...',
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(int crossAxisCount, double cardAspectRatio) {
    if (!_hasSearched) {
      return _recentSearchesView();
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return _noResultsView();
    }
    return _resultsGrid(crossAxisCount, cardAspectRatio);
  }

  Widget _recentSearchesView() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Text(
          'Start typing to search listings',
          style: AppTextStyles.small,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Searches', style: AppTextStyles.title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in _recentSearches)
                GestureDetector(
                  onTap: () => _searchFromRecent(term),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(term, style: AppTextStyles.small),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('No results found', style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text('Try a different search term', style: AppTextStyles.small),
        ],
      ),
    );
  }

  Widget _resultsGrid(int crossAxisCount, double cardAspectRatio) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: cardAspectRatio,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final listing = _results[index];
        final id = listing['id'] as String;
        return ListingCard(
          imageUrl: (listing['images'] as List?)?.isNotEmpty == true
              ? listing['images'][0]
              : '',
          title: listing['title'] ?? '',
          price: (listing['price'] as num).toDouble(),
          sellerName: listing['profiles']?['username'],
          sellerRating: (listing['profiles']?['rating'] as num?)?.toDouble(),
          category: listing['category'],
          condition: listing['condition'],
          createdAt: DateTime.tryParse(listing['created_at'] ?? ''),
          onTap: () => context.push('/listing/$id'),
        );
      },
    );
  }
}
