import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../auth_model/auth_model.dart';
import '../../../core/services/storage_service.dart';
import '../../vote/view_model/vote_view_model.dart';

class AuthViewModel extends ChangeNotifier {
  final VoteViewModel voteViewModel;



  AuthViewModel({required this.voteViewModel});
  bool _isAuthenticated = false;
  AuthUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get currentUser => _currentUser;


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
      // TODO: Remplacer par vrai appel API
      await Future.delayed(const Duration(seconds: 2));

      // Simulation de réponse
      if (_loginEmail == 'error@test.com') {
        throw Exception('Email ou mot de passe incorrect');
      }

      final response = LoginCredentialResponse(
        statusCode: 200,
        verificationToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Code de vérification envoyé à $_loginEmail',
      );

      _isLoginLoading = false;
      notifyListeners();
      return response;

    } catch (e) {
      _loginError = e.toString().replaceAll('Exception: ', '');
      _isLoginLoading = false;
      notifyListeners();
      return null;
    }
  }

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
    if (value.length < 8) return 'Minimum 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Une majuscule requise';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Une minuscule requise';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Un chiffre requis';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Un caractère spécial requis';
    }
    return null;
  }

  Future<SignupResponse?> submitSignup() async {
    if (!canSignup) return null;

    _isSignupLoading = true;
    _signupError = null;
    notifyListeners();

    try {
      // TODO: Remplacer par vrai appel API
      await Future.delayed(const Duration(seconds: 2));

      // Simulation
      if (_signupEmail == 'exist@test.com') {
        throw Exception('Un compte avec cette adresse email existe déjà');
      }

      final response = SignupResponse(
        statusCode: 200,
        message: 'Code de vérification envoyé',
        verificationToken: 'signup_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      _isSignupLoading = false;
      notifyListeners();
      return response;

    } catch (e) {
      _signupError = e.toString().replaceAll('Exception: ', '');
      _isSignupLoading = false;
      notifyListeners();
      return null;
    }
  }



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
      // TODO: Remplacer par vrai appel API
      await Future.delayed(const Duration(seconds: 1));

      // Simulation
      if (_twoFACode != '123456') {
        throw Exception('Code invalide ou expiré');
      }

      final response = TwoFAResponse(
        statusCode: 200,
        message: 'Authentification réussie',
        accessToken: 'access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      );


      final user = AuthUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: mode == TwoFAMode.login ? _loginEmail : _signupEmail,
        fullName: mode == TwoFAMode.login ? 'Utilisateur' : _signupFullName,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );


      await voteViewModel.saveUserData(
        userId: user.id,
        userName: user.fullName,
        authToken: user.accessToken,
      );


      _currentUser = user;
      _isAuthenticated = true;


      await voteViewModel.refreshVotes();

      _isTwoFALoading = false;
      notifyListeners();
      return true;

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
      // TODO: Remplacer par vrai appel API
      await Future.delayed(const Duration(seconds: 1));

      _isResending = false;
      startResendTimer();
      notifyListeners();
      return true;

    } catch (e) {
      _twoFAError = 'Impossible de renvoyer le code';
      _isResending = false;
      notifyListeners();
      return false;
    }
  }



  Future<void> logout() async {
    // Effacer toutes les données
    await voteViewModel.clearAllData();

    _isAuthenticated = false;
    _currentUser = null;

    _resetAllForms();

    notifyListeners();
  }



  Future<void> checkAuthStatus() async {
    final userId = voteViewModel.currentUserId;
    final userName = voteViewModel.currentUserName;

    if (userId.isNotEmpty && userId != 'user_123') {
      _currentUser = AuthUser(
        id: userId,
        email: '',
        fullName: userName,
        accessToken: '',
        refreshToken: '',
      );
      _isAuthenticated = true;
      notifyListeners();
    }
  }



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