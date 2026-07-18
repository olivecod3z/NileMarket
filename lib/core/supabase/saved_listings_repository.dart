import 'supabase_client.dart';

class SavedListingsRepository {
  SavedListingsRepository._();

  static Future<Set<String>> fetchSavedIds() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await supabase
        .from('saved_listings')
        .select('listing_id')
        .eq('user_id', userId);

    return (response as List).map((row) => row['listing_id'] as String).toSet();
  }

  static Future<void> save(String listingId) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('saved_listings').insert({
      'user_id': userId,
      'listing_id': listingId,
    });
  }

  static Future<void> unsave(String listingId) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('saved_listings')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }
}
