
import 'package:dio/dio.dart';

import '../utils/secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://secure-vote-f4mp.onrender.com';

  late Dio _dio;
  final SecureStorage _storage = SecureStorage();

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

    // Intercepteur pour ajouter automatiquement le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print(' ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(' ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print(' ${error.response?.statusCode} ${error.requestOptions.path}');
          print('   ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  // GET / - Welcome message
  Future<Map<String, dynamic>> getWelcome() async {
    try {
      final response = await _dio.get('/');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur'};
    }
  }

  //GET /status - App status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get('/status');
      return response.data;
    } catch (e) {
      return {'status': 'error'};
    }
  }

  // GET /health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

    Map<String, dynamic> _handleAuthError(DioException e) {
      String errorMessage = 'Erreur réseau';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Le serveur met trop de temps à répondre.\n\n'
            'Render démarre peut-être l\'application.\n'
            'Réessayez dans 30-60 secondes.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Impossible de contacter le serveur.\n\n'
            'Vérifiez votre connexion internet.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Email ou mot de passe incorrect';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'Un compte avec cette adresse email existe déjà';
      } else if (e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? e.response?.data['error'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }

  // AUTH ENDPOINTS (/api/v1/auth)


  // POST /api/v1/auth/sign-up
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/sign-up',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        final token = data['accessToken'] ?? data['token'];
        final userId = data['id'] ?? data['_id'] ?? data['user']?['id'];
        final userName = data['name'] ?? data['fullName'] ?? data['user']?['fullName'] ?? 'User';
        final userEmail = data['email'] ?? data['user']?['email'] ?? email;

        if (token != null) {
          await _storage.saveToken(token);
        }
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        if (userName != null) {
          await _storage.saveUserName(userName);
        }
        if (userEmail != null) {
          await _storage.saveUserEmail(userEmail);
        }

        return {
          'success': true,
          'user': {
            'id': data['id'] ?? data['_id'] ?? data['user']?['id'],
            'name': data['name'] ?? data['fullName'] ?? data['user']?['fullName'] ?? name,
            'email': data['email'] ?? data['user']?['email'] ?? email,
            'role': data['role'] ?? data['user']?['role'] ?? 'voter',
            'token': token,
          },
        };
      }

      return {'success': false, 'message': 'Erreur lors de l\'inscription'};
    } on DioException catch (e) {
      return _handleAuthError(e);
    }
  }

  // POST /api/v1/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final token = data['accessToken'] ?? data['token'];
        final userId = data['id'] ?? data['_id'] ?? data['user']?['id'];
        final userName = data['name'] ?? data['fullName'] ?? data['user']?['fullName'] ?? 'User';
        final userEmail = data['email'] ?? data['user']?['email'] ?? email;

        if (token != null) {
          await _storage.saveToken(token);
        }
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        if (userName != null) {
          await _storage.saveUserName(userName);
        }
        if (userEmail != null) {
          await _storage.saveUserEmail(userEmail);
        }

        return {
          'success': true,
          'user': {
            'id': data['id'] ?? data['_id'] ?? data['user']?['id'],
            'name': data['name'] ?? data['fullName'] ?? data['user']?['fullName'] ?? 'User',
            'email': data['email'] ?? data['user']?['email'] ?? email,
            'role': data['role'] ?? data['user']?['role'] ?? 'voter',
            'token': token,
          },
        };
      }

      return {'success': false, 'message': 'Identifiants incorrects'};
    } on DioException catch (e) {
      return _handleAuthError(e);
    }
  }

  // POST /api/v1/auth/logout
  Future<bool> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
      await _storage.clearAll(); // Utilise la méthode qui nettoie tout
      return true;
    } catch (e) {
      print(' Erreur logout: $e');
      await _storage.clearAll(); // Nettoie tout même en cas d'erreur
      return false;
    }
  }

  /// POST /api/v1/auth/refresh
  Future<String?> refreshToken() async {
    try {
      final response = await _dio.post('/api/v1/auth/refresh');

      if (response.statusCode == 200) {
        final newToken = response.data['accessToken'];
        await _storage.saveToken(newToken);
        return newToken;
      }

      return null;
    } catch (e) {
      print('❌ Erreur refresh token: $e');
      return null;
    }
  }


  // ELECTIONS ENDPOINTS (/api/v1/elections)


  // POST /api/v1/elections - Create election
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

        return {
          'success': true,
          'subject': data['subject'],
          'choices': data['choices'],
          'link': data['link'],
        };
      }

      return {'success': false};
    } on DioException catch (e) {
      print('❌ Erreur création élection: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur',
      };
    }
  }

  // GET /api/v1/elections/created - Get created elections
  Future<List<Map<String, dynamic>>> getCreatedElections() async {
    try {
      final response = await _dio.get('/api/v1/elections/created');

      if (response.statusCode == 200) {
        final subjects = response.data['subjects'] as List;
        return subjects.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('❌ Erreur récupération élections: $e');
      return [];
    }
  }

  // GET /api/v1/elections/participation - Get participating elections
  Future<List<Map<String, dynamic>>> getParticipatingElections() async {
    try {
      final response = await _dio.get('/api/v1/elections/participation');

      if (response.statusCode == 200) {
        final invitations = response.data['invitations'] as List;
        return invitations.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('❌ Erreur récupération participations: $e');
      return [];
    }
  }

  // GET /api/v1/elections/:subjectId/link - Get election link
  Future<String?> getElectionLink(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/link');

      if (response.statusCode == 200) {
        return response.data['link'];
      }

      return null;
    } catch (e) {
      print('❌ Erreur link: $e');
      return null;
    }
  }

  // GET /api/v1/elections/:subjectId/details - Get election details
  Future<Map<String, dynamic>?> getElectionDetails(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/details');

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      print('❌ Erreur details: $e');
      return null;
    }
  }

  // GET /api/v1/elections/:subjectId/participants - Get participants
  Future<Map<String, dynamic>?> getElectionParticipants(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/participants');

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      print('❌ Erreur participants: $e');
      return null;
    }
  }

  // GET /api/v1/elections/:subjectId/results - Get results
  Future<Map<String, dynamic>?> getElectionResults(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/results');

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } catch (e) {
      print('❌ Erreur résultats: $e');
      return null;
    }
  }

  // GET /api/v1/elections/:subjectId/welcome - Get election welcome
  Future<Map<String, dynamic>?> getElectionWelcome(String subjectId) async {
    try {
      final response = await _dio.get('/api/v1/elections/$subjectId/welcome');

      if (response.statusCode == 200) {
        return response.data['subject'];
      }

      return null;
    } catch (e) {
      print('❌ Erreur welcome: $e');
      return null;
    }
  }

  // GET /api/v1/elections/:subjectId/register - Register as participant
  Future<bool> registerForElection(String subjectId) async {
    try {
      print(' [API] Inscription au vote $subjectId...');

      final response = await _dio.get('/api/v1/elections/$subjectId/register');

      if (response.statusCode == 200) {
        print(' [API] Inscription réussie');
        return true;
      }

      return false;

    } on DioException catch (e) {
      // Si déjà inscrit, ce n'est pas une erreur
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message']?.toString().toLowerCase() ?? '';

        if (message.contains('déjà') || message.contains('already')) {
          print('  [API] Déjà inscrit');
          return true;
        }
      }

      print('[API] Erreur register: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }

  /// POST /api/v1/elections/:subjectId/vote - Vote for election
  Future<bool> voteForElection({
    required String subjectId,
    required String choiceId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/elections/$subjectId/vote',
        data: {'choiceId': choiceId},
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print('❌ Erreur vote: ${e.response?.data}');
      return false;
    }
  }

}