import 'package:go_router/go_router.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/presentation/screens/admin/admin_data_screen.dart';
import 'package:civic_contribution/presentation/screens/auth/login_screen.dart';
import 'package:civic_contribution/presentation/screens/community/community_selection_screen.dart';
import 'package:civic_contribution/presentation/screens/home/home_screen.dart';
import 'package:civic_contribution/presentation/screens/issue_detail/issue_detail_screen.dart';
import 'package:civic_contribution/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:civic_contribution/presentation/screens/map/map_screen.dart';
import 'package:civic_contribution/presentation/screens/report/camera_screen.dart';
import 'package:civic_contribution/presentation/screens/report/confirm_screen.dart';
import 'package:civic_contribution/presentation/screens/report/form_screen.dart';
import 'package:civic_contribution/presentation/screens/verification/verify_screen.dart';

/// Single responsibility: declares all named routes and the auth redirect guard.
class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const camera = '/report/camera';
  static const reportForm = '/report/form';
  static const reportConfirm = '/report/confirm';
  static const issueDetail = '/issue/:issueId';
  static const verify = '/verify/:issueId';
  static const leaderboard = '/leaderboard';
  static const map = '/map';
  static const communitySelection = '/community-select';
  static const adminData = '/admin/data';

  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      initialLocation: home,
      refreshListenable: userProvider,
      redirect: (context, state) {
        final signedIn = userProvider.isSignedIn;
        final communityId = userProvider.communityId;
        final isAdmin = userProvider.isAdmin;
        final loc = state.matchedLocation;

        // 1. Not signed in → login
        if (!signedIn && loc != login) return login;

        // 2. Signed in but no community → community selection
        if (signedIn &&
            communityId == null &&
            loc != communitySelection &&
            loc != login) {
          return communitySelection;
        }

        // 3. Fully authenticated — don't stay on onboarding screens
        if (signedIn && communityId != null) {
          if (loc == login || loc == communitySelection) return home;
        }

        // 4. Admin-only routes
        if (loc == adminData && !isAdmin) return home;

        return null;
      },
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: communitySelection,
          builder: (context, state) => const CommunitySelectionScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: camera,
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: reportForm,
          builder: (context, state) => const ReportFormScreen(),
        ),
        GoRoute(
          path: reportConfirm,
          builder: (context, state) => const ReportConfirmScreen(),
        ),
        GoRoute(
          path: issueDetail,
          builder: (context, state) {
            final issueId = state.pathParameters['issueId']!;
            return IssueDetailScreen(issueId: issueId);
          },
        ),
        GoRoute(
          path: verify,
          builder: (context, state) {
            final issueId = state.pathParameters['issueId']!;
            return VerifyScreen(issueId: issueId);
          },
        ),
        GoRoute(
          path: leaderboard,
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: map,
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: adminData,
          builder: (context, state) => const AdminDataScreen(),
        ),
      ],
    );
  }
}
