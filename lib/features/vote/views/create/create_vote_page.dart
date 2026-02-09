import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/input_validation_service.dart';
import '../../view_model/vote_view_model.dart';
import '../lien_success/vote_succes_view.dart';


class VoteCreateView extends StatelessWidget {
  const VoteCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VoteViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Retour au menu",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A2E4D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Text(
              "Nouveau Scrutin",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Configurez les paramètres de votre vote sécurisé.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // TITRE
            _buildSectionLabel("Titre du vote (Requis)"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Ex: Élection du bureau syndical",
              onChanged: vm.updateTitle,
            ),

            const SizedBox(height: 24),

            // DESCRIPTION
            _buildSectionLabel("Description (Optionnel)"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Précisez le contexte du scrutin...",
              maxLines: 3,
              onChanged: vm.updateDescription,
            ),

            const SizedBox(height: 24),

            // OPTIONS DE RÉPONSE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel("Options de réponse"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${vm.choices.length} OPTIONS",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...vm.choices.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChoiceField(
                index: e.key,
                hint: "Option ${e.key + 1}",
                value: e.value.name,
                onChanged: (val) => vm.updateChoice(e.key, val),
                showDelete: vm.choices.length > 2,
                onDelete: () => vm.removeChoiceSlot(e.key),
              ),
            )),

            const SizedBox(height: 8),

            // Bouton ajouter option
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: vm.addChoiceSlot,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                label: const Text(
                  "Ajouter une option",
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // CALENDRIER
            _buildSectionLabel("Calendrier"),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildDateField(
                    context,
                    label: "DÉBUT",
                    value: DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(vm.startingDate),
                    onTap: () => _pickStartingDate(context, vm),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    context,
                    label: "ÉCHÉANCE (DEADLINE)",
                    value: vm.deadline == null
                        ? "Sélectionner une date"
                        : DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(vm.deadline!),
                    onTap: () => _pickDeadline(context, vm),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PARAMÈTRES DE SÉCURITÉ
            _buildSectionLabel("Paramètres de sécurité"),
            const SizedBox(height: 8),

            _buildToggleCard(
              icon: Icons.person_outline,
              title: "Vote Anonyme",
              subtitle: "Les identités ne sont pas liées aux choix.",
              value: vm.isAnonymous,
              onChanged: vm.toggleAnonymous,
            ),

            const SizedBox(height: 12),

            _buildToggleCard(
              icon: Icons.lock_outline,
              title: "Scrutin Privé",
              subtitle: "Seulement accessible via lien direct.",
              value: vm.isPrivate,
              onChanged: vm.togglePrivate,
            ),

            const SizedBox(height: 32),

            // BOUTON CRÉER
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: vm.isLoading ? null : () => _handleCreate(context, vm),
                child: vm.isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Création...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
                    : const Text(
                  "Créer le scrutin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note de sécurité
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Une fois créés, les paramètres de sécurité ne peuvent plus être modifiés.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildChoiceField({
    required int index,
    required String hint,
    required String value,
    required Function(String) onChanged,
    bool showDelete = false,
    VoidCallback? onDelete,
  }) {
    return Stack(
      children: [
        _buildTextField(
          hint: hint,
          onChanged: onChanged,
        ),
        if (showDelete)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context, {
        required String label,
        required String value,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF14B8A6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF14B8A6),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        activeColor: const Color(0xFF14B8A6),
        onChanged: onChanged,
      ),
    );
  }




  void _handleCreate(BuildContext context, VoteViewModel vm) async {
    // Validation du titre
    if (vm.title.trim().isEmpty) {
      _showError(context, " Titre requis", "Le titre du scrutin est obligatoire");
      return;
    }

    // Validation de la deadline
    if (vm.deadline == null) {
      _showError(context, " Deadline requise", "Veuillez sélectionner une date limite");
      return;
    }

    // Validation des choix
    final validChoices = vm.choices.where((c) => c.name.trim().isNotEmpty).toList();
    if (validChoices.length < 2) {
      _showError(context, " Options insuffisantes", "Vous devez avoir au moins 2 options de vote");
      return;
    }

    try {
      InputValidationService.validateDates(vm.startingDate, vm.deadline!);
    } on ValidationException catch (e) {
      _showError(context, " Erreur de dates", e.message);
      return;
    }

    final result = await vm.createScrutin();

    if (result != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessView(
            shareLink: result['link']!,
            voteId: result['voteId']!,
          ),
        ),
      );
    } else if (context.mounted) {
      _showError(context, " Erreur", "Impossible de créer le scrutin. Veuillez réessayer.");
    }
  }

  //  SÉLECTION DATE DE DÉBUT avec validation

  Future<void> _pickStartingDate(BuildContext context, VoteViewModel vm) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: vm.startingDate.isAfter(now) ? vm.startingDate : now,
      firstDate: now.subtract(const Duration(minutes: 5)),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF14B8A6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(vm.startingDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF14B8A6),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1A1A1A),
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final newStartingDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

        if (newStartingDate.isBefore(fiveMinutesAgo)) {
          if (context.mounted) {
            _showError(
                context,
                " Date invalide",
                "La date de début ne peut pas être il y a plus de 5 minutes"
            );
          }
          return;
        }

        vm.updateStartingDate(newStartingDate);

        if (vm.deadline != null && context.mounted) {
          _validateDateConsistency(context, vm);
        }
      }
    }
  }



  Future<void> _pickDeadline(BuildContext context, VoteViewModel vm) async {
    final now = DateTime.now();

    final minDeadline = vm.startingDate.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: vm.deadline ?? minDeadline,
      firstDate: minDeadline,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF14B8A6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: vm.deadline != null
            ? TimeOfDay.fromDateTime(vm.deadline!)
            : const TimeOfDay(hour: 18, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF14B8A6),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1A1A1A),
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final newDeadline = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        try {
          InputValidationService.validateDates(vm.startingDate, newDeadline);

          vm.updateDeadline(newDeadline);

        } on ValidationException catch (e) {
          if (context.mounted) {
            _showError(context, " Deadline invalide", e.message);
          }
        }
      }
    }
  }


  void _validateDateConsistency(BuildContext context, VoteViewModel vm) {
    if (vm.deadline == null) return;

    try {
      InputValidationService.validateDates(vm.startingDate, vm.deadline!);
    } on ValidationException catch (e) {
      _showError(context, " Attention", e.message);
    }
  }


  void _showError(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF14B8A6),
            ),
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}