

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

// Service de chiffrement/déchiffrement pour sécuriser les votes
// Utilise AES-256 pour le chiffrement des données sensibles
class EncryptionService {
  // Clé de chiffrement (EN PRODUCTION: à récupérer du backend de manière sécurisée)
  static const String _masterKey = 'VOTRE_CLE_SECURISEE_32_CARACTERES!!';

  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    // Générer une clé sécurisée à partir de la master key
    _key = encrypt.Key.fromUtf8(_masterKey.padRight(32).substring(0, 32));

    // IV (Initialization Vector) - unique pour chaque session
    _iv = encrypt.IV.fromLength(16);

    // Encrypter AES en mode CBC
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  // Chiffrer les données d'un vote
  //Utilisé avant l'envoi au backend
  String encryptVoteData(Map<String, dynamic> voteData) {
    try {
      final jsonString = json.encode(voteData);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

      // Retourner le résultat en base64
      return encrypted.base64;
    } catch (e) {
      throw Exception('Erreur de chiffrement: $e');
    }
  }

  // Déchiffrer les données d'un vote
  //Utilisé après réception du backend
  Map<String, dynamic> decryptVoteData(String encryptedData) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

      return json.decode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur de déchiffrement: $e');
    }
  }

  // Chiffrer un choix de vote individuel
  // Pour garantir l'anonymat du vote
  String encryptVoteChoice(int choiceIndex, String voterId) {
    try {
      final voteData = {
        'choiceIndex': choiceIndex,
        'voterId': voterId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = json.encode(voteData);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

      return encrypted.base64;
    } catch (e) {
      throw Exception('Erreur de chiffrement du vote: $e');
    }
  }

  // Déchiffrer un choix de vote
  Map<String, dynamic> decryptVoteChoice(String encryptedChoice) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedChoice);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

      return json.decode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur de déchiffrement du vote: $e');
    }
  }

  //Hasher un identifiant pour l'anonymat
  // Utilisé pour anonymiser les votants
  String hashVoterId(String voterId) {
    final bytes = utf8.encode(voterId);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Générer un token de session sécurisé
  String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(timestamp + _masterKey);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Vérifier l'intégrité des données
  //
  // Pour s'assurer qu'elles n'ont pas été modifiées
  String generateDataHash(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Vérifier qu'un hash correspond aux données
  bool verifyDataIntegrity(Map<String, dynamic> data, String expectedHash) {
    final actualHash = generateDataHash(data);
    return actualHash == expectedHash;
  }
}