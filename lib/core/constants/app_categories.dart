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
