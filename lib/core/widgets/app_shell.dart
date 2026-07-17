import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const List<NavItem> mainNavItems = [
  NavItem(
    label: 'Sell',
    icon: Icons.add_circle_outline,
    activeIcon: Icons.add_circle,
    route: '/create-listing',
  ),
  NavItem(
    label: 'Saved',
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    route: '/saved',
  ),
  NavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    route: '/profile',
  ),
];

class AppShell extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final String currentRoute;

  const AppShell({
    super.key,
    required this.body,
    required this.currentRoute,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _TopNavBar(currentRoute: currentRoute),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const _BrandLogo(),
      ),
      body: body,
      bottomNavigationBar: _BottomNav(currentRoute: currentRoute),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/nilemarket_logo.png',
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 8),
          Text(
            'NileMarket',
            style: AppTextStyles.title.copyWith(color: AppColors.nileBlue),
          ),
        ],
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final String currentRoute;
  const _TopNavBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const _BrandLogo(),
                const Spacer(),
                for (final item in mainNavItems)
                  _TopNavItem(item: item, isActive: item.route == currentRoute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  const _TopNavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: isActive ? AppColors.activeBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive
                      ? AppColors.nileBlue
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: AppTextStyles.small.copyWith(
                    color: isActive
                        ? AppColors.nileBlue
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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

class _BottomNav extends StatelessWidget {
  final String currentRoute;
  const _BottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final currentIndex = mainNavItems.indexWhere(
      (item) => item.route == currentRoute,
    );

    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.activeBlue,
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onDestinationSelected: (index) => context.go(mainNavItems[index].route),
      destinations: [
        for (final item in mainNavItems)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon, color: AppColors.nileBlue),
            label: item.label,
          ),
      ],
    );
  }
}
