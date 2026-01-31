// lib/features/vote/views/vote_invitations_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';

import '../../model/subject_model.dart';
import '../../view_model/vote_view_model.dart';
import '../history/results_vote_view.dart';
import 'vote_casting_view.dart';


class VoteInvitationsView extends StatelessWidget {
  const VoteInvitationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoteViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A2E4D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mes participations",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton Invitations
              _buildSectionButton(
                context,
                icon: Icons.mail_outline,
                title: "Invitations",
                subtitle: "${vm.invitedVotes.length} scrutin${vm.invitedVotes.length > 1 ? 's' : ''} en attente",
                color: const Color(0xFF14B8A6),
                onTap: () => _showVoteList(
                  context,
                  vm.invitedVotes,
                  "Invitations",
                  false,
                ),
              ),

              const SizedBox(height: 16),

              // Bouton Mes Créations
              _buildSectionButton(
                context,
                icon: Icons.create_outlined,
                title: "Mes Créations",
                subtitle: "${vm.myCreatedVotes.length} scrutin${vm.myCreatedVotes.length > 1 ? 's' : ''} créé${vm.myCreatedVotes.length > 1 ? 's' : ''}",
                color: const Color(0xFF0A2E4D),
                onTap: () => _showVoteList(
                  context,
                  vm.myCreatedVotes,
                  "Mes Créations",
                  true,
                ),
              ),

              const SizedBox(height: 32),

              // Section d'information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Participez aux scrutins qui vous sont envoyés ou consultez vos créations",
                        style: TextStyle(
                          fontSize: 13,
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
    );
  }

  Widget _buildSectionButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showVoteList(
      BuildContext context,
      List<SubjectModel> votes,
      String title,
      bool isMyCreation,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VoteListScreen(
          votes: votes,
          title: title,
          isMyCreation: isMyCreation,
        ),
      ),
    );
  }
}

// Écran de liste des votes
class _VoteListScreen extends StatelessWidget {
  final List<SubjectModel> votes;
  final String title;
  final bool isMyCreation;

  const _VoteListScreen({
    required this.votes,
    required this.title,
    required this.isMyCreation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2E4D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: votes.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMyCreation ? Icons.create_outlined : Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isMyCreation
                    ? "Aucun scrutin créé"
                    : "Aucune invitation reçue",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Les scrutins apparaîtront ici",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: votes.length,
          itemBuilder: (context, index) {
            return _buildVoteCard(context, votes[index]);
          },
        ),
      ),
    );
  }

  Widget _buildVoteCard(BuildContext context, SubjectModel vote) {
    final hasVoted = vote.hasVoted;
    final isOpen = vote.isOpen;

    String? myChoiceName;
    if (hasVoted) {
      final choiceIndex = int.parse(vote.myVoteChoiceIndex!);
      myChoiceName = vote.choices[choiceIndex].name;
    }

    return GestureDetector(
      onTap: () {
        if (isOpen) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoteCastingView(vote: vote),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VoteResultsView(vote: vote),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    vote.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? "En cours" : "Terminé",
                        style: TextStyle(
                          color: isOpen
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (vote.description != null && vote.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                vote.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  "Deadline: ${DateFormat('dd/MM/yyyy').format(vote.deadline)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (hasVoted && myChoiceName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF14B8A6),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "À voté: $myChoiceName",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF14B8A6),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}