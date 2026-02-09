
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../../../core/services/storage_service.dart';
import '../model/subject_model.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/input_validation_service.dart';
import '../../../core/services/permission_service.dart';

class VoteViewModel extends ChangeNotifier {
  // SERVICES DE SÉCURITÉ
  final EncryptionService _encryptionService = EncryptionService();

  // STOCKAGE SÉCURISÉ
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _storage = StorageService();

  // SIMULATION UTILISATEUR (FRONT)
  String currentUserId = "user_123";
  String currentUserName = "Utilisateur Test";

  // BASE DE DONNÉES LOCALE (RAM)
  List<SubjectModel> allVotes = [];

  // ÉTAT DE CHARGEMENT
  bool isLoading = false;

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


  // INITIALISATION : Charger les données au démarrage


  /// Appeler au démarrage de l'app
  Future<void> init() async {
    await loadUserData();
    await loadVotesFromLocal();
    // NOUVEAU : Enrichir avec choix locaux
    await _enrichVotesWithLocalChoices();
  }

  /// Charger les données utilisateur (depuis SecureStorage)
  Future<void> loadUserData() async {
    try {
      // Charger l'ID utilisateur (chiffré)
      final userId = await _secureStorage.read(key: 'userId');
      if (userId == null) {
        // Utiliser le StorageService pour générer un ID
        currentUserId = await _storage.getUserId();
        await _secureStorage.write(key: 'userId', value: currentUserId);
      } else {
        currentUserId = userId;
      }

      // Charger le nom (chiffré)
      final userName = await _secureStorage.read(key: 'userName');
      if (userName == null) {
        // Utiliser le StorageService
        currentUserName = await _storage.getUserName() ?? 'Utilisateur Test';
        await _secureStorage.write(key: 'userName', value: currentUserName);
      } else {
        currentUserName = userName;
      }

      // Charger le token JWT (chiffré)
      final token = await _secureStorage.read(key: 'authToken');
      if (token != null) {
        print(' Token chargé: ${token.substring(0, 20)}...');
      }

      print(' Utilisateur chargé: $currentUserName ($currentUserId)');
    } catch (e) {
      print(' Erreur lors du chargement des données utilisateur: $e');
    }
  }

  /// Sauvegarder les données utilisateur (dans SecureStorage)
  Future<void> saveUserData({
    required String userId,
    required String userName,
    String? authToken,
  }) async {
    try {
      // Sauvegarder de manière CHIFFRÉE
      await _secureStorage.write(key: 'userId', value: userId);
      await _secureStorage.write(key: 'userName', value: userName);

      if (authToken != null) {
        await _secureStorage.write(key: 'authToken', value: authToken);
      }

      currentUserId = userId;
      currentUserName = userName;

      notifyListeners();
    } catch (e) {
      print(' Erreur lors de la sauvegarde des données utilisateur: $e');
    }
  }

  /// Charger les votes depuis SharedPreferences
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

        print(' ${allVotes.length} votes chargés depuis le stockage local');
      } else {
        print('  Aucun vote en stockage local');
      }
    } catch (e) {
      print(' Erreur lors du chargement des votes: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }




  /// Charger les choix de votes depuis le stockage local sécurisé
  Future<void> _enrichVotesWithLocalChoices() async {
    try {
      print(' Enrichissement des votes avec les choix locaux...');

      for (int i = 0; i < allVotes.length; i++) {
        final voteId = allVotes[i].id;

        // Lire le choix local depuis StorageService
        final localChoice = await _storage.getUserVoteChoice(voteId);

        if (localChoice != null) {
          // Mettre à jour le vote avec le choix local
          allVotes[i] = allVotes[i].copyWith(
            myVoteChoiceIndex: localChoice.toString(),
          );
          print(' Choix local chargé : $voteId → choix $localChoice');
        }
      }

      print(' Enrichissement terminé');
      notifyListeners();
    } catch (e) {
      print(' Erreur lors de l\'enrichissement : $e');
    }
  }

  // Sauvegarder les votes dans SharedPreferences
  Future<void> _saveVotesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir en JSON
      final votesJson = allVotes.map((vote) => vote.toJson()).toList();

      // Sauvegarder
      await prefs.setString('votes', json.encode(votesJson));

      print(' ${allVotes.length} votes sauvegardés localement');
    } catch (e) {
      print(' Erreur lors de la sauvegarde des votes: $e');
    }
  }

  /// Effacer toutes les données (logout)
  Future<void> clearAllData() async {
    try {
      // Effacer SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Effacer SecureStorage
      await _secureStorage.deleteAll();

      //  NOUVEAU : Effacer les votes locaux du StorageService
      await _storage.clearAllUserVotes();

      // Réinitialiser la RAM
      allVotes = [];
      currentUserId = "user_123";
      currentUserName = "Utilisateur Test";

      notifyListeners();

      print(' Toutes les données effacées');
    } catch (e) {
      print(' Erreur lors de l\'effacement des données: $e');
    }
  }


  // GETTERS POUR LES FILTRES (identique à votre code)


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


  // ACTIONS FORMULAIRE (identique à votre code)


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


  // CRÉATION DE SCRUTIN SÉCURISÉ (votre code + sauvegarde)


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

      // 1. VALIDATION DES ENTRÉES
      final cleanTitle = InputValidationService.sanitizeTitle(title);
      final cleanDescription = InputValidationService.sanitizeDescription(description);
      final cleanChoices = InputValidationService.sanitizeChoices(validChoices);

      // 2. VALIDER LES DATES
      InputValidationService.validateDates(startingDate, deadline!);

      // 3. RATE LIMITING
      InputValidationService.checkRateLimit(currentUserId);

      // 4. CRÉER L'OBJET VOTE
      final voteData = {
        'title': cleanTitle,
        'description': cleanDescription,
        'startingDate': startingDate.toIso8601String(),
        'deadline': deadline!.toIso8601String(),
        'choices': cleanChoices,
        'isAnonymous': isAnonymous,
        'isPrivate': isPrivate,
        'creatorId': currentUserId,
      };

      // 5. VALIDATION COMPLÈTE
      InputValidationService.validateVoteObject(voteData);

      // 6. CHIFFREMENT DES DONNÉES
      final encryptedData = _encryptionService.encryptVoteData(voteData);

      // 7. GÉNÉRER UN HASH D'INTÉGRITÉ
      final dataHash = _encryptionService.generateDataHash(voteData);

      // 8. SIMULATION D'APPEL API
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Remplacer par appel API réel
      // final response = await _apiService.createVote(encryptedData, dataHash);

      // 9. CRÉER LE VOTE LOCALEMENT
      final newVote = SubjectModel(
        creatorId: currentUserId,
        title: cleanTitle,
        description: cleanDescription,
        startingDate: startingDate,
        deadline: deadline!,
        choices: cleanChoices.map((name) => ChoiceModel(name: name, voteCount: 0)).toList(),
        isAnonymous: isAnonymous,
        isPrivate: isPrivate,
        participantCount: 0,
        voteCount: 0,
      );

      allVotes.insert(0, newVote);

      // 10. SAUVEGARDER LOCALEMENT
      await _saveVotesToLocal();

      final link = "https://securevote.app/vote/${newVote.id}";

      // 11. LOGGING SÉCURISÉ
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
    } on ValidationException catch (e) {
      isLoading = false;
      notifyListeners();
      print(' Erreur de validation: $e');
      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print(' Erreur lors de la création du vote: $e');
      return null;
    }
  }

  // VOTER AVEC SÉCURITÉ + STOCKAGE LOCAL


  Future<bool> castVote(SubjectModel vote, int choiceIndex) async {
    try {
      isLoading = true;
      notifyListeners();

      // VÉRIFIER LES PERMISSIONS
      final permission = PermissionService.canCastVote(vote, currentUserId);
      permission.throwIfDenied();

      // VALIDER L'INDEX DU CHOIX
      InputValidationService.validateChoiceIndex(choiceIndex, vote.choices.length);

      // RATE LIMITING
      InputValidationService.checkRateLimit(currentUserId);

      // CHIFFRER LE VOTE
      final encryptedVote = _encryptionService.encryptVoteChoice(
        choiceIndex,
        currentUserId,
      );

      // HASHER L'ID POUR L'ANONYMAT
      final anonymousId = vote.isAnonymous
          ? _encryptionService.hashVoterId(currentUserId)
          : currentUserId;

      // SIMULATION D'APPEL API
      await Future.delayed(const Duration(milliseconds: 800));
      // TODO: Remplacer par appel API réel


      //  NOUVEAU : SAUVEGARDER LE CHOIX LOCALEMENT


      await _storage.saveUserVoteChoice(vote.id, choiceIndex);
      print(' Choix sauvegardé localement : ${vote.id} → $choiceIndex');

      // MISE À JOUR LOCALE
      final index = allVotes.indexWhere((v) => v.id == vote.id);
      if (index == -1) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      allVotes[index].recordVote(choiceIndex, currentUserId, currentUserName);

      // Mettre à jour myVoteChoiceIndex pour l'UI
      allVotes[index] = allVotes[index].copyWith(
        myVoteChoiceIndex: choiceIndex.toString(),
      );

      // SAUVEGARDER LA LISTE DES VOTES
      await _saveVotesToLocal();

      // LOGGING
      PermissionService.logSecurityAction(
        userId: currentUserId,
        action: 'CAST_VOTE',
        voteId: vote.id,
        allowed: true,
      );

      isLoading = false;
      notifyListeners();
      return true;
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

      print(' Permission refusée: $e');
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print(' Erreur lors du vote: $e');
      return false;
    }
  }


  // MODIFIER UN VOTE (votre code + sauvegarde)


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

      // VÉRIFIER LES PERMISSIONS
      final permission = PermissionService.canEditVote(updatedVote, currentUserId);
      permission.throwIfDenied();

      // VALIDATION
      final cleanTitle = InputValidationService.sanitizeTitle(updatedVote.title);
      final cleanDescription = InputValidationService.sanitizeDescription(updatedVote.description);

      // MISE À JOUR LOCALE
      allVotes[index] = updatedVote.copyWith(
        title: cleanTitle,
        description: cleanDescription,
      );

      // SAUVEGARDER LOCALEMENT
      await _saveVotesToLocal();

      // LOGGING
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
      print(' Erreur lors de la mise à jour: $e');
      return false;
    }
  }


  //  NOUVEAU : UTILITAIRES avec chargement du choix local

  /// Récupérer un vote par son ID (avec choix local pré-chargé)
  /// Version asynchrone pour charger le choix depuis le storage
  Future<SubjectModel?> getVoteByIdAsync(String id) async {
    try {
      final vote = allVotes.firstWhere((v) => v.id == id);

      // Charger le choix local
      final localChoice = await _storage.getUserVoteChoice(id);

      if (localChoice != null) {
        print(' Choix local trouvé : $id → $localChoice');

        // Retourner le vote avec le choix pré-rempli
        return vote.copyWith(
          myVoteChoiceIndex: localChoice.toString(),
        );
      }

      return vote;
    } catch (e) {
      print(' Vote introuvable : $e');
      return null;
    }
  }

  /// Version synchrone (pour compatibilité avec votre code existant)
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
    choices = [ChoiceModel(name: ""), ChoiceModel(name: "")];
    isAnonymous = true;
    isPrivate = true;
  }

  Future<void> refreshVotes() async {
    isLoading = true;
    notifyListeners();

    try {
      // TODO: Appel API quand backend prêt
      await Future.delayed(const Duration(seconds: 1));
      await loadVotesFromLocal();

      //  NOUVEAU : Enrichir avec les choix locaux après refresh
      await _enrichVotesWithLocalChoices();
    } catch (e) {
      print(' Erreur lors du rafraîchissement: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}