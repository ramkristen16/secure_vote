import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service API pour SecureVote
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://secure-vote-f4mp.onrender.com';

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'authToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('🚀 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
          print('   ${error.response?.data}');

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              final newToken = await refreshToken();

              if (newToken != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                _isRefreshing = false;
                return handler.resolve(response);
              }
            } catch (e) {
              print('❌ Refresh token failed: $e');
            }

            _isRefreshing = false;
          }

          return handler.next(error);
        },
      ),
    );
  }

  String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Le serveur met trop de temps à répondre.\n\n'
          'Render démarre peut-être l\'application.\n'
          'Réessayez dans 30-60 secondes.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le serveur.\n\n'
          'Vérifiez votre connexion internet.';
    } else if (e.response?.statusCode == 401) {
      return 'Email ou mot de passe incorrect';
    } else if (e.response?.statusCode == 409) {
      return 'Un compte avec cette adresse email existe déjà';
    } else if (e.response?.data != null) {
      return e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Une erreur est survenue';
    }
    return 'Une erreur est survenue';
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== AUTH ENDPOINTS (AVEC 2FA) ====================

  /// 🔥 ÉTAPE 1 : POST /api/v1/auth/sign-up/send-code
  Future<Map<String, dynamic>> signUpSendCode({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/sign-up/send-code',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Code envoyé',
          'code': response.data['code'], // En dev uniquement
        };
      }

      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 🔥 ÉTAPE 2 : POST /api/v1/auth/sign-up (AVEC code)
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/sign-up',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'code': code,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        final token = data['accessToken'];
        final userId = data['id'];
        final userName = data['name'];
        final userEmail = data['email'];

        // Sauvegarder
        if (token != null) {
          await _secureStorage.write(key: 'authToken', value: token);
        }
        if (userId != null) {
          await _secureStorage.write(key: 'userId', value: userId);
        }
        if (userName != null) {
          await _secureStorage.write(key: 'userName', value: userName);
        }
        if (userEmail != null) {
          await _secureStorage.write(key: 'userEmail', value: userEmail);
        }

        return {
          'success': true,
          'userId': userId,
          'userName': userName,
          'email': userEmail,
          'token': token,
          'message': 'Inscription réussie',
        };
      }

      return {
        'success': false,
        'message': 'Erreur lors de l\'inscription',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 🔥 ÉTAPE 1 : POST /api/v1/auth/login/send-code
  Future<Map<String, dynamic>> loginSendCode({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login/send-code',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Code envoyé',
          'code': response.data['code'], // En dev uniquement
        };
      }

      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// 🔥 ÉTAPE 2 : POST /api/v1/auth/login (AVEC code)
  Future<Map<String, dynamic>> login({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final token = data['accessToken'];
        final userId = data['id'];
        final userName = data['name'];
        final userEmail = data['email'];

        // Sauvegarder
        if (token != null) {
          await _secureStorage.write(key: 'authToken', value: token);
        }
        if (userId != null) {
          await _secureStorage.write(key: 'userId', value: userId);
        }
        if (userName != null) {
          await _secureStorage.write(key: 'userName', value: userName);
        }
        if (userEmail != null) {
          await _secureStorage.write(key: 'userEmail', value: userEmail);
        }

        return {
          'success': true,
          'userId': userId,
          'userName': userName,
          'email': userEmail,
          'token': token,
          'message': 'Connexion réussie',
        };
      }

      return {
        'success': false,
        'message': 'Identifiants incorrects',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      print('❌ Erreur logout: $e');
      await _secureStorage.deleteAll();
      return false;
    }
  }

  Future<String?> refreshToken() async {
    try {
      final response = await _dio.post('/api/v1/auth/refresh');

      if (response.statusCode == 200) {
        final newToken = response.data['accessToken'];
        if (newToken != null) {
          await _secureStorage.write(key: 'authToken', value: newToken);
          return newToken;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur refresh token: $e');
      return null;
    }
  }

  // ==================== ELECTIONS ENDPOINTS ====================

  Future<Map<String, dynamic>> createElection({
    required String title,
    String? description,
    required DateTime startingDate,
    required DateTime deadline,
    required bool anonymous,
    required bool isPrivate,
    required List<String> choices,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/elections',
        data: {
          'title': title,
          'description': description,
          'startingDate': startingDate.toUtc().toIso8601String(),
          'deadline': deadline.toUtc().toIso8601String(),
          'anonymous': anonymous,
          'isPrivate': isPrivate,
          'choices': choices,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'];
        final subject = data['subject'];

        return {
          'success': true,
          'subjectId': subject['id'],
          'title': subject['title'],
          'link': data['link'],
          'choices': subject['choices'] ?? data['choices'],
        };
      }

      return {'success': false, 'message': 'Erreur de création'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getCreatedElections() async {
    try {
      final response = await _dio.get('/api/v1/elections/created');

      if (response.statusCode == 200) {
        final subjects = response.data['subjects'] as List? ?? [];

        return {
          'success': true,
          'elections': subjects,
        };
      }

      return {'success': false, 'elections': []};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
        'elections': [],
      };
    }
  }

  Future<Map<String, dynamic>> getParticipatingElections() async {
    try {
      final response = await _dio.get('/api/v1/elections/participation');

      if (response.statusCode == 200) {
        final invitations = response.data['invitations'] as List? ?? [];

        return {
          'success': true,
          'invitations': invitations,
        };
      }

      return {'success': false, 'invitations': []};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
        'invitations': [],
      };
    }
  }

  Future<Map<String, dynamic>> getElectionWelcome(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/welcome');

      if (response.statusCode == 200) {
        final subject = response.data['subject'];

        return {
          'success': true,
          'election': subject,
        };
      }

      return {'success': false, 'message': 'Élection introuvable'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getElectionDetails(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'election': response.data,
        };
      }

      return {'success': false, 'message': 'Élection introuvable'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> registerForElection(String subjectId) async {
    try {
      print('📝 [API] Inscription au vote $subjectId...');

      final response = await _dio.get('/api/v1/elections/$subjectId/register');

      if (response.statusCode == 200) {
        print('✅ [API] Inscription réussie');
        return {
          'success': true,
          'message': 'Inscription réussie',
        };
      }

      return {'success': false, 'message': 'Erreur d\'inscription'};

    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message']?.toString().toLowerCase() ?? '';

        if (message.contains('déjà') || message.contains('already')) {
          print('ℹ️ [API] Déjà inscrit');
          return {
            'success': true,
            'message': 'Déjà inscrit',
          };
        }
      }

      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> voteForElection({
    required String subjectId,
    required String choiceId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/elections/$subjectId/vote',
        data: {'choiceId': choiceId},
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Vote enregistré',
        };
      }

      return {'success': false, 'message': 'Erreur lors du vote'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getElectionResults(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/results');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'results': response.data,
        };
      }

      return {'success': false, 'message': 'Résultats non disponibles'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getElectionLink(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/link');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'link': response.data['link'],
        };
      }

      return {'success': false, 'message': 'Lien non disponible'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> updateElection({
    required String subjectId,
    required String title,
    String? description,
    required DateTime deadline,
    required bool anonymous,
    required bool isPrivate,
    required List<String> choices,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/elections/$subjectId',
        data: {
          'title': title,
          'description': description,
          'deadline': deadline.toUtc().toIso8601String(),
          'anonymous': anonymous,
          'isPrivate': isPrivate,
          'choices': choices.map((name) => {'name': name}).toList(),
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Élection modifiée avec succès',
          'election': response.data,
        };
      }

      return {'success': false, 'message': 'Erreur de modification'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> deleteElection(String subjectId) async {
    try {
      final response = await _dio.delete('/api/v1/elections/$subjectId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Élection supprimée avec succès',
        };
      }

      return {'success': false, 'message': 'Erreur de suppression'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }
}