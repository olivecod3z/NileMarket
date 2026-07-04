import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://alcvazpopjpoyskdftya.supabase.co';
  static const String publishableKey =
      'sb_publishable_S4kMjzvZZwWTJoNIqaeNtA_u5qpj5af';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

final supabase = Supabase.instance.client;
