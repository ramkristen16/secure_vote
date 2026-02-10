import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:secure_vote/features/Dashboard/dashboard_page.dart';
import 'package:secure_vote/features/vote/views/access/participation_page.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/storage_service.dart';

import '../../model/subject_model.dart';
import '../../view_model/vote_view_model.dart';

class VoteCastingView extends StatefulWidget {
  final SubjectModel vote;
  const VoteCastingView({super.key, required this.vote});

  @override
  State<VoteCastingView> createState() => _VoteCastingViewState();
}

class _VoteCastingViewState extends State<VoteCastingView> {
  int? _selectedChoice;
  bool _isSubmitting = false;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadLocalVote();
  }

  Future<void> _loadLocalVote() async {
    final localChoice = await _storage.getUserVoteChoice(widget.vote.id);

    if (localChoice != null) {
      setState(() {
        _selectedChoice = localChoice;
      });
      print(' Choix pré-sélectionné : $localChoice');
    } else if (widget.vote.hasVoted) {
      setState(() {
        _selectedChoice = int.parse(widget.vote.myVoteChoiceIndex!);
      });
    }
  }



 /* Future<void> _shareVote() async {
    final vm = context.read<VoteViewModel>();

    // Générer le lien
    final shareLink = "https://securevote.app/vote/${widget.vote.id}";

    // Message d'invitation
    final message = _buildInvitationMessage(shareLink);

    try {
      await Share.share(
        message,
        subject: '🗳️ Invitation : ${widget.vote.title}',
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du partage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }*/


  // COPIER LE LIEN


  /*void _copyLink() {
    final shareLink = "https://securevote.app/vote/${widget.vote.id}";

    Clipboard.setData(ClipboardData(text: shareLink));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Lien copié dans le presse-papiers"),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }*/
  Future<void> _shareVote() async {
    final vm = context.read<VoteViewModel>();
    final apiService = ApiService();

    String shareLink;

    // 1. Essayer d'obtenir le lien depuis le backend
    final response = await apiService.getElectionLink(widget.vote.id);

    if (response['success'] == true && response['link'] != null) {
      shareLink = response['link'];
      print('🔗 Lien backend: $shareLink');
    } else {
      // Fallback sur le lien généré localement
      shareLink = "https://securevote.app/vote/${widget.vote.id}";
      print('🔗 Lien local: $shareLink');
    }

    // 2. Message d'invitation
    final message = _buildInvitationMessage(shareLink);

    try {
      await Share.share(
        message,
        subject: '🗳️ Invitation : ${widget.vote.title}',
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du partage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔥 MODIFIÉ : Copier le lien du backend
  void _copyLink() async {
    final apiService = ApiService();

    String shareLink;

    // 1. Essayer d'obtenir le lien depuis le backend
    final response = await apiService.getElectionLink(widget.vote.id);

    if (response['success'] == true && response['link'] != null) {
      shareLink = response['link'];
    } else {
      shareLink = "https://securevote.app/vote/${widget.vote.id}";
    }

    // 2. Copier dans le presse-papiers
    Clipboard.setData(ClipboardData(text: shareLink));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Lien copié dans le presse-papiers"),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  //  AFFICHER LES OPTIONS DE PARTAGE


  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            const Text(
              "Partager le scrutin",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.vote.title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 24),

            // Bouton Partager
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share,
                  color: Color(0xFF25D366),
                ),
              ),
              title: const Text("Partager via..."),
              subtitle: const Text("WhatsApp, SMS, Email, etc."),
              onTap: () {
                Navigator.pop(context);
                _shareVote();
              },
            ),

            const SizedBox(height: 8),

            // Bouton Copier
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.content_copy,
                  color: Color(0xFF14B8A6),
                ),
              ),
              title: const Text("Copier le lien"),
              subtitle: const Text("Coller dans n'importe quelle app"),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),

            const SizedBox(height: 16),

            // Bouton Annuler
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInvitationMessage(String shareLink) {
    final deadlineFormatted = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(widget.vote.deadline);

    return '''🗳️ INVITATION À VOTER

📋 ${widget.vote.title}

${widget.vote.description != null && widget.vote.description!.isNotEmpty ? '📝 ${widget.vote.description}\n\n' : ''}⏰ Date limite : $deadlineFormatted

👉 Votez maintenant :
$shareLink

${widget.vote.isAnonymous ? '🔒 Vote anonyme et sécurisé\n' : ''}---
SecureVote''';
  }

  Future<void> _submitVote() async {
    if (_selectedChoice == null) return;

    setState(() => _isSubmitting = true);

    final vm = context.read<VoteViewModel>();
    final success = await vm.castVote(widget.vote, _selectedChoice!);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      final message = widget.vote.hasVoted
          ? "Vote modifié avec succès !"
          : "Vote enregistré avec succès !";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParticipationPage(),
          ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'enregistrement du vote"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VoteViewModel>();
    final isMyVote = widget.vote.isCreatedByMe(vm.currentUserId);

    final hasVoted = widget.vote.hasVoted;
    final notStartedYet = widget.vote.notStartedYet;
    final isFinished = widget.vote.isFinished;
    final canVote = widget.vote.isOpen;

    if (notStartedYet) {
      return _buildNotStartedView(isMyVote);
    }

    if (isFinished) {
      return _buildFinishedView(isMyVote);
    }

    // Vue normale pour voter
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E4D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // ✨ NOUVEAU : Bouton Partager si c'est mon vote
        actions: isMyVote ? [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: "Partager ce scrutin",
            onPressed: _showShareOptions,
          ),
        ] : null,
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF0A2E4D),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vote.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.vote.description != null &&
                    widget.vote.description!.isNotEmpty)
                  Text(
                    widget.vote.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dates
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                "Début: ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.vote.startingDate)}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                "Deadline: ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.vote.deadline)}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Badge anonymat
                    if (widget.vote.isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Votre vote est sécurisé et anonyme",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Section titre + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Choisissez une option",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (_selectedChoice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "1 sélectionné",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF14B8A6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LISTE DES CHOIX
                    ...List.generate(widget.vote.choices.length, (index) {
                      final choice = widget.vote.choices[index];
                      final isSelected = _selectedChoice == index;

                      return GestureDetector(
                        onTap: canVote
                            ? () => setState(() => _selectedChoice = index)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF14B8A6).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF14B8A6)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF14B8A6)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF14B8A6)
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  choice.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Bouton de soumission
                    if (canVote)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _selectedChoice == null || _isSubmitting
                              ? null
                              : _submitVote,
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            hasVoted
                                ? "Modifier mon vote (1 choix)"
                                : "Confirmer mon vote (1 choix)",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Information
                    if (canVote)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasVoted
                                    ? "Vous pouvez modifier votre vote jusqu'à la deadline"
                                    : "Votre choix sera enregistré de manière sécurisée",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vue quand le vote n'a pas encore commencé
  Widget _buildNotStartedView(bool isMyVote) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E4D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(),
              ),),
        ),
        title: const Text(
          "Vote à venir",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        //Bouton partager aussi ici
        actions: isMyVote ? [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showShareOptions,
          ),
        ] : null,
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: const Color(0xFF0F2A44).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.schedule, size: 64, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Text(widget.vote.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text("Ce scrutin n'a pas encore commencé", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text("Début: ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.vote.startingDate)}", style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Si terminé
  Widget _buildFinishedView(bool isMyVote) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E4D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vote terminé", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        // Bouton partager aussi ici
        actions: isMyVote ? [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showShareOptions,
          ),
        ] : null,
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                const Text("Ce scrutin est terminé", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text("Consultez les résultats pour voir les votes", style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}