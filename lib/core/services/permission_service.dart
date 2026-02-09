

import '../../features/vote/model/subject_model.dart';

// Service de gestion des permissions
//Contrôle qui peut faire quoi sur chaque vote
class PermissionService {

  // Vérifier si l'utilisateur est le créateur du vote
  static bool isCreator(SubjectModel vote, String userId) {
    return vote.creatorId == userId;
  }

  // Vérifier si l'utilisateur peut modifier le CONTENU du vote
  // (titre, description, choix, deadline - PAS le startingDate)
  static PermissionResult canEditVote(SubjectModel vote, String userId) {
    // Seul le créateur peut modifier
    if (!isCreator(vote, userId)) {
      return PermissionResult.denied(
          'Seul le créateur peut modifier ce vote'
      );
    }

    // Le vote ne doit pas encore avoir commencé
    if (!vote.notStartedYet) {
      return PermissionResult.denied(
          'Le vote ne peut plus être modifié car il a déjà commencé'
      );
    }

    // Vérifier qu'aucun vote n'a été enregistré
    if (vote.voteCount > 0) {
      return PermissionResult.denied(
          'Le vote ne peut plus être modifié car des personnes ont déjà voté'
      );
    }

    return PermissionResult.allowed();
  }

  // Vérifier si l'utilisateur peut voter ou modifier son vote
  static PermissionResult canCastVote(SubjectModel vote, String userId) {
    // Le vote doit être actif (entre startingDate et deadline)
    if (vote.notStartedYet) {
      return PermissionResult.denied(
          'Le vote n\'a pas encore commencé'
      );
    }

    if (vote.isFinished) {
      return PermissionResult.denied(
          'Le vote est terminé'
      );
    }

    if (!vote.isOpen) {
      return PermissionResult.denied(
          'Le vote n\'est pas ouvert'
      );
    }

    // Si le vote est privé, vérifier que l'utilisateur est invité
    if (vote.isPrivate) {
      // TODO: Vérifier dans la liste des invités
      // Pour l'instant, on suppose que si l'utilisateur voit le vote, il est invité
    }

    return PermissionResult.allowed();
  }

  // Vérifier si l'utilisateur peut voir les résultats
  static PermissionResult canViewResults(SubjectModel vote, String userId) {
    // Le créateur peut toujours voir les résultats
    if (isCreator(vote, userId)) {
      return PermissionResult.allowed();
    }

    // Pour un vote anonyme, tout le monde peut voir les résultats après le vote
    if (vote.isAnonymous) {
      return PermissionResult.allowed();
    }

    // Pour un vote non anonyme, on peut voir les résultats si on a voté
    if (vote.hasVoted) {
      return PermissionResult.allowed();
    }

    return PermissionResult.denied(
        'Vous devez voter pour voir les résultats'
    );
  }

  // Vérifier si l'utilisateur peut supprimer le vote
  static PermissionResult canDeleteVote(SubjectModel vote, String userId) {
    // Seul le créateur peut supprimer
    if (!isCreator(vote, userId)) {
      return PermissionResult.denied(
          'Seul le créateur peut supprimer ce vote'
      );
    }

    // On peut supprimer uniquement si le vote n'a pas commencé
    if (!vote.notStartedYet) {
      return PermissionResult.denied(
          'Un vote ne peut être supprimé une fois commencé'
      );
    }

    return PermissionResult.allowed();
  }

  // Vérifier si l'utilisateur peut inviter des participants
  static PermissionResult canInviteParticipants(SubjectModel vote, String userId) {
    // Seul le créateur peut inviter
    if (!isCreator(vote, userId)) {
      return PermissionResult.denied(
          'Seul le créateur peut inviter des participants'
      );
    }

    // On peut inviter jusqu'au début du vote
    if (!vote.notStartedYet) {
      return PermissionResult.denied(
          'Impossible d\'inviter de nouveaux participants après le début du vote'
      );
    }

    return PermissionResult.allowed();
  }

  // Vérifier si l'utilisateur peut voir les détails des votants (pour votes non anonymes)
  static PermissionResult canViewVoterDetails(SubjectModel vote, String userId) {
    // Si le vote est anonyme, personne ne peut voir les détails
    if (vote.isAnonymous) {
      return PermissionResult.denied(
          'Ce vote est anonyme, les détails des votants sont masqués'
      );
    }

    // Le créateur peut toujours voir
    if (isCreator(vote, userId)) {
      return PermissionResult.allowed();
    }

    // Les autres participants peuvent voir après avoir voté
    if (vote.hasVoted) {
      return PermissionResult.allowed();
    }

    return PermissionResult.denied(
        'Vous devez voter pour voir les détails'
    );
  }

  // Vérifier si l'utilisateur peut exporter les résultats
  static PermissionResult canExportResults(SubjectModel vote, String userId) {
    // Seul le créateur peut exporter
    if (!isCreator(vote, userId)) {
      return PermissionResult.denied(
          'Seul le créateur peut exporter les résultats'
      );
    }

    // On peut exporter uniquement après la fin du vote
    if (!vote.isFinished) {
      return PermissionResult.denied(
          'Les résultats ne peuvent être exportés qu\'après la fin du vote'
      );
    }

    return PermissionResult.allowed();
  }

  // Vérifier si l'utilisateur peut clôturer le vote prématurément
  static PermissionResult canCloseVoteEarly(SubjectModel vote, String userId) {
    // Seul le créateur peut clôturer
    if (!isCreator(vote, userId)) {
      return PermissionResult.denied(
          'Seul le créateur peut clôturer le vote'
      );
    }

    // Le vote doit être en cours
    if (!vote.isActive) {
      return PermissionResult.denied(
          'Le vote n\'est pas en cours'
      );
    }

    return PermissionResult.allowed();
  }

  // Journaliser une action pour audit de sécurité
  static void logSecurityAction({
    required String userId,
    required String action,
    required String voteId,
    required bool allowed,
    String? reason,
  }) {
    // TODO: Envoyer au backend pour audit
    final timestamp = DateTime.now().toIso8601String();
    print('[SECURITY AUDIT] $timestamp - User: $userId - Action: $action - Vote: $voteId - Allowed: $allowed${reason != null ? ' - Reason: $reason' : ''}');
  }
}

// Résultat d'une vérification de permission
class PermissionResult {
  final bool isAllowed;
  final String? denialReason;

  PermissionResult._({
    required this.isAllowed,
    this.denialReason,
  });

  factory PermissionResult.allowed() {
    return PermissionResult._(isAllowed: true);
  }

  factory PermissionResult.denied(String reason) {
    return PermissionResult._(
      isAllowed: false,
      denialReason: reason,
    );
  }

  // Lancer une exception si l'action n'est pas autorisée
  void throwIfDenied() {
    if (!isAllowed) {
      throw PermissionDeniedException(denialReason ?? 'Action non autorisée');
    }
  }
}

// Exception pour les refus de permission
class PermissionDeniedException implements Exception {
  final String message;

  PermissionDeniedException(this.message);

  @override
  String toString() => message;
}