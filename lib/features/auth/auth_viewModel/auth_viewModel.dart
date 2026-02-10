import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth_model/auth_model.dart';
import '../../vote/view_model/vote_view_model.dart';
import '../../../core/services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final VoteViewModel voteViewModel;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthViewModel({required this.voteViewModel});

  bool _isAuthenticated = false;
  AuthUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get currentUser => _currentUser;

  // ==================== LOGIN ====================

  String _loginEmail = '';
  String _loginPassword = '';
  bool _isLoginLoading = false;
  String? _loginError;

  String get loginEmail => _loginEmail;
  String get loginPassword => _loginPassword;
  bool get isLoginLoading => _isLoginLoading;
  String? get loginError => _loginError;
  bool get canLogin => _loginEmail.isNotEmpty && _loginPassword.isNotEmpty && !_isLoginLoading;

  void updateLoginEmail(String value) {
    _loginEmail = value.trim().toLowerCase();
    _loginError = null;
    notifyListeners();
  }

  void updateLoginPassword(String value) {
    _loginPassword = value;
    _loginError = null;
    notifyListeners();
  }

  /// 🔥 ÉTAPE 1 : Vérifier credentials + envoyer code
  Future<LoginCredentialResponse?> submitLoginSendCode() async {
    if (!canLogin) {
      _loginError = 'Veuillez remplir tous les champs';
      notifyListeners();
      return null;
    }

    _isLoginLoading = true;
    _loginError = null;
    notifyListeners();

    try {
      // 🔥 Appel API : login/send-code
      final response = await _apiService.loginSendCode(
        email: _loginEmail,
        password: _loginPassword,
      );

      if (response['success'] == true) {
        // Retourner le code pour l'étape 2FA
        final mockResponse = LoginCredentialResponse(
          statusCode: 200,
          verificationToken: _loginEmail, // On garde l'email pour l'étape suivante
          message: response['message'] ?? 'Code envoyé par email',
        );

        _isLoginLoading = false;
        notifyListeners();
        return mockResponse;
      } else {
        throw Exception(response['message'] ?? 'Erreur de connexion');
      }

    } catch (e) {
      _loginError = e.toString().replaceAll('Exception: ', '');
      _isLoginLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== SIGNUP ====================

  String _signupEmail = '';
  String _signupFullName = '';
  String _signupPassword = '';
  String _signupConfirmPassword = '';
  bool _isSignupLoading = false;

  String? _emailError;
  String? _fullNameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _signupError;

  String get signupEmail => _signupEmail;
  String get signupFullName => _signupFullName;
  String get signupPassword => _signupPassword;
  String get signupConfirmPassword => _signupConfirmPassword;
  bool get isSignupLoading => _isSignupLoading;

  String? get emailError => _emailError;
  String? get fullNameError => _fullNameError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get signupError => _signupError;

  bool get canSignup =>
      _signupEmail.isNotEmpty &&
          _signupFullName.isNotEmpty &&
          _signupPassword.isNotEmpty &&
          _signupConfirmPassword.isNotEmpty &&
          _signupPassword == _signupConfirmPassword &&
          !_isSignupLoading &&
          _emailError == null &&
          _fullNameError == null &&
          _passwordError == null &&
          _confirmPasswordError == null;

  void updateSignupEmail(String value) {
    _signupEmail = value.trim();
    _emailError = _signupEmail.isEmpty
        ? null
        : RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_signupEmail)
        ? null
        : 'Email invalide';
    _signupError = null;
    notifyListeners();
  }

  void updateSignupFullName(String value) {
    _signupFullName = value.trim();
    _fullNameError = _signupFullName.isEmpty || _signupFullName.length >= 3
        ? null
        : 'Nom trop court';
    _signupError = null;
    notifyListeners();
  }

  void updateSignupPassword(String value) {
    _signupPassword = value;
    _passwordError = _validatePassword(value);
    if (_signupConfirmPassword.isNotEmpty) {
      _confirmPasswordError = _signupConfirmPassword == _signupPassword
          ? null
          : 'Les mots de passe ne correspondent pas';
    }
    _signupError = null;
    notifyListeners();
  }

  void updateSignupConfirmPassword(String value) {
    _signupConfirmPassword = value;
    _confirmPasswordError = value.isEmpty || value == _signupPassword
        ? null
        : 'Les mots de passe ne correspondent pas';
    _signupError = null;
    notifyListeners();
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return null;
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  /// 🔥 ÉTAPE 1 : Envoyer code signup
  Future<SignupResponse?> submitSignup() async {
    if (!canSignup) return null;

    _isSignupLoading = true;
    _signupError = null;
    notifyListeners();

    try {
      // 🔥 Appel API : sign-up/send-code
      final response = await _apiService.signUpSendCode(
        email: _signupEmail,
      );

      if (response['success'] == true) {
        final mockResponse = SignupResponse(
          statusCode: 200,
          message: response['message'] ?? 'Code envoyé par email',
          verificationToken: _signupEmail, // On garde l'email pour l'étape suivante
        );

        _isSignupLoading = false;
        notifyListeners();
        return mockResponse;
      } else {
        throw Exception(response['message'] ?? 'Erreur d\'inscription');
      }

    } catch (e) {
      _signupError = e.toString().replaceAll('Exception: ', '');
      _isSignupLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== 2FA ====================

  String _twoFACode = '';
  bool _isTwoFALoading = false;
  String? _twoFAError;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  String get twoFACode => _twoFACode;
  bool get isTwoFALoading => _isTwoFALoading;
  String? get twoFAError => _twoFAError;
  bool get canSubmitTwoFA => _twoFACode.length == 6 && !_isTwoFALoading;
  bool get isResending => _isResending;
  int get resendCountdown => _resendCountdown;
  bool get canResend => _resendCountdown == 0 && !_isResending;

  void updateTwoFACode(String value) {
    _twoFACode = value;
    _twoFAError = null;
    notifyListeners();
  }

  void startResendTimer() {
    _resendCountdown = 60;
    notifyListeners();

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// 🔥 ÉTAPE 2 : Vérifier le code 2FA et finaliser
  Future<bool> verify2FAAndLogin({
    required String verificationToken,
    required TwoFAMode mode,
  }) async {
    if (_twoFACode.length != 6) {
      _twoFAError = 'Le code doit contenir 6 chiffres';
      notifyListeners();
      return false;
    }

    _isTwoFALoading = true;
    _twoFAError = null;
    notifyListeners();

    try {
      Map<String, dynamic> response;

      if (mode == TwoFAMode.login) {
        // 🔥 Appel API : /auth/login (AVEC code)
        response = await _apiService.login(
          email: verificationToken, // C'est l'email qu'on a gardé
          code: _twoFACode,
        );
      } else {
        // 🔥 Appel API : /auth/sign-up (AVEC code)
        response = await _apiService.signUp(
          name: _signupFullName,
          email: verificationToken, // C'est l'email qu'on a gardé
          password: _signupPassword,
          code: _twoFACode,
        );
      }

      if (response['success'] == true) {
        // Sauvegarder les données utilisateur
        await voteViewModel.saveUserData(
          userId: response['userId'] ?? '',
          userName: response['userName'] ?? _signupFullName,
          authToken: response['token'] ?? '',
        );

        _currentUser = AuthUser(
          id: response['userId'] ?? '',
          email: response['email'] ?? verificationToken,
          fullName: response['userName'] ?? '',
          accessToken: response['token'] ?? '',
          refreshToken: '',
        );

        _isAuthenticated = true;

        // Rafraîchir les votes
        await voteViewModel.refreshVotes();

        _isTwoFALoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Code invalide');
      }

    } catch (e) {
      _twoFAError = e.toString().replaceAll('Exception: ', '');
      _isTwoFALoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resend2FACode({
    required String verificationToken,
    required TwoFAMode mode,
  }) async {
    if (!canResend) return false;

    _isResending = true;
    notifyListeners();

    try {
      Map<String, dynamic> response;

      if (mode == TwoFAMode.login) {
        response = await _apiService.loginSendCode(
          email: verificationToken,
          password: _loginPassword,
        );
      } else {
        response = await _apiService.signUpSendCode(
          email: verificationToken,
        );
      }

      if (response['success'] == true) {
        _isResending = false;
        startResendTimer();
        notifyListeners();
        return true;
      } else {
        throw Exception('Impossible de renvoyer le code');
      }

    } catch (e) {
      _twoFAError = 'Impossible de renvoyer le code';
      _isResending = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    await _apiService.logout();
    await voteViewModel.clearAllData();

    _isAuthenticated = false;
    _currentUser = null;

    _resetAllForms();

    notifyListeners();
  }

  // ==================== CHECK AUTH STATUS ====================

  Future<void> checkAuthStatus() async {
    final userId = voteViewModel.currentUserId;
    final userName = voteViewModel.currentUserName;
    final token = await _secureStorage.read(key: 'authToken');

    if (userId.isNotEmpty &&
        userId != 'user_123' &&
        token != null &&
        token.isNotEmpty) {
      _currentUser = AuthUser(
        id: userId,
        email: '',
        fullName: userName,
        accessToken: token,
        refreshToken: '',
      );
      _isAuthenticated = true;

      print('✅ Utilisateur authentifié: $userName');
      notifyListeners();
    } else {
      _isAuthenticated = false;
      _currentUser = null;

      print('❌ Aucun utilisateur authentifié');
      notifyListeners();
    }
  }

  // ==================== HELPERS ====================

  void _resetAllForms() {
    _loginEmail = '';
    _loginPassword = '';
    _loginError = null;

    _signupEmail = '';
    _signupFullName = '';
    _signupPassword = '';
    _signupConfirmPassword = '';
    _emailError = null;
    _fullNameError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _signupError = null;

    _twoFACode = '';
    _twoFAError = null;
    _resendTimer?.cancel();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

enum TwoFAMode { login, signup }