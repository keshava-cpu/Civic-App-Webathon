import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/issue_detail/issue_detail_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/report/camera_screen.dart';
import '../screens/report/confirm_screen.dart';
import '../screens/report/form_screen.dart';
import '../screens/verification/verify_screen.dart';

class AppRoutes {
  static const home = '/';
  static const camera = '/report/camera';
  static const reportForm = '/report/form';
  static const reportConfirm = '/report/confirm';
  static const issueDetail = '/issue/:issueId';
  static const verify = '/verify/:issueId';
  static const leaderboard = '/leaderboard';
  static const map = '/map';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
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
    ],
  );
}
