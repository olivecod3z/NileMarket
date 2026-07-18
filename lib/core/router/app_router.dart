import 'package:go_router/go_router.dart';
import 'package:nilemarket/features/auth/screens/complete_profile_screen.dart';
import 'package:nilemarket/features/marketplace/screens/home_screen.dart';
import 'package:nilemarket/features/marketplace/screens/listing_details_screen.dart';
import 'package:nilemarket/features/marketplace/screens/seller_profile_screen.dart';
import 'package:nilemarket/features/selling/screens/create_listing_screen.dart';
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
      path: '/search',
      builder: (context, state) => const ComingSoonScreen(title: 'Search'),
    ),
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
      builder: (context, state) => const ComingSoonScreen(title: 'My Profile'),
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
  ],
);
