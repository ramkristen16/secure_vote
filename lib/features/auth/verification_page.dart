import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secure_vote/features/Dashboard/dashboard_page.dart';

import 'auth_viewModel/auth_viewModel.dart';

class VerificationPage extends StatefulWidget {
  final TwoFAMode mode; // Pour savoir si c'est login ou signup
  final String verificationToken; // L'email de l'utilisateur

  const VerificationPage({
    super.key,
    required this.mode,
    required this.verificationToken,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // Contrôleurs pour les 6 champs OTP
  final List<TextEditingController> _controllers = List.generate(
    6,
        (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    6,
        (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    // Démarrer le timer de renvoi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().startResendTimer();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getFullCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xfff5f5f5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A5F),
            elevation: 0,
            toolbarHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Code de vérification OTP",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Icône de sécurité
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF2DC4B6),
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                const Text(
                  "Entrez votre code de vérification",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  "Nous avons envoyé un code de confirmation à ${widget.verificationToken}",
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Ligne des champs OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                        (index) => _otpInputBox(context, index, vm),
                  ),
                ),

                const SizedBox(height: 16),

                // Message d'erreur
                if (vm.twoFAError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vm.twoFAError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: vm.isTwoFALoading
                        ? null
                        : () => _handleVerification(context, vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DC4B6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: vm.isTwoFALoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      "Vérifier",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton renvoyer le code
                Center(
                  child: TextButton(
                    onPressed: vm.canResend
                        ? () => _handleResendCode(context, vm)
                        : null,
                    child: vm.isResending
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DC4B6)),
                      ),
                    )
                        : Text(
                      vm.canResend
                          ? "Renvoyer le code"
                          : "Renvoyer le code (${vm.resendCountdown}s)",
                      style: TextStyle(
                        color: vm.canResend
                            ? const Color(0xFF2DC4B6)
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info supplémentaire
                Center(
                  child: Text(
                    widget.mode == TwoFAMode.login
                        ? "Code de connexion"
                        : "Code d'inscription",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour chaque case du code
  Widget _otpInputBox(BuildContext context, int index, AuthViewModel vm) {
    return Container(
      height: 65,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? const Color(0xFF2DC4B6)
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0,
          enabled: !vm.isTwoFALoading,
          onChanged: (value) {
            if (value.length == 1) {
              // Mettre à jour le code dans le ViewModel
              vm.updateTwoFACode(_getFullCode());

              // Passer au champ suivant
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                // Dernier champ, on retire le focus
                _focusNodes[index].unfocus();
              }
            } else if (value.isEmpty && index > 0) {
              // Si on efface, revenir au champ précédent
              _focusNodes[index - 1].requestFocus();
              vm.updateTwoFACode(_getFullCode());
            }
          },
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerification(BuildContext context, AuthViewModel vm) async {
    final code = _getFullCode();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer les 6 chiffres du code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier le code avec l'API
    final success = await vm.verify2FAAndLogin(
      verificationToken: widget.verificationToken,
      mode: widget.mode,
    );

    if (success && context.mounted) {
      // Succès, navigation vers le dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
            (route) => false, // Supprimer toutes les routes précédentes
      );

      // Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mode == TwoFAMode.login
                ? 'Connexion réussie !'
                : 'Compte créé avec succès !',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Erreur, effacer les champs
      _clearAllFields();
    }
  }

  Future<void> _handleResendCode(BuildContext context, AuthViewModel vm) async {
    final success = await vm.resend2FACode(
      verificationToken: widget.verificationToken,
      mode: widget.mode,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code renvoyé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de renvoyer le code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}