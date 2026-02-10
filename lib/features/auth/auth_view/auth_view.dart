
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_vote/features/auth/verification_page.dart';
import '../auth_viewModel/auth_viewModel.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late TabController _tabController;
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF2DC4B6),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  const Text(
                    'SecureVote',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sous-titre
                  const Text(
                    'Authentification sécurisée requise',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card avec le formulaire
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tabs
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: const Color(0xFF2DC4B6),
                            indicatorWeight: 3,
                            labelColor: const Color(0xFF2DC4B6),
                            unselectedLabelColor: const Color(0xFF666666),
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(text: 'Connexion'),
                              Tab(text: "S'inscrire"),
                            ],
                          ),
                        ),

                        // Contenu des tabs
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(),
                              _buildSignupForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Badge de sécurité
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Plateforme de vote sécurisée et certifiée',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Email
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: !vm.isLoginLoading,
                onChanged: vm.updateLoginEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'nom@organisation.fr',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Mot de passe
              const Text(
                'Mot de passe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscureLoginPassword,
                enabled: !vm.isLoginLoading,
                onChanged: vm.updateLoginPassword,

                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.lock_outlined, color: Colors.black54),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureLoginPassword = !_obscureLoginPassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de connexion
             SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: vm.canLogin ? () => _handleLogin(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DC4B6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: vm.isLoginLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Message d'erreur
              if (vm.loginError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vm.loginError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignupForm() {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Nom complet
                const Text(
                  'Nom complet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullNameController,
                  enabled: !vm.isSignupLoading,
                  onChanged: vm.updateSignupFullName,
                  decoration: InputDecoration(
                    hintText: 'Jean Dupont',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: vm.fullNameError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  enabled: !vm.isSignupLoading,
                  onChanged: vm.updateSignupEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'nom@organisation.fr',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: vm.emailError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  enabled: !vm.isSignupLoading,
                  onChanged: vm.updateSignupPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSignupPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSignupPassword = !_obscureSignupPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: vm.passwordError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                const Text(
                  'Confirmer le mot de passe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !vm.isSignupLoading,
                  onChanged: vm.updateSignupConfirmPassword,
                  obscureText: _obscureSignupPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSignupPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSignupPassword = !_obscureSignupPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: vm.confirmPasswordError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton de création de compte
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: vm.canSignup ? () => _handleSignup(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DC4B6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: vm.isSignupLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Message d'erreur
                if (vm.signupError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vm.signupError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    final response = await vm.submitLoginSendCode();

    if (response != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationPage(),
        ),
      );
    }
  }

  Future<void> _handleSignup(BuildContext context) async {
    final vm = context.read<AuthViewModel>();
    final response = await vm.submitSignup();

    if (response != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationPage(),
        ),
      );
    }
  }
}