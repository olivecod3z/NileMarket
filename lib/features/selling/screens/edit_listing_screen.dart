import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/theme/app_radius.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';
import 'package:nilemarket/core/constants/app_categories.dart';
import 'package:nilemarket/core/supabase/supabase_client.dart';

class EditListingScreen extends StatefulWidget {
  final String listingId;
  const EditListingScreen({super.key, required this.listingId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];

  String _listingType = 'goods';
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isSubmitting = false;
  bool _isLoading = true;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Used'];

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  List<CategoryItem> get _categoriesForType =>
      _listingType == 'goods' ? goodsCategories : servicesCategories;

  int get _totalImageCount => _existingImageUrls.length + _newImages.length;

  Future<void> _loadListing() async {
    try {
      final data = await supabase
          .from('listings')
          .select()
          .eq('id', widget.listingId)
          .maybeSingle();

      if (data != null && mounted) {
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _priceController.text = (data['price'] as num).toString();
        setState(() {
          _listingType = data['listing_type'] ?? 'goods';
          _selectedCategory = data['category'];
          _selectedCondition = data['condition'];
          _existingImageUrls = (data['images'] as List?)?.cast<String>() ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final remaining = 3 - _totalImageCount;
    if (remaining <= 0) return;
    final images = await _picker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (images.isNotEmpty) {
      setState(() => _newImages = [...images.take(remaining)]);
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<List<String>> _uploadNewImages(String userId) async {
    final List<String> urls = [];
    for (final image in _newImages) {
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';
      await supabase.storage.from('listing-images').uploadBinary(path, bytes);
      urls.add(supabase.storage.from('listing-images').getPublicUrl(path));
    }
    return urls;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final newUrls = await _uploadNewImages(userId);
      final allImages = [..._existingImageUrls, ...newUrls];

      await supabase
          .from('listings')
          .update({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.parse(_priceController.text.trim()),
            'category': _selectedCategory,
            'listing_type': _listingType,
            'condition': _listingType == 'goods' ? _selectedCondition : null,
            'images': allImages,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.listingId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing updated!')));
        context.pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/edit-listing/${widget.listingId}',
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context),
                          const SizedBox(height: 24),
                          _sectionHeader('Photos'),
                          _imageRow(),
                          const SizedBox(height: 32),
                          _sectionHeader('Listing Details'),
                          _sectionLabel('Title'),
                          TextFormField(
                            controller: _titleController,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Title is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _sectionLabel('Category'),
                          _categoryDropdown(),
                          const SizedBox(height: 18),
                          if (_listingType == 'goods') ...[
                            _sectionLabel('Condition'),
                            _conditionDropdown(),
                            const SizedBox(height: 18),
                          ],
                          const SizedBox(height: 14),
                          _sectionHeader('Pricing'),
                          _sectionLabel('Price'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(prefixText: '₦ '),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Price is required';
                              if (double.tryParse(v) == null)
                                return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          _sectionHeader('Description'),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Description is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSave,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/my-listings'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        Text('Edit Listing', style: AppTextStyles.heading3),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: AppTextStyles.title),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _imageRow() {
    return Row(
      children: [
        for (int i = 0; i < _existingImageUrls.length; i++) _existingThumb(i),
        for (int i = 0; i < _newImages.length; i++) _newThumb(i),
        if (_totalImageCount < 3) _addTile(),
      ],
    );
  }

  Widget _existingThumb(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: Image.network(
              _existingImageUrls[index],
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          _removeBadge(() => _removeExistingImage(index)),
        ],
      ),
    );
  }

  Widget _newThumb(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: FutureBuilder<Uint8List>(
              future: _newImages[index].readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: 88,
                    height: 88,
                    color: AppColors.divider,
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          _removeBadge(() => _removeNewImage(index)),
        ],
      ),
    );
  }

  Widget _removeBadge(VoidCallback onTap) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.image),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      hint: const Text('Select a category'),
      items: [
        for (final item in _categoriesForType)
          DropdownMenuItem(
            value: item.label,
            child: Text('${item.emoji} ${item.label}'),
          ),
      ],
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _conditionDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCondition,
      hint: const Text('Select condition'),
      items: [
        for (final c in _conditions) DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (value) => setState(() => _selectedCondition = value),
    );
  }
}
