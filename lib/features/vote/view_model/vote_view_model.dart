

import 'package:flutter/material.dart';
import '../model/subject_model.dart';

class VoteViewModel extends ChangeNotifier {
  //  SIMULATION UTILISATEUR (FRONT)
  String currentUserId = "user_123";
  String currentUserName = "Utilisateur Test";

  // BASE DE DONNÉES LOCALE (FRONT)
  List<SubjectModel> allVotes = [];

  //  GETTERS POUR LES FILTRES

  // Scrutins créés par moi
  List<SubjectModel> get myCreatedVotes =>
      allVotes.where((v) => v.isCreatedByMe(currentUserId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Plus récent d'abord

  // Invitations reçues (scrutins créés par d'autres)
  List<SubjectModel> get invitedVotes =>
      allVotes.where((v) => !v.isCreatedByMe(currentUserId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Historique = mes créations
  List<SubjectModel> get history => myCreatedVotes;

  // Filtrer par plage de dates
  List<SubjectModel> getVotesByDateRange(DateTime start, DateTime end) {
    return myCreatedVotes.where((v) {
      return v.createdAt.isAfter(start) && v.createdAt.isBefore(end);
    }).toList();
  }

  // Filtrer par jour spécifique
  List<SubjectModel> getVotesByDay(DateTime day) {
    return myCreatedVotes.where((v) {
      return v.createdAt.year == day.year &&
          v.createdAt.month == day.month &&
          v.createdAt.day == day.day;
    }).toList();
  }

  // Grouper par jour pour l'historique
  Map<DateTime, List<SubjectModel>> get votesGroupedByDay {
    final Map<DateTime, List<SubjectModel>> grouped = {};

    for (var vote in myCreatedVotes) {
      final day = DateTime(
        vote.createdAt.year,
        vote.createdAt.month,
        vote.createdAt.day,
      );
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(vote);
    }

    return grouped;
  }

  // VARIABLES DU FORMULAIRE
  String title = "";
  String description = "";
  DateTime startingDate = DateTime.now();
  DateTime? deadline;
  List<ChoiceModel> choices = [
    ChoiceModel(name: ""),
    ChoiceModel(name: "")
  ];

  bool isAnonymous = true;
  bool isPrivate = true;
  bool isLoading = false;

  // --- ACTIONS FORMULAIRE ---
  void updateTitle(String val) {
    title = val;
    notifyListeners();
  }

  void updateDescription(String val) {
    description = val;
    notifyListeners();
  }

  void updateStartingDate(DateTime date) {
    startingDate = date;
    notifyListeners();
  }

  void updateDeadline(DateTime date) {
    deadline = date;
    notifyListeners();
  }

  void updateChoice(int index, String val) {
    if (index < choices.length) {
      choices[index].name = val;
      notifyListeners();
    }
  }

  void addChoiceSlot() {
    choices.add(ChoiceModel(name: ""));
    notifyListeners();
  }

  void removeChoiceSlot(int index) {
    if (choices.length > 2) {
      choices.removeAt(index);
      notifyListeners();
    }
  }

  void toggleAnonymous(bool val) {
    isAnonymous = val;
    notifyListeners();
  }

  void togglePrivate(bool val) {
    isPrivate = val;
    notifyListeners();
  }

  //  CRÉATION DE SCRUTIN
  Future<Map<String, String>?> createScrutin() async {
    if (title.isEmpty || deadline == null) return null;

    // Vérifier les choix valides
    final validChoices = choices
        .where((c) => c.name.trim().isNotEmpty)
        .map((c) => ChoiceModel(name: c.name.trim(), voteCount: 0))
        .toList();

    if (validChoices.length < 2) return null;

    isLoading = true;
    notifyListeners();

    // Simulation d'appel API
    await Future.delayed(const Duration(seconds: 1));

    final newVote = SubjectModel(
      creatorId: currentUserId,
      title: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      startingDate: startingDate,
      deadline: deadline!,
      choices: validChoices,
      isAnonymous: isAnonymous,
      isPrivate: isPrivate,
      participantCount: 0,
      voteCount: 0,
    );

    allVotes.insert(0, newVote);

    final link = "https://securevote.app/v/${newVote.id}";

    _resetForm();
    isLoading = false;
    notifyListeners();

    return {
      'link': link,
      'voteId': newVote.id,
    };
  }

  // VOTER SUR UN SCRUTIN
  Future<bool> castVote(SubjectModel vote, int choiceIndex) async {
    try {
      isLoading = true;
      notifyListeners();

      // Simulation d'appel API
      await Future.delayed(const Duration(milliseconds: 800));

      final index = allVotes.indexWhere((v) => v.id == vote.id);
      if (index == -1) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Mise à jour locale
      allVotes[index].recordVote(choiceIndex, currentUserId, currentUserName);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //  MODIFIER MON VOTE
  Future<bool> modifyVote(SubjectModel vote, int newChoiceIndex) async {
    if (!vote.isOpen) return false;
    return await castVote(vote, newChoiceIndex);
  }

  // RÉCUPÉRER UN VOTE SPÉCIFIQUE
  SubjectModel? getVoteById(String id) {
    try {
      return allVotes.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  //  METTRE À JOUR MON VOTE , Si LE DEADLINE N'EST PAS ENCORE TERMINE ON PEUT METTRE A JOUR
  Future<bool> updateVote(
      String voteId, {
        String? title,
        String? description,
        DateTime? deadline,
      }) async {
    try {
      isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      final index = allVotes.indexWhere((v) => v.id == voteId);
      if (index == -1) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      final vote = allVotes[index];

      if (!vote.isCreatedByMe(currentUserId) || !vote.isOpen) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      allVotes[index] = vote.copyWith(
        title: title,
        description: description,
        deadline: deadline,
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //  RESET FORMULAIRE
  void _resetForm() {
    title = "";
    description = "";
    startingDate = DateTime.now();
    deadline = null;
    choices = [ChoiceModel(name: ""), ChoiceModel(name: "")];
    isAnonymous = true;
    isPrivate = true;
  }

  //  RAFRAICHIR LA LISTE
  Future<void> refreshVotes() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Appel API
    } catch (e) {
      // Gérer les erreurs
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // RAFRAÎCHIR RÉSULTATS
  Future<void> refreshVoteResults(String voteId) async {
    try {
      // TODO: Appel API pour résultats actualisés
      notifyListeners();
    } catch (e) {
      // Gérer les erreurs
    }
  }
}