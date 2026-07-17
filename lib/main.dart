import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const NileMarketApp());
}

class NileMarketApp extends StatelessWidget {
  const NileMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NileMarket',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      scrollBehavior: const ScrollBehavior().copyWith(scrollbars: false),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
