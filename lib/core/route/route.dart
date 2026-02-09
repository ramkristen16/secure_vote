import 'package:go_router/go_router.dart';
import 'package:secure_vote/features/Dashboard/dashboard_view.dart';
import 'package:secure_vote/features/vote/views/access/vote_invitation.dart';
import 'package:secure_vote/features/vote/views/create/vote_create_view.dart';
import 'package:secure_vote/features/vote/views/history/history_vote_view.dart';

class Router {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const VoteDashboardView()
      ),
      GoRoute(
        path: "/create",
        builder: (context, state) => const VoteCreateView()
      ),
      GoRoute(
        path: "/history",
        builder: (context, state) => const VoteHistoryView()
      ),
      GoRoute(
        path: "/participation",
        builder: (context, state) => const VoteInvitationsView()
      )
    ]
  );
}
