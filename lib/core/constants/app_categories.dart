import 'package:flutter/material.dart';

class CategoryItem {
  final String label;
  final String emoji;
  const CategoryItem(this.label, this.emoji);
}

// Full lists — used by Create Listing when a seller picks a category
const List<CategoryItem> goodsCategories = [
  CategoryItem('Books & Study Materials', '📚'),
  CategoryItem('Electronics', '💻'),
  CategoryItem('Phones & Accessories', '📱'),
  CategoryItem('Fashion & Clothing', '👕'),
  CategoryItem('Shoes', '👟'),
  CategoryItem('Beauty & Personal Care', '💄'),
  CategoryItem('Hostel & Room Essentials', '🛏️'),
  CategoryItem('Furniture', '🪑'),
  CategoryItem('Home Appliances', '🍳'),
  CategoryItem('Food & Drinks', '🍔'),
  CategoryItem('Gaming', '🎮'),
  CategoryItem('Tickets & Events', '🎟️'),
  CategoryItem('Handmade & Crafts', '🎨'),
  CategoryItem('Vehicles', '🚗'),
  CategoryItem('Others', '📦'),
];

const List<CategoryItem> servicesCategories = [
  CategoryItem('Academic Tutoring', '📖'),
  CategoryItem('Programming & Tech', '💻'),
  CategoryItem('Graphic Design', '🎨'),
  CategoryItem('Photography & Videography', '📸'),
  CategoryItem('Hair & Beauty Services', '💇'),
  CategoryItem('Laundry', '🧺'),
  CategoryItem('Cleaning', '🧹'),
  CategoryItem('Delivery & Errands', '🚚'),
  CategoryItem('Repairs & Maintenance', '🔧'),
  CategoryItem('Printing & Typing', '🖨️'),
  CategoryItem('Event Services', '🎉'),
  CategoryItem('Fitness & Coaching', '🏋️'),
  CategoryItem('Music & Entertainment', '🎵'),
  CategoryItem('Freelance Services', '📝'),
  CategoryItem('Other Services', '🛠️'),
];

// Curated subsets — shown as the quick-filter chips on the Home screen
const List<CategoryItem> homeFeaturedGoodsCategories = [
  CategoryItem('Books & Study Materials', '📚'),
  CategoryItem('Electronics', '💻'),
  CategoryItem('Phones & Accessories', '📱'),
  CategoryItem('Fashion & Clothing', '👕'),
  CategoryItem('Hostel & Room Essentials', '🛏️'),
  CategoryItem('Food & Drinks', '🍔'),
  CategoryItem('Others', '📦'),
];

const List<CategoryItem> homeFeaturedServicesCategories = [
  CategoryItem('Academic Tutoring', '📖'),
  CategoryItem('Programming & Tech', '💻'),
  CategoryItem('Graphic Design', '🎨'),
  CategoryItem('Delivery & Errands', '🚚'),
  CategoryItem('Repairs & Maintenance', '🔧'),
  CategoryItem('Event Services', '🎉'),
  CategoryItem('Other Services', '🛠️'),
];
const Map<String, (IconData, Color)> categoryVisuals = {
  'Books & Study Materials': (Icons.menu_book_outlined, Color(0xFF3B82F6)),
  'Electronics': (Icons.laptop_outlined, Color(0xFF10B981)),
  'Phones & Accessories': (Icons.smartphone_outlined, Color(0xFF6366F1)),
  'Fashion & Clothing': (Icons.checkroom_outlined, Color(0xFFEC4899)),
  'Shoes': (Icons.hiking_outlined, Color(0xFF8B5CF6)),
  'Beauty & Personal Care': (
    Icons.face_retouching_natural_outlined,
    Color(0xFFEC4899),
  ),
  'Hostel & Room Essentials': (Icons.bed_outlined, Color(0xFFF59E0B)),
  'Furniture': (Icons.chair_outlined, Color(0xFF64748B)),
  'Home Appliances': (Icons.kitchen_outlined, Color(0xFF10B981)),
  'Food & Drinks': (Icons.restaurant_outlined, Color(0xFF10B981)),
  'Gaming': (Icons.sports_esports_outlined, Color(0xFF6366F1)),
  'Tickets & Events': (Icons.confirmation_number_outlined, Color(0xFFEF4444)),
  'Handmade & Crafts': (Icons.brush_outlined, Color(0xFF8B5CF6)),
  'Vehicles': (Icons.directions_car_outlined, Color(0xFF3B82F6)),
  'Others': (Icons.more_horiz, Color(0xFF64748B)),
  'Academic Tutoring': (Icons.menu_book_outlined, Color(0xFF3B82F6)),
  'Programming & Tech': (Icons.laptop_outlined, Color(0xFF6366F1)),
  'Graphic Design': (Icons.brush_outlined, Color(0xFF8B5CF6)),
  'Photography & Videography': (Icons.camera_alt_outlined, Color(0xFFEC4899)),
  'Hair & Beauty Services': (
    Icons.face_retouching_natural_outlined,
    Color(0xFFEC4899),
  ),
  'Laundry': (Icons.local_laundry_service_outlined, Color(0xFF3B82F6)),
  'Cleaning': (Icons.cleaning_services_outlined, Color(0xFF10B981)),
  'Delivery & Errands': (Icons.local_shipping_outlined, Color(0xFFF59E0B)),
  'Repairs & Maintenance': (Icons.build_outlined, Color(0xFF64748B)),
  'Printing & Typing': (Icons.print_outlined, Color(0xFF6366F1)),
  'Event Services': (Icons.celebration_outlined, Color(0xFFEC4899)),
  'Fitness & Coaching': (Icons.fitness_center_outlined, Color(0xFFEF4444)),
  'Music & Entertainment': (Icons.music_note_outlined, Color(0xFF8B5CF6)),
  'Freelance Services': (Icons.work_outline, Color(0xFF3B82F6)),
  'Other Services': (Icons.more_horiz, Color(0xFF64748B)),
};

(IconData, Color) visualsFor(String category) =>
    categoryVisuals[category] ??
    (Icons.category_outlined, const Color(0xFF64748B));
