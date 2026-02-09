
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String accessToken;
  final String refreshToken;
  final DateTime? createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.accessToken,
    required this.refreshToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'],
    email: json['email'],
    fullName: json['fullName'],
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );
}
class LoginCredentials {
  final String email;
  final String password;

  LoginCredentials({
    required String email,
    required String password,
  })  : email = email.trim().toLowerCase(),
        password = password;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginCredentialResponse {
  final int statusCode;
  final String verificationToken;
  final String message;

  LoginCredentialResponse({
    required this.statusCode,
    required this.verificationToken,
    required this.message,
  });

  factory LoginCredentialResponse.fromJson(Map<String, dynamic> json) =>
      LoginCredentialResponse(
        statusCode: json['statusCode'] ?? 200,
        verificationToken: json['verificationToken'],
        message: json['message'],
      );
}

class SignupCredentials {
  final String email;
  final String fullName;
  final String password;

  SignupCredentials({
    required this.email,
    required this.fullName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'fullName': fullName,
    'password': password,
  };
}

class SignupResponse {
  final int statusCode;
  final String message;
  final String verificationToken;

  SignupResponse({
    required this.statusCode,
    required this.message,
    required this.verificationToken,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
    statusCode: json['statusCode'] ?? 200,
    message: json['message'] ?? '',
    verificationToken: json['verificationToken'] ?? '',
  );
}

class TwoFAResponse {
  final int statusCode;
  final String message;
  final String accessToken;
  final String refreshToken;

  TwoFAResponse({
    required this.statusCode,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
  });

  factory TwoFAResponse.fromJson(Map<String, dynamic> json) => TwoFAResponse(
    statusCode: json['statusCode'] ?? 200,
    message: json['message'] ?? '',
    accessToken: json['accessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
  );
}