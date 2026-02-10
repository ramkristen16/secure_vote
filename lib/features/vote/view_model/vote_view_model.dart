import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../../core/services/storage_service.dart';
import '../model/subject_model.dart';
import '../../../core/services/input_validation_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/api_service.dart'; // 🔥 NOUVEAU

class VoteViewModel extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _storage = StorageService();
  final ApiService _apiService = ApiService(); // 🔥 NOUVEAU

  String currentUserId = "user_123";
  String currentUserName = "Utilisateur Test";

  List<SubjectModel> allVotes = [];
  bool isLoading = false;

  // Variables du formulaire
  String title = "";
  String description = "";
  DateTime startingDate = DateTime.now();
  DateTime? deadline;
  List<ChoiceModel> choices = [
    ChoiceModel(name: "", id: ''),
    ChoiceModel(name: "", id: '')
  ];
  bool isAnonymous = true;
  bool isPrivate = true;

  // ==================== INITIALISATION ====================

  Future<void> init() async {
    await loadUserData();
    await loadVotesFromLocal();
    await _enrichVotesWithLocalChoices();
  }

 /* Future<void> loadUserData() async {
    try {
      final userId = await _secureStorage.read(key: 'userId');
      if (userId == null) {
        currentUserId = await _storage.getUserId();
        await _secureStorage.write(key: 'userId', value: currentUserId);
      } else {
        currentUserId = userId;
      }

      final userName = await _secureStorage.read(key: 'userName');
      if (userName == null) {
        currentUserName = await _storage.getUserName() ?? 'Utilisateur Test';
        await _secureStorage.write(key: 'userName', value: currentUserName);
      } else {
        currentUserName = userName;
      }

      final token = await _secureStorage.read(key: 'authToken');
      if (token != null) {
        print('🔑 Token chargé: ${token.substring(0, 20)}...');
      }

      print('👤 Utilisateur chargé: $currentUserName ($currentUserId)');
    } catch (e) {
      print('❌ Erreur lors du chargement des données utilisateur: $e');
    }
*/
  Future<void> loadUserData() async {
    try {
      final userId = await _secureStorage.read(key: 'userId');

      // 🔥 Ne PAS utiliser "user_123" par défaut
      if (userId != null && userId.isNotEmpty) {
        currentUserId = userId;
      } else {
        currentUserId = ""; // ⚠️ VIDE au lieu de "user_123"
      }

      final userName = await _secureStorage.read(key: 'userName');
      if (userName != null && userName.isNotEmpty) {
        currentUserName = userName;
      } else {
        currentUserName = ""; // ⚠️ VIDE au lieu de "Utilisateur Test"
      }

      final token = await _secureStorage.read(key: 'authToken');
      if (token != null) {
        print('🔑 Token chargé: ${token.substring(0, 20)}...');
      } else {
        print('⚠️ Aucun token trouvé');
      }

      print('👤 User: "$currentUserId" / "$currentUserName"');
    } catch (e) {
      print('❌ Erreur: $e');
      currentUserId = "";
      currentUserName = "";
    }
  }
  Future<void> saveUserData({
    required String userId,
    required String userName,
    String? authToken,
  }) async {
    try {
      await _secureStorage.write(key: 'userId', value: userId);
      await _secureStorage.write(key: 'userName', value: userName);

      if (authToken != null) {
        await _secureStorage.write(key: 'authToken', value: authToken);
      }

      currentUserId = userId;
      currentUserName = userName;

      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des données utilisateur: $e');
    }
  }

  Future<void> loadVotesFromLocal() async {
    try {
      isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final votesJson = prefs.getString('votes');

      if (votesJson != null) {
        final List<dynamic> votesList = json.decode(votesJson);

        allVotes = votesList
            .map((voteJson) => SubjectModel.fromJson(
          voteJson as Map<String, dynamic>,
          currentUserId,
        ))
            .toList();

        print('📦 ${allVotes.length} votes chargés depuis le stockage local');
      } else {
        print('📭 Aucun vote en stockage local');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des votes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _enrichVotesWithLocalChoices() async {
    try {
      print('🔄 Enrichissement des votes avec les choix locaux...');

      for (int i = 0; i < allVotes.length; i++) {
        final voteId = allVotes[i].id;
        final localChoice = await _storage.getUserVoteChoice(voteId);

        if (localChoice != null) {
          allVotes[i] = allVotes[i].copyWith(
            myVoteChoiceIndex: localChoice.toString(),
          );
          print('✅ Choix local chargé : $voteId → choix $localChoice');
        }
      }

      print('✅ Enrichissement terminé');
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de l\'enrichissement : $e');
    }
  }

  Future<void> _saveVotesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final votesJson = allVotes.map((vote) => vote.toJson()).toList();
      await prefs.setString('votes', json.encode(votesJson));
      print('💾 ${allVotes.length} votes sauvegardés localement');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des votes: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      await _storage.clearAllUserVotes();

      allVotes = [];
      currentUserId = "user_123";
      currentUserName = "Utilisateur Test";

      notifyListeners();

      print('🗑️ Toutes les données effacées');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des données: $e');
    }
  }

  // ==================== GETTERS ====================

  List<SubjectModel> get myCreatedVotes =>
      allVotes.where((v) => v.isCreatedByMe(currentUserId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<SubjectModel> get invitedVotes =>
      allVotes.where((v) => !v.isCreatedByMe(currentUserId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<SubjectModel> get history => myCreatedVotes;

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

  // ==================== FORMULAIRE ====================

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
    choices.add(ChoiceModel(name: "", id: ''));
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

  // ==================== CRÉATION DE SCRUTIN (avec API) ====================

  /// 🔥 MODIFIÉ : Utilise l'API backend
  Future<Map<String, String>?> createScrutin() async {
    if (title.isEmpty || deadline == null) return null;

    final validChoices = choices
        .where((c) => c.name.trim().isNotEmpty)
        .map((c) => c.name.trim())
        .toList();

    if (validChoices.length < 2) return null;

    try {
      isLoading = true;
      notifyListeners();

      // Validation des entrées
      final cleanTitle = InputValidationService.sanitizeTitle(title);
      final cleanDescription = InputValidationService.sanitizeDescription(description);
      final cleanChoices = InputValidationService.sanitizeChoices(validChoices);

      InputValidationService.validateDates(startingDate, deadline!);
      InputValidationService.checkRateLimit(currentUserId);

      // 🔥 APPEL API BACKEND
      final response = await _apiService.createElection(
        title: cleanTitle,
        description: cleanDescription!.isEmpty ? null : cleanDescription,
        startingDate: startingDate,
        deadline: deadline!,
        anonymous: isAnonymous,
        isPrivate: isPrivate,
        choices: cleanChoices,
      );

      if (response['success'] == true) {
        // Créer le vote localement aussi (pour l'affichage immédiat)
        final newVote = SubjectModel(
          id: response['subjectId'] ?? '', // 🔥 Utiliser l'ID du backend
          creatorId: currentUserId,
          title: cleanTitle,
          description: cleanDescription,
          startingDate: startingDate,
          deadline: deadline!,
          choices: (response['choices'] as List?)
              ?.map((c) => ChoiceModel(
            id: c['_id'] ?? c['id'] ?? '',
            name: c['label'] ?? c['name'] ?? '',
            voteCount: 0,
          ))
              .toList() ??
              cleanChoices.map((name) => ChoiceModel(name: name, voteCount: 0, id: '')).toList(),
          isAnonymous: isAnonymous,
          isPrivate: isPrivate,
          participantCount: 0,
          voteCount: 0,
        );

        allVotes.insert(0, newVote);
        await _saveVotesToLocal();

        final link = response['link'] ?? "https://securevote.app/vote/${newVote.id}";

        PermissionService.logSecurityAction(
          userId: currentUserId,
          action: 'CREATE_VOTE',
          voteId: newVote.id,
          allowed: true,
        );

        _resetForm();
        isLoading = false;
        notifyListeners();

        return {
          'link': link,
          'voteId': newVote.id,
        };
      } else {
        throw Exception(response['message'] ?? 'Erreur de création');
      }

    } on ValidationException catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur de validation: $e');
      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de la création du vote: $e');
      return null;
    }
  }

  // ==================== VOTER (avec API) ====================

  /// 🔥 MODIFIÉ : Utilise l'API backend
  Future<bool> castVote(SubjectModel vote, int choiceIndex) async {
    try {
      isLoading = true;
      notifyListeners();

      // Vérifications locales
      final permission = PermissionService.canCastVote(vote, currentUserId);
      permission.throwIfDenied();

      InputValidationService.validateChoiceIndex(choiceIndex, vote.choices.length);
      InputValidationService.checkRateLimit(currentUserId);

      // Récupérer l'ID du choix
      final choiceId = vote.choices[choiceIndex].id;
      if (choiceId.isEmpty) {
        throw Exception('ID du choix manquant');
      }

      // 🔥 APPEL API BACKEND
      final response = await _apiService.voteForElection(
        subjectId: vote.id,
        choiceId: choiceId,
      );

      if (response['success'] == true) {
        // Sauvegarder le choix localement
        await _storage.saveUserVoteChoice(vote.id, choiceIndex);
        print('💾 Choix sauvegardé localement : ${vote.id} → $choiceIndex');

        // Mise à jour locale
        final index = allVotes.indexWhere((v) => v.id == vote.id);
        if (index != -1) {
          allVotes[index].recordVote(choiceIndex, currentUserId, currentUserName);
          allVotes[index] = allVotes[index].copyWith(
            myVoteChoiceIndex: choiceIndex.toString(),
          );

          await _saveVotesToLocal();
        }

        PermissionService.logSecurityAction(
          userId: currentUserId,
          action: 'CAST_VOTE',
          voteId: vote.id,
          allowed: true,
        );

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Erreur lors du vote');
      }

    } on PermissionDeniedException catch (e) {
      isLoading = false;
      notifyListeners();

      PermissionService.logSecurityAction(
        userId: currentUserId,
        action: 'CAST_VOTE',
        voteId: vote.id,
        allowed: false,
        reason: e.message,
      );

      print('❌ Permission refusée: $e');
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors du vote: $e');
      return false;
    }
  }

  // ==================== DEEP LINKING : Charger un vote depuis le backend ====================

  /// 🔥 NOUVEAU : Charger un vote depuis le backend via son ID
  /// Utilisé quand on clique sur un lien partagé
  Future<SubjectModel?> loadVoteFromBackend(String voteId) async {
    try {
      print('🔗 Chargement du vote $voteId depuis le backend...');

      isLoading = true;
      notifyListeners();

      // 1. Récupérer les infos publiques du vote
      final response = await _apiService.getElectionWelcome(voteId);

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Vote introuvable');
      }

      final electionData = response['election'];

      // 2. S'inscrire automatiquement comme participant
      await _apiService.registerForElection(voteId);

      // 3. Créer l'objet SubjectModel
      final vote = SubjectModel(
        id: electionData['_id'] ?? electionData['id'] ?? voteId,
        creatorId: electionData['creatorId'] ?? '',
        title: electionData['title'] ?? '',
        description: electionData['description'] ?? '',
        startingDate: DateTime.parse(electionData['startingDate'] ?? DateTime.now().toIso8601String()),
        deadline: DateTime.parse(electionData['deadline'] ?? DateTime.now().toIso8601String()),
        choices: (electionData['choices'] as List?)
            ?.map((c) => ChoiceModel(
          id: c['_id'] ?? c['id'] ?? '',
          name: c['label'] ?? c['name'] ?? '',
          voteCount: c['votes'] ?? c['voteCount'] ?? 0,
        ))
            .toList() ??
            [],
        isAnonymous: electionData['anonymous'] ?? true,
        isPrivate: electionData['isPrivate'] ?? electionData['is_private'] ?? false,
        participantCount: electionData['participantCount'] ?? 0,
        voteCount: electionData['voteCount'] ?? 0,
      );

      // 4. Vérifier si le vote existe déjà localement
      final existingIndex = allVotes.indexWhere((v) => v.id == vote.id);

      if (existingIndex == -1) {
        // Ajouter le vote à la liste locale
        allVotes.add(vote);
        await _saveVotesToLocal();
        print('✅ Vote ajouté à la liste locale');
      } else {
        // Mettre à jour le vote existant
        allVotes[existingIndex] = vote;
        await _saveVotesToLocal();
        print('✅ Vote mis à jour dans la liste locale');
      }

      // 5. Charger le choix local si existant
      final localChoice = await _storage.getUserVoteChoice(voteId);
      if (localChoice != null) {
        final updatedVote = vote.copyWith(
          myVoteChoiceIndex: localChoice.toString(),
        );

        isLoading = false;
        notifyListeners();
        return updatedVote;
      }

      isLoading = false;
      notifyListeners();
      return vote;

    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors du chargement du vote: $e');
      return null;
    }
  }

  // ==================== REFRESH ====================

  /// 🔥 MODIFIÉ : Synchroniser avec le backend
  Future<void> refreshVotes() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Charger les votes créés par moi
      final createdResponse = await _apiService.getCreatedElections();

      if (createdResponse['success'] == true) {
        final createdElections = createdResponse['elections'] as List;

        // Convertir en SubjectModel
        for (var electionData in createdElections) {
          final vote = SubjectModel(
            id: electionData['_id'] ?? electionData['id'] ?? '',
            creatorId: currentUserId,
            title: electionData['title'] ?? '',
            description: electionData['description'] ?? '',
            startingDate: DateTime.parse(electionData['startingDate'] ?? DateTime.now().toIso8601String()),
            deadline: DateTime.parse(electionData['deadline'] ?? DateTime.now().toIso8601String()),
            choices: (electionData['choices'] as List?)
                ?.map((c) => ChoiceModel(
              id: c['_id'] ?? c['id'] ?? '',
              name: c['label'] ?? c['name'] ?? '',
              voteCount: c['votes'] ?? c['voteCount'] ?? 0,
            ))
                .toList() ??
                [],
            isAnonymous: electionData['anonymous'] ?? true,
            isPrivate: electionData['isPrivate'] ?? false,
            participantCount: electionData['participantCount'] ?? 0,
            voteCount: electionData['voteCount'] ?? 0,
          );

          final existingIndex = allVotes.indexWhere((v) => v.id == vote.id);
          if (existingIndex == -1) {
            allVotes.add(vote);
          } else {
            allVotes[existingIndex] = vote;
          }
        }
      }

      // 2. Charger les votes où je participe
      final participatingResponse = await _apiService.getParticipatingElections();

      if (participatingResponse['success'] == true) {
        final invitations = participatingResponse['invitations'] as List;

        for (var invitation in invitations) {
          final electionData = invitation['subject'] ?? invitation;

          final vote = SubjectModel(
            id: electionData['_id'] ?? electionData['id'] ?? '',
            creatorId: electionData['creatorId'] ?? '',
            title: electionData['title'] ?? '',
            description: electionData['description'] ?? '',
            startingDate: DateTime.parse(electionData['startingDate'] ?? DateTime.now().toIso8601String()),
            deadline: DateTime.parse(electionData['deadline'] ?? DateTime.now().toIso8601String()),
            choices: (electionData['choices'] as List?)
                ?.map((c) => ChoiceModel(
              id: c['_id'] ?? c['id'] ?? '',
              name: c['label'] ?? c['name'] ?? '',
              voteCount: c['votes'] ?? c['voteCount'] ?? 0,
            ))
                .toList() ??
                [],
            isAnonymous: electionData['anonymous'] ?? true,
            isPrivate: electionData['isPrivate'] ?? false,
            participantCount: electionData['participantCount'] ?? 0,
            voteCount: electionData['voteCount'] ?? 0,
          );

          final existingIndex = allVotes.indexWhere((v) => v.id == vote.id);
          if (existingIndex == -1) {
            allVotes.add(vote);
          } else {
            allVotes[existingIndex] = vote;
          }
        }
      }

      // 3. Sauvegarder localement
      await _saveVotesToLocal();

      // 4. Enrichir avec les choix locaux
      await _enrichVotesWithLocalChoices();

      print('✅ ${allVotes.length} votes synchronisés avec le backend');

    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');
      // En cas d'erreur, charger depuis le local
      await loadVotesFromLocal();
      await _enrichVotesWithLocalChoices();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UTILITAIRES ====================

  Future<SubjectModel?> getVoteByIdAsync(String id) async {
    try {
      // 1. Chercher localement
      final localVote = allVotes.firstWhere((v) => v.id == id);
      final localChoice = await _storage.getUserVoteChoice(id);

      if (localChoice != null) {
        return localVote.copyWith(
          myVoteChoiceIndex: localChoice.toString(),
        );
      }

      return localVote;
    } catch (e) {
      // 2. Si pas trouvé localement, charger depuis le backend
      print('⚠️ Vote non trouvé localement, chargement depuis le backend...');
      return await loadVoteFromBackend(id);
    }
  }

  SubjectModel? getVoteById(String id) {
    try {
      return allVotes.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  void _resetForm() {
    title = "";
    description = "";
    startingDate = DateTime.now();
    deadline = null;
    choices = [ChoiceModel(name: "", id: ''), ChoiceModel(name: "", id: '')];
    isAnonymous = true;
    isPrivate = true;
  }

  Future<bool> updateVote(SubjectModel updatedVote) async {
    try {
      isLoading = true;
      notifyListeners();

      final index = allVotes.indexWhere((v) => v.id == updatedVote.id);
      if (index == -1) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      final permission = PermissionService.canEditVote(updatedVote, currentUserId);
      permission.throwIfDenied();

      final cleanTitle = InputValidationService.sanitizeTitle(updatedVote.title);
      final cleanDescription = InputValidationService.sanitizeDescription(updatedVote.description);

      allVotes[index] = updatedVote.copyWith(
        title: cleanTitle,
        description: cleanDescription,
      );

      await _saveVotesToLocal();

      PermissionService.logSecurityAction(
        userId: currentUserId,
        action: 'UPDATE_VOTE',
        voteId: updatedVote.id,
        allowed: true,
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de la mise à jour: $e');
      return false;
    }

  }
  // ==================== MÉTHODES À AJOUTER DANS VoteViewModel ====================

  /// 🔥 NOUVEAU : Modifier un vote via l'API
  Future<bool> updateVoteOnBackend({
    required String voteId,
    required String title,
    String? description,
    required DateTime deadline,
    required List<String> choices,
    required bool isAnonymous,
    required bool isPrivate,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      // 🔥 Appel API pour modifier
      final response = await _apiService.updateElection(
        subjectId: voteId,
        title: title,
        description: description,
        deadline: deadline,
        anonymous: isAnonymous,
        isPrivate: isPrivate,
        choices: choices,
      );

      if (response['success'] == true) {
        // Mettre à jour localement aussi
        final index = allVotes.indexWhere((v) => v.id == voteId);
        if (index != -1) {
          allVotes[index] = allVotes[index].copyWith(
            title: title,
            description: description,
            deadline: deadline,
            choices: choices.map((name) => ChoiceModel(name: name, id: '', voteCount: 0)).toList(),
            isAnonymous: isAnonymous,
            isPrivate: isPrivate,
          );

          await _saveVotesToLocal();
        }

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Erreur de modification');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de la modification: $e');
      return false;
    }
  }

  /// 🔥 NOUVEAU : Supprimer un vote via l'API
  Future<bool> deleteVoteOnBackend(String voteId) async {
    try {
      isLoading = true;
      notifyListeners();

      // 🔥 Appel API pour supprimer
      final response = await _apiService.deleteElection(voteId);

      if (response['success'] == true) {
        // Supprimer localement aussi
        allVotes.removeWhere((v) => v.id == voteId);
        await _saveVotesToLocal();

        // Supprimer le choix local si existant
        await _storage.deleteUserVoteChoice(voteId);

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Erreur de suppression');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// 🔥 NOUVEAU : Obtenir les résultats d'un vote depuis l'API
  Future<Map<String, dynamic>?> getVoteResults(String voteId) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await _apiService.getElectionResults(voteId);

      isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        return response['results'];
      }

      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de la récupération des résultats: $e');
      return null;
    }
  }
}