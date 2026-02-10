
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();


  /// Obtenir ou créer un ID utilisateur unique
  Future<String> getUserId() async {
    String? userId = await _secureStorage.read(key: 'user_id');

    if (userId == null) {
      // Générer un nouvel ID unique
      userId = _uuid.v4();
      await _secureStorage.write(key: 'user_id', value: userId);
    }

    return userId;
  }

  /// Sauvegarder le nom d'utilisateur
  Future<void> saveUserName(String userName) async {
    await _secureStorage.write(key: 'user_name', value: userName);
  }

  /// Obtenir le nom d'utilisateur
  Future<String?> getUserName() async {
    String? userName = await _secureStorage.read(key: 'user_name');

    if (userName == null) {
      // Nom par défaut
      userName = 'Utilisateur ${DateTime.now().millisecondsSinceEpoch % 10000}';
      await saveUserName(userName);
    }

    return userName;
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? name,
    String? email,
  }) async {
    if (name != null) {
      await _secureStorage.write(key: 'user_name', value: name);
    }
    if (email != null) {
      await _secureStorage.write(key: 'user_email', value: email);
    }
  }

  /// Obtenir l'email utilisateur
  Future<String?> getUserEmail() async {
    return await _secureStorage.read(key: 'user_email');
  }

  // ========== ENCRYPTION KEYS ==========

  /// Sauvegarder la clé de chiffrement
  Future<void> saveEncryptionKey(String key) async {
    await _secureStorage.write(key: 'encryption_key', value: key);
  }

  /// Obtenir ou générer une clé de chiffrement
  Future<String> getEncryptionKey() async {
    String? key = await _secureStorage.read(key: 'encryption_key');

    if (key == null) {
      // Générer une nouvelle clé
      key = _uuid.v4();
      await saveEncryptionKey(key);
    }

    return key;
  }


  /// Sauvegarder les données de rate limiting
  Future<void> saveRateLimitData(String userId, Map<String, dynamic> data) async {
    await _secureStorage.write(
      key: 'rate_limit_$userId',
      value: jsonEncode(data),
    );
  }

  /// Obtenir les données de rate limiting
  Future<Map<String, dynamic>?> getRateLimitData(String userId) async {
    final data = await _secureStorage.read(key: 'rate_limit_$userId');
    if (data == null) return null;

    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Nettoyer les anciennes données de rate limiting
  Future<void> cleanOldRateLimitData(String userId) async {
    await _secureStorage.delete(key: 'rate_limit_$userId');
  }


  Future<void> saveUserVoteChoice(String voteId, int choiceIndex) async {
    try {
      await _secureStorage.write(
        key: 'vote_choice_$voteId',
        value: choiceIndex.toString(),
      );
      print('Choix de vote sauvegardé localement : $voteId → choix $choiceIndex');

      // Ajouter aussi à l'historique
      await addToHistory(voteId);
    } catch (e) {
      print(' Erreur sauvegarde choix de vote : $e');
      rethrow;
    }
  }


  Future<int?> getUserVoteChoice(String voteId) async {
    try {
      final value = await _secureStorage.read(key: 'vote_choice_$voteId');
      if (value != null) {
        final index = int.tryParse(value);
        if (index != null) {
          print('Choix de vote lu : $voteId → choix $index');
          return index;
        }
      }
      return null;
    } catch (e) {
      print(' Erreur lecture choix de vote : $e');
      return null;
    }
  }


  Future<bool> hasUserVoted(String voteId) async {
    try {
      final value = await _secureStorage.read(key: 'vote_choice_$voteId');
      return value != null;
    } catch (e) {
      return false;
    }
  }


  Future<void> deleteUserVoteChoice(String voteId) async {
    try {
      await _secureStorage.delete(key: 'vote_choice_$voteId');
      print('🗑️  Choix de vote supprimé : $voteId');
    } catch (e) {
      print('❌ Erreur suppression choix de vote : $e');
    }
  }


  Future<Map<String, int>> getAllUserVotes() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final voteChoices = <String, int>{};

      for (var entry in allKeys.entries) {
        if (entry.key.startsWith('vote_choice_')) {
          final voteId = entry.key.replaceFirst('vote_choice_', '');
          final choiceIndex = int.tryParse(entry.value);
          if (choiceIndex != null) {
            voteChoices[voteId] = choiceIndex;
          }
        }
      }

      print(' ${voteChoices.length} vote(s) local(aux) trouvé(s)');
      return voteChoices;
    } catch (e) {
      print(' Erreur lecture tous les votes : $e');
      return {};
    }
  }


  Future<void> clearAllUserVotes() async {
    try {
      final allKeys = await _secureStorage.readAll();
      int count = 0;

      for (var key in allKeys.keys) {
        if (key.startsWith('vote_choice_')) {
          await _secureStorage.delete(key: key);
          count++;
        }
      }

      print('🧹 $count choix de vote(s) supprimé(s)');
    } catch (e) {
      print('❌ Erreur nettoyage votes : $e');
    }
  }

  ///
  /// Cette méthode remplace automatiquement l'ancien choix
  Future<void> updateUserVoteChoice(String voteId, int newChoiceIndex) async {
    // Pas besoin de supprimer l'ancien, write() écrase automatiquement
    await saveUserVoteChoice(voteId, newChoiceIndex);
    print('🔄 Choix de vote mis à jour : $voteId → nouveau choix $newChoiceIndex');
  }

  // FIN NOUVEAUTÉ VOTES



  /// Sauvegarder les votes en cache
  Future<void> cacheVotes(List<Map<String, dynamic>> votes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_votes', jsonEncode(votes));
    await prefs.setString('cache_timestamp', DateTime.now().toIso8601String());
  }

  /// Récupérer les votes en cache
  Future<List<Map<String, dynamic>>?> getCachedVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final votesJson = prefs.getString('cached_votes');

    if (votesJson == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(votesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // Vérifier si le cache est expiré (1 heure)
  Future<bool> isCacheExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString('cache_timestamp');

    if (timestampStr == null) return true;

    final timestamp = DateTime.parse(timestampStr);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return difference.inHours >= 1;
  }

  /// Effacer le cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_votes');
    await prefs.remove('cache_timestamp');
  }



  /// Sauvegarder les préférences
  Future<void> savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  /// Récupérer une préférence
  Future<dynamic> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  // Préférence: Thème sombre
  Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }

  // Activer/Désactiver le thème sombre
  Future<void> setDarkMode(bool enabled) async {
    await savePreference('dark_mode', enabled);
  }

  // Préférence: Notifications
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }

  //Activer/Désactiver les notifications
  Future<void> setNotifications(bool enabled) async {
    await savePreference('notifications', enabled);
  }



  // Ajouter un vote à l'historique
  Future<void> addToHistory(String voteId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('vote_history') ?? [];

    if (!history.contains(voteId)) {
      history.insert(0, voteId); // Ajouter au début

      // Garder seulement les 50 derniers
      if (history.length > 50) {
        history = history.sublist(0, 50);
      }

      await prefs.setStringList('vote_history', history);
    }
  }

  // Récupérer l'historique
  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('vote_history') ?? [];
  }

  // Effacer l'historique
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vote_history');
  }



  // Vérifier si c'est la première ouverture
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_launch') ?? true;
  }

  // Marquer l'onboarding comme complété
  Future<void> completeOnboarding() async {
    await savePreference('first_launch', false);
  }



  // Effacer toutes les données (Reset complet)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Effacer seulement les données sensibles
  Future<void> clearSensitiveData() async {
    await _secureStorage.deleteAll();
  }

  // Effacer seulement les votes (garder le reste)
  Future<void> clearVotesOnly() async {
    await clearAllUserVotes();
    await clearHistory();
  }



  // Afficher toutes les clés stockées (DEBUG ONLY)
  Future<void> debugPrintAll() async {
    print('=== SECURE STORAGE ===');
    final allKeys = await _secureStorage.readAll();
    allKeys.forEach((key, value) {
      print('$key: ${value.substring(0, value.length > 20 ? 20 : value.length)}...');
    });

    print('\n=== SHARED PREFERENCES ===');
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      print('$key: ${prefs.get(key)}');
    }

    print('\n=== VOTES LOCAUX ===');
    final votes = await getAllUserVotes();
    votes.forEach((voteId, choiceIndex) {
      print('$voteId → Choix $choiceIndex');
    });
  }
}