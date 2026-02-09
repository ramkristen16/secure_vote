// lib/features/vote/views/lien_success/vote_succes_view.dart
// VERSION CORRIGÉE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../view_model/vote_view_model.dart';
import '../access/vote_casting_view.dart';

class SuccessView extends StatelessWidget {
  final String shareLink;
  final String voteId;

  const SuccessView({
    super.key,
    required this.shareLink,
    required this.voteId,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VoteViewModel>();
    final vote = vm.getVoteById(voteId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF4CAF50),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 24),

                // Titre
                const Text(
                  "Scrutin Créé avec Succès",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Sous-titre
                Text(
                  "Votre scrutin est maintenant en ligne. Partagez le lien pour inviter des participants.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // "LIEN DU SCRUTIN"
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "LIEN DU SCRUTIN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF666666),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Zone de lien avec bouton copier
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shareLink,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: const Color(0xFF14B8A6),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _copyLink(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.content_copy,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Copier",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ BOUTON PARTAGER (WhatsApp, SMS, Email, etc.)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _shareViaWhatsApp(context, vote),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text(
                      "Partager via WhatsApp",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ BOUTON PARTAGER AUTRES (SMS, Email, Telegram, etc.)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF14B8A6), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _shareViaOthers(context, vote),
                    icon: const Icon(Icons.more_horiz, color: Color(0xFF14B8A6), size: 20),
                    label: const Text(
                      "Autres options de partage",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Info sur les apps de partage
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "SMS • Email • Telegram • Messenger • Copier le lien",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons côte à côte
                Row(
                  children: [
                    // BOUTON : Accéder au vote
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2E4D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (vote != null) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VoteCastingView(vote: vote),
                                ),
                                    (route) => route.isFirst,
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.launch,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Accéder\nau vote",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // BOUTON : Menu principal
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.popUntil(
                            context,
                                (route) => route.isFirst,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                color: Colors.grey[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Menu\nprincipal",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ COPIER LE LIEN
  // ═══════════════════════════════════════════════════════════

  void _copyLink(BuildContext context) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ PARTAGER VIA WHATSAPP (fonctionne vraiment)
  // ═══════════════════════════════════════════════════════════

  void _shareViaWhatsApp(BuildContext context, dynamic vote) async {
    if (vote == null) return;

    // Message d'invitation
    final message = _buildInvitationMessage(vote);

    try {
      // Partager avec sujet
      await Share.share(
        message,
        subject: '🗳️ Invitation : ${vote.title}',
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du partage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ PARTAGER AUTRES OPTIONS (SMS, Email, Telegram, etc.)
  // ═══════════════════════════════════════════════════════════

  void _shareViaOthers(BuildContext context, dynamic vote) async {
    if (vote == null) return;

    final message = _buildInvitationMessage(vote);

    try {
      await Share.share(
        message,
        subject: '🗳️ Invitation : ${vote.title}',
      );
    } catch (e) {
      print('❌ Erreur partage : $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ CONSTRUIRE LE MESSAGE D'INVITATION
  // ═══════════════════════════════════════════════════════════

  String _buildInvitationMessage(dynamic vote) {
    final deadlineFormatted = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(vote.deadline);

    return '''🗳️ INVITATION À VOTER

📋 ${vote.title}

${vote.description != null && vote.description!.isNotEmpty ? '📝 ${vote.description}\n\n' : ''}⏰ Date limite : $deadlineFormatted

👉 Votez maintenant en cliquant sur ce lien :
$shareLink

${vote.isAnonymous ? '🔒 Vote anonyme et sécurisé\n' : ''}
---
SecureVote - Vote sécurisé''';
  }
}