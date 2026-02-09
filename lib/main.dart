import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'features/Dashboard/dashboard_page.dart';
import 'features/vote/view_model/vote_view_model.dart';
import 'features/vote/views/access/vote_casting_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation localisation dates FR
  await initializeDateFormatting('fr_FR', null);

  final voteViewModel = VoteViewModel();
  await voteViewModel.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: voteViewModel),
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
  }

  // ===============================
  // DEEP LINKING
  // ===============================

  void _initDeepLinking() async {
    final appLinks = AppLinks();

    try {
      final uri = await appLinks.getInitialLink();

      if (uri != null) {
        print('App ouverte avec lien: $uri');
        _handleDeepLink(uri.toString());
      }
    } catch (e) {
      print('Erreur initial link: $e');
    }

    _sub = appLinks.uriLinkStream.listen(
          (Uri uri) {
        print('Lien reçu: $uri');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        print('Erreur stream: $err');
      },
    );
  }



  // ===============================
  // TRAITEMENT DU LIEN
  // ===============================

  void _handleDeepLink(String link) {
    print('Traitement du lien: $link');

    final uri = Uri.parse(link);

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments[0] == 'vote' && uri.pathSegments.length > 1) {
        final voteId = uri.pathSegments[1];
        print('Vote ID extrait: $voteId');

        _navigateToVote(voteId);
      } else {
        print('Format lien non reconnu: ${uri.path}');
      }
    }
  }

  // ===============================
  // NAVIGATION VERS VOTE
  // ===============================

  void _navigateToVote(String voteId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final voteViewModel = context.read<VoteViewModel>();
      final vote = voteViewModel.getVoteById(voteId);

      if (vote != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoteCastingView(vote: vote),
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

      home: DashboardPage(),
    );
  }
}
