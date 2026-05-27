import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/savings/screens/savings_screen.dart';
import 'features/loans/screens/loans_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/groups/screens/groups_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_members_screen.dart';
import 'features/admin/screens/admin_loans_screen.dart';
import 'features/admin/screens/admin_savings_screen.dart';
import 'features/admin/screens/admin_groups_screen.dart';
import 'features/admin/screens/admin_notifications_screen.dart';
import 'features/admin/screens/admin_reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MkobaApp());
}

class MkobaApp extends StatelessWidget {
  const MkobaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mkoba System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

// Roles zinazopelekwa Admin Dashboard
const List<String> adminRoles = [
  'ADMIN',
  'CHAIRPERSON',
  'TREASURER',
  'ACCOUNTANT',
  'SECRETARY',
];

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    if (isLoggedIn && isAuthRoute) {
      // Angalia role ya mtumiaji
      final userInfo = await AuthService.getUserInfo();
      final role = userInfo['role'] ?? 'MEMBER';
      if (adminRoles.contains(role)) {
        return '/admin';
      }
      return '/dashboard';
    }

    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // User Routes
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/savings',
      builder: (context, state) => const SavingsScreen(),
    ),
    GoRoute(path: '/loans', builder: (context, state) => const LoansScreen()),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
    GoRoute(path: '/groups', builder: (context, state) => const GroupsScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),

    // Admin Routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/members',
      builder: (context, state) => const AdminMembersScreen(),
    ),
    GoRoute(
      path: '/admin/loans',
      builder: (context, state) => const AdminLoansScreen(),
    ),
    GoRoute(
      path: '/admin/savings',
      builder: (context, state) => const AdminSavingsScreen(),
    ),
    GoRoute(
      path: '/admin/groups',
      builder: (context, state) => const AdminGroupsScreen(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const AdminNotificationsScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
  ],
);
