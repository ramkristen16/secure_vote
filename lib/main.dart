import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'package:secure_vote/features/Dashboard/dashboard_page.dart';
import 'dart:async';
import 'features/auth/auth_view/auth_view.dart';
import 'features/auth/auth_viewModel/auth_viewModel.dart';
import 'features/vote/model/subject_model.dart';
import 'features/vote/view_model/vote_view_model.dart';
import 'features/vote/views/access/vote_casting_view.dart';
import 'core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService().init();

  // Initialisation localisation dates FR
  await initializeDateFormatting('fr_FR', null);

  final voteViewModel = VoteViewModel();
  await voteViewModel.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: voteViewModel),

        ChangeNotifierProxyProvider<VoteViewModel, AuthViewModel>(
          create: (context) => AuthViewModel(voteViewModel: voteViewModel),
          update: (context, voteVM, authVM) =>
          authVM ?? AuthViewModel(voteViewModel: voteVM),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _sub;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().checkAuthStatus();
    });
  }

  // DEEP LINKING

  void _initDeepLinking() async {
    try {
      final uri = await _appLinks.getInitialLink();

      if (uri != null) {
        print('🔗 App ouverte avec lien: $uri');
        _handleDeepLink(uri.toString());
      }
    } catch (e) {
      print('❌ Erreur initial link: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
          (Uri uri) {
        print('🔗 Lien reçu: $uri');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        print('❌ Erreur stream: $err');
      },
    );
  }

  /// 🔥 MODIFIÉ : Gérer le deep linking avec chargement depuis le backend
  void _handleDeepLink(String link) {
    print('🔍 Traitement du lien: $link');

    final uri = Uri.parse(link);

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments[0] == 'vote' && uri.pathSegments.length > 1) {
        final voteId = uri.pathSegments[1];
        print('🗳️ Vote ID extrait: $voteId');

        _navigateToVote(voteId);
      } else {
        print('⚠️ Format lien non reconnu: ${uri.path}');
      }
    }
  }

  /// 🔥 MODIFIÉ : Charger le vote depuis le backend si nécessaire
  void _navigateToVote(String voteId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final voteViewModel = context.read<VoteViewModel>();

      // 1. Chercher localement d'abord
      SubjectModel? vote = voteViewModel.getVoteById(voteId);

      // 2. Si pas trouvé localement, charger depuis le backend
      if (vote == null) {
        print('⏳ Chargement du vote depuis le backend...');

        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        vote = await voteViewModel.loadVoteFromBackend(voteId);

        // Fermer le loader
        if (mounted) {
          Navigator.of(context).pop();
        }
      }

      if (!mounted) return;

      // 3. Naviguer vers le vote
      if (vote != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoteCastingView(vote: vote!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Vote introuvable ou supprimé')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return MaterialApp(
          title: 'Secure Vote App',
          debugShowCheckedModeBanner: false,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
          ],
          locale: const Locale('fr', 'FR'),

          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: false,
          ),

          // 🔥 MODIFIÉ : Utiliser authVM.isAuthenticated au lieu de false
          home: authVM.isAuthenticated
              ? DashboardPage()
              : const LoginPage(),
        );
      },
    );
  }
}