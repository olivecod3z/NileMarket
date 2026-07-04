import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive.isDesktop(context)
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(flex: 3, child: _brandPanel()),
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _actionButtons(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 4, child: _brandPanel()),
        Expanded(
          flex: 6,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _actionButtons(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandPanel() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.nileBlue,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/nilemarket_logo.png', width: 100),
              const SizedBox(height: 12),
              Text(
                'NileMarket',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Buy, sell & discover services within your campus',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome to NileMarket',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'The easiest way to buy, sell, and connect with your campus',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Get Started'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/login'),
              child: const Text('I already have an account'),
            ),
          ),
        ],
      ),
    );
  }
}
