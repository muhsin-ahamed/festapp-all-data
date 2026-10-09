import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  Future<void> _processQrPayload(String payload) async {
    final clean = payload.trim();
    if (clean.isEmpty) return;

    final scanRes = QrService.parseQrPayload(clean);

    // 1. Direct credentials provided in QR (e.g. fest_jury_login, fest_login, JSON, or username:password)
    if (scanRes.username != null && scanRes.password != null) {
      setState(() {
        _isScanningQr = false;
        _errorMessage = null;
      });
      await _handleLogin(
        scanRes.username,
        scanRes.password,
        scanRes.programId,
      );
      return;
    }

    // 2. Jury QR containing jury code or jury ID (e.g. fest_jury:JURY-101 or JURY-101)
    if (scanRes.type == QrScanType.jury ||
        scanRes.value.toUpperCase().startsWith('JURY') ||
        scanRes.value.toUpperCase().startsWith('J-')) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final juryRepo = ref.read(juryRepositoryProvider);
        final juries = await juryRepo.getJuries();
        final searchVal = scanRes.value.trim().toLowerCase();

        final matchedJury = juries.where((j) {
          return j.juryCode.trim().toLowerCase() == searchVal ||
              j.id.trim().toLowerCase() == searchVal ||
              j.username.trim().toLowerCase() == searchVal;
        }).firstOrNull;

        if (matchedJury != null && matchedJury.password.isNotEmpty) {
          setState(() {
            _isScanningQr = false;
            _isLoading = false;
          });
          await _handleLogin(matchedJury.username, matchedJury.password);
          return;
        }

        // Try user repository as fallback
        final userRepo = ref.read(userRepositoryProvider);
        final users = await userRepo.getUsers();
        final matchedUser = users.where((u) {
          return (u.role == UserRole.jury &&
                  u.juryId?.toLowerCase() == searchVal) ||
              u.username.toLowerCase() == searchVal;
        }).firstOrNull;

        if (matchedUser != null &&
            matchedUser.password != null &&
            matchedUser.password!.isNotEmpty) {
          setState(() {
            _isScanningQr = false;
            _isLoading = false;
          });
          await _handleLogin(matchedUser.username, matchedUser.password!);
          return;
        }

        if (matchedJury != null || matchedUser != null) {
          final uName = matchedJury?.username ?? matchedUser?.username ?? '';
          setState(() {
            _isScanningQr = false;
            _isLoading = false;
            _usernameController.text = uName;
            _errorMessage =
                'Jury profile found for "$uName". Please enter your password.';
          });
          return;
        }
      } catch (_) {}
    }

    // 3. Known Username QR fallback
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final users = await userRepo.getUsers();
      final searchVal = scanRes.value.trim().toLowerCase();
      final matchedUser = users
          .where((u) => u.username.trim().toLowerCase() == searchVal)
          .firstOrNull;

      if (matchedUser != null) {
        setState(() {
          _isScanningQr = false;
          _isLoading = false;
          _usernameController.text = matchedUser.username;
          _errorMessage =
              'Account "${matchedUser.username}" found! Please enter your password.';
        });
        return;
      }
    } catch (_) {}

    // 4. Invalid or unrecognized QR code
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage =
          'Unrecognized QR code (${scanRes.value}). Please scan a valid Fest Login QR or Jury badge.';
    });
  }

  Future<void> _pickQrImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isNotEmpty) {
        final path = result.first.path;
        if (path != null && !kIsWeb) {
          final controller = MobileScannerController();
          try {
            final barcodes = await controller.analyzeImage(path);
            if (barcodes != null && barcodes.barcodes.isNotEmpty) {
              final raw = barcodes.barcodes.first.rawValue;
              if (raw != null && raw.isNotEmpty) {
                await _processQrPayload(raw);
                return;
              }
            }
          } finally {
            controller.dispose();
          }
        }
        if (mounted) {
          setState(() {
            _errorMessage =
                'No QR code could be detected in the selected image.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not scan image: ${e.toString().replaceAll("Exception: ", "")}';
        });
      }
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.ink.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.line),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        color: AppTheme.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Scan Login QR Code',
                                          style: GoogleFonts.workSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Scan your Jury badge or Login QR code with camera, or paste/upload below.',
                                    style: GoogleFonts.workSans(
                                      color: AppTheme.inkSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: isMobile ? 260 : 300,
                                    child: QRScannerWidget(
                                      onScanned: (payload) =>
                                          _processQrPayload(payload),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.paste_rounded, size: 16),
                                        label: const Text(
                                          'Paste QR Text',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          try {
                                            final data = await Clipboard.getData(
                                              Clipboard.kTextPlain,
                                            );
                                            final text = data?.text?.trim() ?? '';
                                            if (text.isNotEmpty) {
                                              await _processQrPayload(text);
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Clipboard is empty',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (_) {}
                                        },
                                      ),
                                      if (!kIsWeb &&
                                          (Platform.isAndroid ||
                                              Platform.isIOS ||
                                              Platform.isMacOS))
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.image_search_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Upload QR Image',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          onPressed: _pickQrImage,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _isScanningQr = false;
                                      _errorMessage = null;
                                    }),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text(
                                      'Cancel & Return to Password Login',
                                    ),
                                  ),
                                ],
                              ),
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
