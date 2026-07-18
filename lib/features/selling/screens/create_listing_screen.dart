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

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _pickedImages = [];

  String _listingType = 'goods';
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isSubmitting = false;

  final List<String> _conditions = ['New', 'Like New', 'Used'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  List<CategoryItem> get _categoriesForType =>
      _listingType == 'goods' ? goodsCategories : servicesCategories;

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (images.isNotEmpty) {
      setState(() => _pickedImages = images.take(3).toList());
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<List<String>> _uploadImages(String userId) async {
    final List<String> urls = [];
    for (final image in _pickedImages) {
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      await supabase.storage
          .from('listing-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );

      final publicUrl = supabase.storage
          .from('listing-images')
          .getPublicUrl(path);
      urls.add(publicUrl);
    }
    return urls;
  }

  Future<void> _handleSubmit() async {
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
      final imageUrls = await _uploadImages(userId);

      await supabase.from('listings').insert({
        'seller_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'listing_type': _listingType,
        'condition': _listingType == 'goods' ? _selectedCondition : null,
        'images': imageUrls,
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing created!')));
        context.go('/home');
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
        ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/create-listing',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text('Create Listing', style: AppTextStyles.heading3),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _typeToggleSection(),
                    const SizedBox(height: 32),

                    _sectionHeader('Photos'),
                    Text(
                      'Add up to 3 clear photos. Listings with photos get more views',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 10),
                    _imagePickerRow(),
                    const SizedBox(height: 32),

                    _sectionHeader('Listing Details'),
                    _sectionLabel('Title'),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dell Latitude 5420',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Title is required';
                        }
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

                    // const SizedBox(height: 14),
                    _sectionLabel('Price'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(prefixText: '₦ '),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    _sectionHeader('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your item or service...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Publish Listing'),
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

  Widget _typeToggleSection() {
    return Row(
      children: [
        _typeChip('goods', 'Goods'),
        const SizedBox(width: 12),
        _typeChip('services', 'Services'),
      ],
    );
  }

  Widget _typeChip(String value, String label) {
    final isActive = _listingType == value;
    final subtitle = value == 'goods' ? 'Sell products' : 'Offer services';
    final icon = value == 'goods'
        ? Icons.inventory_2_outlined
        : Icons.handyman_outlined;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _listingType = value;
          _selectedCategory = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.activeBlue : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isActive ? AppColors.nileBlue : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 26,
                color: isActive ? AppColors.nileBlue : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: isActive ? AppColors.nileBlue : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePickerRow() {
    if (_pickedImages.isEmpty) {
      return _emptyDropzone();
    }

    return Row(
      children: [
        for (int i = 0; i < _pickedImages.length; i++) _imageThumb(i),
        if (_pickedImages.length < 3) _addMoreTile(),
      ],
    );
  }

  Widget _emptyDropzone() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.image),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.nileBlue,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photos',
              style: AppTextStyles.body.copyWith(
                color: AppColors.nileBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text('Tap to upload (up to 3)', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _addMoreTile() {
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

  Widget _imageThumb(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: FutureBuilder<Uint8List>(
              future: _pickedImages[index].readAsBytes(),
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
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
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
