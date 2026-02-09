
class InputValidationService {

  /// Patterns dangereux à bloquer
  static final List<RegExp> _dangerousPatterns = [
    // Injection SQL
    RegExp(r"('|(--)|;|\/\*|\*\/|xp_|sp_)", caseSensitive: false),

    // Injection de script
    RegExp(r"<script[^>]*>.*?</script>", caseSensitive: false),
    RegExp(r"javascript:", caseSensitive: false),
    RegExp(r"on\w+\s*=", caseSensitive: false), // onclick, onload, etc.

    // Injection NoSQL
    RegExp(r"(\$where|\$ne|\$gt|\$lt)", caseSensitive: false),

    // Commandes système
    RegExp(r"(rm\s|del\s|format\s)", caseSensitive: false),
  ];

  // Nettoyer et valider le titre du vote
  static String sanitizeTitle(String title) {
    if (title.isEmpty) {
      throw ValidationException('Le titre ne peut pas être vide');
    }

    String cleaned = title.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.length < 3) {
      throw ValidationException('Le titre doit contenir au moins 3 caractères');
    }
    if (cleaned.length > 200) {
      throw ValidationException('Le titre ne peut pas dépasser 200 caractères');
    }

    _checkForDangerousPatterns(cleaned, 'titre');

    return cleaned;
  }

  static String? sanitizeDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return null;
    }

    String cleaned = description.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.length > 1000) {
      throw ValidationException('La description ne peut pas dépasser 1000 caractères');
    }

    _checkForDangerousPatterns(cleaned, 'description');

    return cleaned;
  }

  // Nettoyer et valider un choix de vote
  static String sanitizeChoice(String choice) {
    if (choice.trim().isEmpty) {
      throw ValidationException('Le choix ne peut pas être vide');
    }

    String cleaned = choice.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.length < 1) {
      throw ValidationException('Le choix doit contenir au moins 1 caractère');
    }
    if (cleaned.length > 100) {
      throw ValidationException('Le choix ne peut pas dépasser 100 caractères');
    }

    _checkForDangerousPatterns(cleaned, 'choix');

    return cleaned;
  }

  // Valider une liste de choix
  static List<String> sanitizeChoices(List<String> choices) {
    if (choices.length < 2) {
      throw ValidationException('Un vote doit avoir au moins 2 choix');
    }
    if (choices.length > 20) {
      throw ValidationException('Un vote ne peut pas avoir plus de 20 choix');
    }

    final cleanedChoices = choices.map(sanitizeChoice).toList();

    final uniqueChoices = cleanedChoices.toSet();
    if (uniqueChoices.length != cleanedChoices.length) {
      throw ValidationException('Les choix doivent être uniques');
    }

    return cleanedChoices;
  }

  // Valider un email
  static String sanitizeEmail(String email) {
    final cleaned = email.trim().toLowerCase();

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegex.hasMatch(cleaned)) {
      throw ValidationException('Email invalide');
    }

    return cleaned;
  }

  // Valider un ID utilisateur
  static String sanitizeUserId(String userId) {
    final cleaned = userId.trim();

    if (cleaned.isEmpty) {
      throw ValidationException('ID utilisateur invalide');
    }

    final validIdRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validIdRegex.hasMatch(cleaned)) {
      throw ValidationException('ID utilisateur contient des caractères invalides');
    }

    if (cleaned.length > 50) {
      throw ValidationException('ID utilisateur trop long');
    }

    return cleaned;
  }

  /// Valider les dates pour la CRÉATION de vote
  static void validateDates(DateTime startingDate, DateTime deadline) {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    if (startingDate.isBefore(fiveMinutesAgo)) {
      throw ValidationException(
          'La date de début ne peut pas être il y a plus de 5 minutes'
      );
    }

    if (deadline.isBefore(startingDate) || deadline.isAtSameMomentAs(startingDate)) {
      throw ValidationException(
          'La deadline doit être après la date de début'
      );
    }

    final duration = deadline.difference(startingDate);

    if (duration.inMinutes < 60) {
      final remaining = 60 - duration.inMinutes;
      throw ValidationException(
          'Le vote doit durer au moins 1 heure. '
              'Il manque encore $remaining minutes.'
      );
    }

    // SÉCURITÉ : Évite les votes qui ne finissent jamais
    if (duration.inDays > 365) {
      throw ValidationException(
          'Le vote ne peut pas durer plus de 1 an (${duration.inDays} jours demandés)'
      );
    }

    // SÉCURITÉ : Un vote terminé ne peut pas être créé
    if (deadline.isBefore(now)) {
      throw ValidationException(
          'La deadline doit être dans le futur'
      );
    }
  }

  // Valider les dates pour la MODIFICATION de vote (VoteEditView)
  static void validateDatesForUpdate(
      DateTime originalStartingDate,
      DateTime newDeadline,
      ) {
    final now = DateTime.now();

    // RÈGLE 1 : Nouvelle deadline APRÈS startingDate original
    if (newDeadline.isBefore(originalStartingDate)) {
      throw ValidationException(
          'La deadline ne peut pas être avant la date de début du vote'
      );
    }

    // RÈGLE 2 : Nouvelle deadline dans le FUTUR
    if (newDeadline.isBefore(now)) {
      throw ValidationException(
          'La nouvelle deadline doit être dans le futur'
      );
    }

    // RÈGLE 3 : Au moins 10 minutes restantes
    // SÉCURITÉ : Évite de fermer le vote trop vite
    final timeRemaining = newDeadline.difference(now);

    if (timeRemaining.inMinutes < 10) {
      throw ValidationException(
          'La deadline doit être au moins 10 minutes dans le futur'
      );
    }
  }

  // Vérifier les patterns dangereux
  static void _checkForDangerousPatterns(String input, String fieldName) {
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        throw ValidationException(
            'Le $fieldName contient des caractères non autorisés pour des raisons de sécurité'
        );
      }
    }
  }

  // Encoder les caractères HTML pour éviter XSS
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  static void validateVoteObject(Map<String, dynamic> voteData) {
    final requiredFields = ['title', 'startingDate', 'deadline', 'choices', 'creatorId'];

    for (final field in requiredFields) {
      if (!voteData.containsKey(field)) {
        throw ValidationException('Champ obligatoire manquant: $field');
      }
    }

    sanitizeTitle(voteData['title'] as String);

    if (voteData.containsKey('description') &&
        voteData['description'] != null &&
        (voteData['description'] as String).trim().isNotEmpty) {
      sanitizeDescription(voteData['description'] as String);
    }

    final choices = (voteData['choices'] as List).cast<String>();
    sanitizeChoices(choices);

    sanitizeUserId(voteData['creatorId'] as String);
  }

  // Valider un index de choix lors du vote
  static void validateChoiceIndex(int choiceIndex, int totalChoices) {
    if (choiceIndex < 0 || choiceIndex >= totalChoices) {
      throw ValidationException('Index de choix invalide');
    }
  }

  // Rate limiting côté client
  static final Map<String, DateTime> _lastRequests = {};

  static void checkRateLimit(String userId, {Duration cooldown = const Duration(seconds: 1)}) {
    final lastRequest = _lastRequests[userId];
    final now = DateTime.now();

    if (lastRequest != null && now.difference(lastRequest) < cooldown) {
      throw ValidationException(
          'Trop de requêtes. Veuillez attendre ${cooldown.inSeconds} secondes.'
      );
    }

    _lastRequests[userId] = now;
  }
}

// Exception personnalisée
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => message;
}