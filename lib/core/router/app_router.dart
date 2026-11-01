import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project.dart';
import '../../features/about/about_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_gate.dart';
import '../../features/admin/admin_messages_screen.dart';
import '../../features/admin/admin_profile_screen.dart';
import '../../features/admin/admin_projects_screen.dart';
import '../../features/admin/admin_services_screen.dart';
import '../../features/admin/admin_skills_screen.dart';
import '../../features/admin/admin_timeline_screen.dart';
import '../../features/admin/message_detail_screen.dart';
import '../../features/admin/project_editor_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/resume/resume_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../providers/app_providers.dart';
import '../supabase/supabase_bootstrap.dart';

/// Central route table (all paths in one place).
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String projects = '/projects';
  static const String about = '/about';
  static const String contact = '/contact';

  static const String projectDetail = '/projects/:slug';
  static String project(String slug) => '/projects/$slug';

  static const String resume = '/resume';

  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';

  static const String admin = '/admin';
  static const String adminProjects = '/admin/projects';
  static const String adminProjectNew = '/admin/projects/new';
  static const String adminProjectEdit = '/admin/projects/:id/edit';
  static String adminProjectEditPath(String id) => '/admin/projects/$id/edit';
  static const String adminMessages = '/admin/messages';
  static const String adminMessageDetail = '/admin/messages/:id';
  static String adminMessage(String id) => '/admin/messages/$id';
  static const String adminProfile = '/admin/profile';
  static const String adminSkills = '/admin/skills';
  static const String adminServices = '/admin/services';
  static const String adminTimeline = '/admin/timeline';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final Preferences prefs = ref.watch(preferencesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = SupabaseBootstrap.isReady &&
          SupabaseBootstrap.client.auth.currentSession != null;
      final bool isAdminRoute = state.matchedLocation.startsWith(AppRoutes.admin);

      // Admin routes require a session; the AdminGate then verifies the role.
      if (isAdminRoute && !signedIn) {
        final String next = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.signIn}?next=$next';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) => SplashScreen(
          hasSeenOnboarding: prefs.hasSeenOnboarding,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
      ),
      StatefulShellRoute(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            MainShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (
          BuildContext context,
          StatefulNavigationShell navigationShell,
          List<Widget> children,
        ) =>
            BranchTransitionStack(
          currentIndex: navigationShell.currentIndex,
          children: children,
        ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.projects,
                builder: (BuildContext context, GoRouterState state) => const ProjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.about,
                builder: (BuildContext context, GoRouterState state) => const AboutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.contact,
                builder: (BuildContext context, GoRouterState state) => const ContactScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.projectDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => ProjectDetailScreen(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.resume,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const ResumeScreen(),
      ),

      // -- Auth ---------------------------------------------------------------
      GoRoute(
        path: AppRoutes.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => SignInScreen(
          nextLocation: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => SignUpScreen(
          nextLocation: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'],
        ),
      ),

      // -- Admin --------------------------------------------------------------
      GoRoute(
        path: AppRoutes.admin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminProjects,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminProjectsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminProjectNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: ProjectEditorScreen(project: null),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminProjectEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => AdminGate(
          child: ProjectEditorScreen(
            project: state.extra is Project ? state.extra! as Project : null,
            projectId: state.pathParameters['id'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminMessages,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminMessagesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminMessageDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => AdminGate(
          child: MessageDetailScreen(messageId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminSkills,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminSkillsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminServices,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminServicesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminTimeline,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const AdminGate(
          child: AdminTimelineScreen(),
        ),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => _NotFoundScreen(
      location: state.uri.toString(),
    ),
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Page not found', style: TextStyle(fontSize: 22, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                location,
                style: const TextStyle(color: Color(0xFF7A849C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
