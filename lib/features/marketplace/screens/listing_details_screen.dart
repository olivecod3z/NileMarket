import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/utils/formatters.dart';
import 'package:nilemarket/core/utils/responsive.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailsScreen({super.key, required this.listingId});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  late Future<Map<String, dynamic>?> _listingFuture;
  final PageController _imageController = PageController();
  int _currentImage = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _listingFuture = _fetchListing();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchListing() async {
    final response = await supabase
        .from('listings')
        .select('*, profiles(username, full_name, rating, avatar_url)')
        .eq('id', widget.listingId)
        .maybeSingle();
    return response;
  }

  Future<void> _contactOnWhatsApp(Map<String, dynamic> listing) async {
    final title = listing['title'] ?? 'this item';
    final price = Formatters.currency((listing['price'] as num).toDouble());
    final id = listing['id'];

    final message = Uri.encodeComponent(
      'Hi! 👋\nI\'m interested in your listing on NileMarket.\n'
      '📦 Item: $title\n💰 Price: $price\nIs it still available?\n'
      'Listing ID: $id',
    );
    final url = Uri.parse('https://wa.me/?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_blank');
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  void _showReportComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reporting is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/listing/${widget.listingId}',
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _listingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _notFoundState(context);
          }

          final listing = snapshot.data!;
          final isDesktop = Responsive.isDesktop(context);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  child: isDesktop
                      ? _desktopLayout(context, listing)
                      : _mobileLayout(context, listing),
                ),
              ),
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
          Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Listing not found', style: AppTextStyles.title),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, Map<String, dynamic> listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(context),
        _imageGallery(listing),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleAndPrice(listing),
              const SizedBox(height: 16),
              _metaRow(listing),
              const SizedBox(height: 20),
              _sellerCard(listing),
              const SizedBox(height: 20),
              _descriptionSection(listing),
              const SizedBox(height: 24),
              _actionButtons(listing),
              const SizedBox(height: 12),
              _reportRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desktopLayout(BuildContext context, Map<String, dynamic> listing) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(context),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: SizedBox(height: 420, child: _imageGallery(listing)),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleAndPrice(listing),
                    const SizedBox(height: 16),
                    _metaRow(listing),
                    const SizedBox(height: 20),
                    _sellerCard(listing),
                    const SizedBox(height: 24),
                    _actionButtons(listing),
                    const SizedBox(height: 12),
                    _reportRow(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _descriptionSection(listing),
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

  Widget _imageGallery(Map<String, dynamic> listing) {
    final images = (listing['images'] as List?)?.cast<String>() ?? [];

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: AppColors.divider,
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _imageController,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemCount: images.length,
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(color: AppColors.divider),
              errorWidget: (c, u, e) => Container(
                color: AppColors.divider,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentImage ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentImage ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() => _isSaved = !_isSaved),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: _isSaved ? Colors.red : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleAndPrice(Map<String, dynamic> listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(listing['title'] ?? '', style: AppTextStyles.heading3),
        const SizedBox(height: 6),
        Text(
          Formatters.currency((listing['price'] as num).toDouble()),
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.marketplaceGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _metaRow(Map<String, dynamic> listing) {
    final condition = listing['condition'];
    final category = listing['category'];
    final createdAt = DateTime.tryParse(listing['created_at'] ?? '');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (condition != null) _metaChip(condition, AppColors.nileBlue),
        if (category != null) _metaChip(category, AppColors.textSecondary),
        if (createdAt != null)
          _metaChip(Formatters.timeAgo(createdAt), AppColors.textSecondary),
      ],
    );
  }

  Widget _metaChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sellerCard(Map<String, dynamic> listing) {
    final profile = listing['profiles'];
    final username = profile?['username'] ?? 'Unknown seller';
    final rating = (profile?['rating'] as num?)?.toDouble();

    return GestureDetector(
      onTap: () => context.push('/seller/${listing['seller_id']}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.divider,
              child: Icon(Icons.person, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rating != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _descriptionSection(Map<String, dynamic> listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: AppTextStyles.title),
        const SizedBox(height: 8),
        Text(listing['description'] ?? '', style: AppTextStyles.body),
      ],
    );
  }

  Widget _actionButtons(Map<String, dynamic> listing) {
    return ElevatedButton.icon(
      onPressed: () => _contactOnWhatsApp(listing),
      icon: const Icon(Icons.chat, size: 18),
      label: const Text('Contact on WhatsApp'),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
    );
  }

  Widget _reportRow() {
    return TextButton.icon(
      onPressed: _showReportComingSoon,
      icon: Icon(Icons.flag_outlined, size: 16, color: AppColors.textSecondary),
      label: Text(
        'Report Listing',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
