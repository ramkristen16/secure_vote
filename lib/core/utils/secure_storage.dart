

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // TOKEN

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.token, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.token);
  }

  Future<bool> hasToken() async {
    return await _storage.containsKey(key: StorageKeys.token);
  }


  // USER ID (NOUVEAU)


  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: StorageKeys.userId);
  }


  // USER NAME (NOUVEAU)


  Future<void> saveUserName(String name) async {
    await _storage.write(key: StorageKeys.userName, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: StorageKeys.userName);
  }

  Future<void> deleteUserName() async {
    await _storage.delete(key: StorageKeys.userName);
  }


  // USER EMAIL (NOUVEAU)


  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: StorageKeys.userEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: StorageKeys.userEmail);
  }

  Future<void> deleteUserEmail() async {
    await _storage.delete(key: StorageKeys.userEmail);
  }


  // CLEAR ALL (LOGOUT COMPLET)


  Future<void> clearAll() async {
    await deleteToken();
    await deleteUserId();
    await deleteUserName();
    await deleteUserEmail();
  }
}