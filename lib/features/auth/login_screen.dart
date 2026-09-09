import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../services/qr_service.dart';

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
  bool _isScanningQr = false;
  String? _errorMessage;

  Future<void> _handleLogin([
    String? u,
    String? p,
    String? targetProgramId,
  ]) async {
    final username = u ?? _usernameController.text.trim();
    final password = p ?? _passwordController.text.trim();

    if (u != null) {
      _usernameController.text = u;
      _passwordController.text = p ?? '';
    } else {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(username, password);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
        if (!mounted) return;
        switch (user.role) {
          case UserRole.festController:
            context.go('/controller');
            break;
          case UserRole.teamLeader:
            context.go('/leader');
            break;
          case UserRole.jury:
            context.go('/jury', extra: targetProgramId);
            break;
          case UserRole.tvOperator:
            context.go('/tv');
            break;
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Authentication failed. Please check your credentials.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      backgroundColor: AppTheme.wood,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PatternStrip(height: 10),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 24 : 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandMark(size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'Fest Portal Login',
                            style: GoogleFonts.rye(
                              fontSize: isMobile ? 22 : 25,
                              color: AppTheme.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to access your designated portal',
                            style: GoogleFonts.workSans(
                              color: AppTheme.inkSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.workSans(
                                        color: Colors.redAccent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isScanningQr) ...[
                            SizedBox(
                              height: isMobile ? 240 : 280,
                              child: QRScannerWidget(
                                onScanned: (payload) {
                                  final scanRes = QrService.parseQrPayload(
                                    payload,
                                  );
                                  if (scanRes.type ==
                                      QrScanType.juryLoginProgram) {
                                    setState(() => _isScanningQr = false);
                                    if (scanRes.username != null &&
                                        scanRes.password != null) {
                                      _handleLogin(
                                        scanRes.username,
                                        scanRes.password,
                                        scanRes.programId,
                                      );
                                    } else {
                                      setState(
                                        () => _errorMessage =
                                            'Invalid Jury Login QR code',
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      _errorMessage =
                                          'Scanned QR is not a Jury Login QR';
                                      _isScanningQr = false;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _isScanningQr = false),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel QR Scan'),
                            ),
                          ] else ...[
                            AppTextField(
                              label: 'Username',
                              controller: _usernameController,
                              prefixIcon: Icons.person_outline,
                              hint: 'Enter your username',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Username required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Password',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,
                              hint: 'Enter your password',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Password required'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              label: 'Sign In',
                              width: double.infinity,
                              isLoading: _isLoading,
                              onPressed: () => _handleLogin(),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _isScanningQr = true),
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Login with QR Code'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.arrow_back,
                              size: 16,
                              color: AppTheme.red,
                            ),
                            label: Text(
                              'Back to Public Portal',
                              style: GoogleFonts.workSans(
                                color: AppTheme.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () => context.go('/public'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
