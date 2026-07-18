import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilemarket/core/theme/app_colors.dart';
import 'package:nilemarket/core/theme/app_text_styles.dart';
import 'package:nilemarket/core/widgets/app_shell.dart';

class StaticTextScreen extends StatelessWidget {
  final String title;
  final String body;
  final String currentRoute;

  const StaticTextScreen({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: currentRoute,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/settings'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      Text(title, style: AppTextStyles.heading3),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      body,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
