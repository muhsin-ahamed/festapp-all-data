import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin([String? u, String? p]) async {
    final username = u ?? _usernameController.text.trim();
    final password = p ?? _passwordController.text.trim();

    if (u == null && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final user = await authService.login(username, password);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      switch (user.role) {
        case UserRole.festController:
          context.go('/controller');
          break;
        case UserRole.teamLeader:
          context.go('/leader');
          break;
        case UserRole.jury:
          context.go('/jury');
          break;
        case UserRole.tvOperator:
          context.go('/tv');
          break;
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password. Please check your credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.festival, size: 48, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fest Portal Login',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sign in to access your designated portal',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppTextField(
                        label: 'Username',
                        controller: _usernameController,
                        prefixIcon: Icons.person_outline,
                        hint: 'Enter your username',
                        validator: (v) => (v == null || v.isEmpty) ? 'Username required' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        hint: 'Enter your password',
                        validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Sign In',
                        width: double.infinity,
                        isLoading: _isLoading,
                        onPressed: () => _handleLogin(),
                      ),
                       const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back to Public Portal'),
                        onPressed: () => context.go('/public'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
