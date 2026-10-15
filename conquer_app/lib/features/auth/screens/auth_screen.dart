import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/cyber_button.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _usernameController =
      TextEditingController(text: 'SHRAVAN');
  final TextEditingController _passwordController =
      TextEditingController(text: '••••••••');
  final TextEditingController _emailController =
      TextEditingController(text: 'shravan@conquer.app');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleLogin(WidgetRef ref) async {
    final success = await ref.read(authProvider.notifier).login(
          _usernameController.text,
          _passwordController.text,
        );
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Shield
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonCyan.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.neonCyan, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield, color: AppColors.neonCyan, size: 40),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'CONQUER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'OWN YOUR WORLD',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Auth Card
                    CyberCard(
                      borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
                      isGlowing: true,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Toggle (Login / Register)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.bgDeep,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isSignUp = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !_isSignUp
                                            ? AppColors.neonCyan.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: !_isSignUp
                                            ? Border.all(color: AppColors.neonCyan, width: 1)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          color: !_isSignUp
                                              ? AppColors.neonCyan
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isSignUp = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isSignUp
                                            ? AppColors.neonCyan.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: _isSignUp
                                            ? Border.all(color: AppColors.neonCyan, width: 1)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'NEW RECRUIT',
                                        style: TextStyle(
                                          color: _isSignUp
                                              ? AppColors.neonCyan
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_isSignUp) ...[
                            CyberTextField(
                              controller: _emailController,
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                          ],

                          CyberTextField(
                            controller: _usernameController,
                            label: 'Commander Call-Sign',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),

                          CyberTextField(
                            controller: _passwordController,
                            label: 'Security Key',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),

                          CyberButton(
                            text: _isSignUp ? 'ENLIST COMMANDER' : 'ACCESS TERMINAL',
                            icon: Icons.key_rounded,
                            isLoading: authState.isLoading,
                            onPressed: () => _handleLogin(ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Demo Login Pill
                    GestureDetector(
                      onTap: () => _handleLogin(ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: AppColors.neonGold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Instant Demo: Play as SHRAVAN (Level 14)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
        );
      },
    );
  }
}
