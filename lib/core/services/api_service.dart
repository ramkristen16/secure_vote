
import 'package:dio/dio.dart';
import 'encryption_service.dart';
import 'input_validation_service.dart';

// Service API avec Dio et chiffrement automatique via Interceptors
class ApiService {
  static const String baseUrl = 'https://votre-api.com/api';

  late final Dio _dio;
  final EncryptionService _encryptionService = EncryptionService();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // INTERCEPTORS : Chiffrement/Déchiffrement automatique
    _dio.interceptors.add(_EncryptionInterceptor(_encryptionService));

    // INTERCEPTOR : Logging (debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // INTERCEPTOR : Retry automatique
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  // Définir le token JWT
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  // VOTES


  // Créer un vote
  Future<ApiResponse<Map<String, dynamic>>> createVote({
    required String title,
    String? description,
    required DateTime startingDate,
    required DateTime deadline,
    required List<String> choices,
    required bool isAnonymous,
    required bool isPrivate,
    required String creatorId,
  }) async {
    try {
      // Validation
      final cleanTitle = InputValidationService.sanitizeTitle(title);
      final cleanDescription = InputValidationService.sanitizeDescription(description);
      final cleanChoices = InputValidationService.sanitizeChoices(choices);
      InputValidationService.validateDates(startingDate, deadline);

      final data = {
        'title': cleanTitle,
        'description': cleanDescription,
        'startingDate': startingDate.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'choices': cleanChoices,
        'isAnonymous': isAnonymous,
        'isPrivate': isPrivate,
        'creatorId': creatorId,
      };

      // L'interceptor chiffre automatiquement
      final response = await _dio.post('/votes', data: data);

      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } on ValidationException catch (e) {
      return ApiResponse.error(e.message);
    }
  }

  // Récupérer mes votes
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyVotes(String userId) async {
    try {
      // L'interceptor déchiffre automatiquement
      final response = await _dio.get('/votes/my/$userId');

      final votes = (response.data['votes'] as List)
          .map((v) => v as Map<String, dynamic>)
          .toList();

      return ApiResponse.success(votes);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Récupérer mes invitations
  Future<ApiResponse<List<Map<String, dynamic>>>> getInvitations(String userId) async {
    try {
      final response = await _dio.get('/votes/invitations/$userId');

      final invitations = (response.data['invitations'] as List)
          .map((v) => v as Map<String, dynamic>)
          .toList();

      return ApiResponse.success(invitations);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Modifier un vote
  Future<ApiResponse<Map<String, dynamic>>> updateVote({
    required String voteId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      InputValidationService.validateVoteObject(updateData);

      // L'interceptor chiffre automatiquement
      final response = await _dio.put('/votes/$voteId', data: updateData);

      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } on ValidationException catch (e) {
      return ApiResponse.error(e.message);
    }
  }

  // Supprimer un vote
  Future<ApiResponse<bool>> deleteVote(String voteId) async {
    try {
      await _dio.delete('/votes/$voteId');
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }


  // VOTING


  // Voter
  Future<ApiResponse<Map<String, dynamic>>> castVote({
    required String voteId,
    required int choiceIndex,
    required String voterId,
    required bool isAnonymous,
  }) async {
    try {
      final encryptedVote = _encryptionService.encryptVoteChoice(
        choiceIndex,
        voterId,
      );

      final anonymousId = isAnonymous
          ? _encryptionService.hashVoterId(voterId)
          : voterId;

      final response = await _dio.post(
        '/votes/$voteId/cast',
        data: {
          'encryptedVote': encryptedVote,
          'voterId': anonymousId,
        },
      );

      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Récupérer les résultats
  Future<ApiResponse<Map<String, dynamic>>> getVoteResults(String voteId) async {
    try {
      final response = await _dio.get('/votes/$voteId/results');

      // Déchiffrer les résultats
      final decryptedResults = _encryptionService.decryptVoteData(
          response.data['encryptedResults']
      );

      return ApiResponse.success(decryptedResults);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // INVITATIONS


  // Inviter des participants
  Future<ApiResponse<bool>> inviteParticipants({
    required String voteId,
    required List<String> emails,
  }) async {
    try {
      final cleanEmails = emails
          .map((e) => InputValidationService.sanitizeEmail(e))
          .toList();

      await _dio.post(
        '/votes/$voteId/invite',
        data: {'emails': cleanEmails},
      );

      return ApiResponse.success(true);
    } on DioException catch (e) {
      return _handleDioError(e);
    } on ValidationException catch (e) {
      return ApiResponse.error(e.message);
    }
  }

  // AUTHENTIFICATION


  // Login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Stocker le token
      final token = response.data['token'];
      setAuthToken(token);

      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }


  // GESTION DES ERREURS


  ApiResponse<T> _handleDioError<T>(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connexion expirée. Vérifiez votre connexion internet.';
        break;

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 401) {
          message = 'Session expirée. Veuillez vous reconnecter.';
        } else if (statusCode == 403) {
          message = 'Vous n\'avez pas la permission d\'effectuer cette action.';
        } else if (statusCode == 404) {
          message = 'Ressource introuvable.';
        } else if (statusCode == 500) {
          message = 'Erreur serveur. Réessayez plus tard.';
        } else {
          message = data?['message'] ?? 'Erreur inconnue';
        }
        break;

      case DioExceptionType.cancel:
        message = 'Requête annulée.';
        break;

      case DioExceptionType.connectionError:
        message = 'Pas de connexion internet.';
        break;

      default:
        message = 'Erreur: ${e.message}';
    }

    return ApiResponse.error(message);
  }
}

// INTERCEPTOR : Chiffrement/Déchiffrement automatique


class _EncryptionInterceptor extends Interceptor {
  final EncryptionService _encryptionService;

  _EncryptionInterceptor(this._encryptionService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // CHIFFRER les données pour POST/PUT/DELETE
    if (options.method == 'POST' ||
        options.method == 'PUT' ||
        options.method == 'DELETE') {

      if (options.data != null && options.data is Map) {
        try {
          // Exceptions : login/register ne chiffrent pas
          if (!options.path.contains('/auth/')) {
            final data = options.data as Map<String, dynamic>;
            final encryptedData = _encryptionService.encryptVoteData(data);
            final dataHash = _encryptionService.generateDataHash(data);

            options.data = {
              'encryptedData': encryptedData,
              'dataHash': dataHash,
            };
          }
        } catch (e) {
          print('Erreur chiffrement: $e');
        }
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // DÉCHIFFRER les données pour GET
    if (response.requestOptions.method == 'GET') {
      try {
        // Si la réponse contient des données chiffrées
        if (response.data is Map &&
            response.data['encryptedData'] != null) {

          final decrypted = _encryptionService.decryptVoteData(
              response.data['encryptedData']
          );

          // Vérifier l'intégrité
          if (response.data['dataHash'] != null) {
            final isValid = _encryptionService.verifyDataIntegrity(
              decrypted,
              response.data['dataHash'],
            );

            if (!isValid) {
              print('Données corrompues détectées');
            }
          }

          response.data = decrypted;
        }
      } catch (e) {
        print('Erreur déchiffrement: $e');
      }
    }

    handler.next(response);
  }
}


// INTERCEPTOR : Retry automatique


class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int maxRetries = 3;

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Retry uniquement pour les erreurs de connexion
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {

      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        print(' Retry ${retryCount + 1}/$maxRetries...');

        err.requestOptions.extra['retryCount'] = retryCount + 1;

        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: retryCount + 1));

        try {
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // Continue avec l'erreur
        }
      }
    }

    handler.next(err);
  }
}


// Classe de réponse API


class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }
  factory ApiResponse.error(String message) {
    return ApiResponse._(
      error: message,
      isSuccess: false,
    );
  }
}