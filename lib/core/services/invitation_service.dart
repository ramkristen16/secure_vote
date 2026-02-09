/// Service de validation des entrées utilisateur
///
/// Fournit des méthodes statiques pour valider différents types de données
/// avant de les envoyer au backend ou de les stocker
class InputValidationService {
  // pour l'email

  // Valider un email

  // Vérifie le format basique d'un email (présence de @ et d'un domaine)

  // Exemples valides:
  // - user@example.com
  // - test.user+tag@domain.co.uk

  // Exemples invalides:
  // - user@
  // - @example.com
  // - user.example.com
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Regex pour validation email (RFC 5322 simplifié)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  // Valider une liste d'emails

  //Retourne un map avec les emails valides et invalides séparés
  static Map<String, List<String>> validateEmails(List<String> emails) {
    final validEmails = <String>[];
    final invalidEmails = <String>[];

    for (var email in emails) {
      final trimmedEmail = email.trim().toLowerCase();
      if (isValidEmail(trimmedEmail)) {
        validEmails.add(trimmedEmail);
      } else {
        invalidEmails.add(email);
      }
    }

    return {
      'valid': validEmails,
      'invalid': invalidEmails,
    };
  }

  //  TÉLÉPHONE

  /// Valider un numéro de téléphone (format international)
  ///
  /// Accepte les formats:
  /// - +33612345678
  /// - +1234567890
  /// - 0612345678 (France)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Enlever les espaces, tirets, parenthèses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Vérifier format international ou national
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

    return phoneRegex.hasMatch(cleaned);
  }

  // TEXTE

  // Valider un titre de vote

  // Règles:
  // - Longueur: 3-200 caractères
  //- Pas uniquement des espaces
  static ValidationResult validateVoteTitle(String title) {
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Le titre ne peut pas être vide',
      );
    }

    if (trimmed.length < 3) {
      return ValidationResult(
        isValid: false,
        message: 'Le titre doit contenir au moins 3 caractères',
      );
    }

    if (trimmed.length > 200) {
      return ValidationResult(
        isValid: false,
        message: 'Le titre ne peut pas dépasser 200 caractères',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Valider une description

  //Règles:
  // - Longueur max: 2000 caractères
  // - Peut être vide (optionnelle)
  static ValidationResult validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return ValidationResult(isValid: true); // Optionnelle
    }

    if (description.trim().length > 2000) {
      return ValidationResult(
        isValid: false,
        message: 'La description ne peut pas dépasser 2000 caractères',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Valider un nom d'utilisateur
  //
  // Règles:
  // - Longueur: 2-50 caractères
  // - Lettres, chiffres, espaces, tirets, underscores
  // - Pas uniquement des espaces
  static ValidationResult validateUsername(String username) {
    final trimmed = username.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Le nom d\'utilisateur ne peut pas être vide',
      );
    }

    if (trimmed.length < 2) {
      return ValidationResult(
        isValid: false,
        message: 'Le nom doit contenir au moins 2 caractères',
      );
    }

    if (trimmed.length > 50) {
      return ValidationResult(
        isValid: false,
        message: 'Le nom ne peut pas dépasser 50 caractères',
      );
    }

    // Vérifier caractères autorisés
    final usernameRegex = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return ValidationResult(
        isValid: false,
        message: 'Le nom ne peut contenir que des lettres, chiffres, espaces, tirets et underscores',
      );
    }

    return ValidationResult(isValid: true);
  }

  // OPTIONS DE VOTE

  // Valider une option de vote

  // Règles:
  // - Longueur: 1-100 caractères
  // - Pas uniquement des espaces
  static ValidationResult validateVoteOption(String option) {
    final trimmed = option.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'L\'option ne peut pas être vide',
      );
    }

    if (trimmed.length > 100) {
      return ValidationResult(
        isValid: false,
        message: 'L\'option ne peut pas dépasser 100 caractères',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Valider une liste d'options de vote
  //
  // Règles:
  // - Minimum 2 options
  // - Maximum 20 options
  // - Pas de doublons
  // - Chaque option doit être valide
  static ValidationResult validateVoteOptions(List<String> options) {
    if (options.length < 2) {
      return ValidationResult(
        isValid: false,
        message: 'Il faut au moins 2 options',
      );
    }

    if (options.length > 20) {
      return ValidationResult(
        isValid: false,
        message: 'Maximum 20 options autorisées',
      );
    }

    // Vérifier les doublons
    final trimmedOptions = options.map((o) => o.trim().toLowerCase()).toList();
    final uniqueOptions = trimmedOptions.toSet();

    if (uniqueOptions.length != trimmedOptions.length) {
      return ValidationResult(
        isValid: false,
        message: 'Il ne peut pas y avoir d\'options identiques',
      );
    }

    // Vérifier chaque option individuellement
    for (var option in options) {
      final result = validateVoteOption(option);
      if (!result.isValid) {
        return result;
      }
    }

    return ValidationResult(isValid: true);
  }

  //  DATES

  // Valider une date limite

  // Règles:
  // - Doit être dans le futur
  // - Pas plus de 2 ans dans le futur
  static ValidationResult validateDeadline(DateTime deadline) {
    final now = DateTime.now();

    if (deadline.isBefore(now)) {
      return ValidationResult(
        isValid: false,
        message: 'La date limite doit être dans le futur',
      );
    }

    // Vérifier que ce n'est pas trop loin
    final twoYearsFromNow = now.add(const Duration(days: 730));
    if (deadline.isAfter(twoYearsFromNow)) {
      return ValidationResult(
        isValid: false,
        message: 'La date limite ne peut pas dépasser 2 ans',
      );
    }

    // Vérifier qu'on a au moins 1 minute
    final minDeadline = now.add(const Duration(minutes: 1));
    if (deadline.isBefore(minDeadline)) {
      return ValidationResult(
        isValid: false,
        message: 'La date limite doit être au moins 1 minute dans le futur',
      );
    }

    return ValidationResult(isValid: true);
  }

  // URL

  // Valider une URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  //  ID

  // Valider un ID (UUID ou autre)

  //Vérifie que l'ID n'est pas vide et a une longueur raisonnable
  static bool isValidId(String id) {
    if (id.isEmpty) return false;
    if (id.length < 8) return false; // Trop court pour être sécurisé
    if (id.length > 100) return false; // Trop long

    // Vérifier caractères autorisés (alphanumériques + tirets)
    final idRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    return idRegex.hasMatch(id);
  }

  // NOMBRES

  // Valider un nombre de participants
  static ValidationResult validateParticipantCount(int count) {
    if (count < 1) {
      return ValidationResult(
        isValid: false,
        message: 'Il faut au moins 1 participant',
      );
    }

    if (count > 10000) {
      return ValidationResult(
        isValid: false,
        message: 'Maximum 10 000 participants',
      );
    }

    return ValidationResult(isValid: true);
  }

  // SANITIZATION

  // Nettoyer une chaîne de caractères

  // Enlève les espaces en début/fin et remplace les espaces multiples
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Nettoyer une liste d'emails
  static List<String> sanitizeEmails(List<String> emails) {
    return emails
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  //  VALIDATION COMPLEXE

  // Valider un vote complet avant création
  static ValidationResult validateVoteCreation({
    required String title,
    String? description,
    required List<String> options,
    required DateTime deadline,
    required bool allowMultipleChoice,
  }) {
    // 1. Valider le titre
    var result = validateVoteTitle(title);
    if (!result.isValid) return result;

    // 2. Valider la description
    result = validateDescription(description);
    if (!result.isValid) return result;

    // 3. Valider les options
    result = validateVoteOptions(options);
    if (!result.isValid) return result;

    // 4. Valider la date limite
    result = validateDeadline(deadline);
    if (!result.isValid) return result;

    // 5. Vérifications spécifiques au choix multiple
    if (allowMultipleChoice && options.length < 2) {
      return ValidationResult(
        isValid: false,
        message: 'Un vote à choix multiples nécessite au moins 2 options',
      );
    }

    return ValidationResult(
      isValid: true,
      message: 'Vote valide',
    );
  }

  //HELPERS

  //Vérifier si une chaîne contient uniquement des espaces
  static bool isOnlyWhitespace(String text) {
    return text.trim().isEmpty;
  }

  // Compter les mots dans un texte
  static int countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }

  //Vérifier si un texte est trop long
  static bool isTextTooLong(String text, int maxLength) {
    return text.length > maxLength;
  }

  //Tronquer un texte
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }
}

//  CLASSE DE RÉSULTAT

class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({
    required this.isValid,
    this.message,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message)';
  }
}