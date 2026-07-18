import 'package:go_router/go_router.dart';
import 'package:nilemarket/features/auth/screens/complete_profile_screen.dart';
import 'package:nilemarket/features/marketplace/screens/categories_screen.dart';
import 'package:nilemarket/features/marketplace/screens/category_listings_screen.dart';
import 'package:nilemarket/features/marketplace/screens/home_screen.dart';
import 'package:nilemarket/features/marketplace/screens/listing_details_screen.dart';
import 'package:nilemarket/features/marketplace/screens/search_screen.dart';
import 'package:nilemarket/features/marketplace/screens/seller_profile_screen.dart';
import 'package:nilemarket/features/profile/screens/profile_screen.dart';
import 'package:nilemarket/features/selling/screens/create_listing_screen.dart';
import 'package:nilemarket/features/selling/screens/edit_listing_screen.dart';
import 'package:nilemarket/features/selling/screens/my_listings_screen.dart';
import 'package:nilemarket/shared_screens/coming_soon_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/create-listing',
      builder: (context, state) => const CreateListingScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) =>
          const ComingSoonScreen(title: 'Saved Listings'),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) =>
          ListingDetailsScreen(listingId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/seller/:id',
      builder: (context, state) =>
          SellerProfileScreen(sellerId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) => CategoryListingsScreen(
        category: Uri.decodeComponent(state.pathParameters['name']!),
      ),
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) =>
          const ComingSoonScreen(title: 'Saved Listings'),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) =>
          const ComingSoonScreen(title: 'Edit Profile'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const ComingSoonScreen(title: 'Settings'),
    ),
    GoRoute(
      path: '/edit-listing/:id',
      builder: (context, state) =>
          EditListingScreen(listingId: state.pathParameters['id']!),
    ),
  ],
);
