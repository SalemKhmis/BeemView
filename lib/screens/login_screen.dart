import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../utils/validators.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/theme_toggle_button.dart';

/// Beautiful login screen with:
/// - Animated gradient background with floating translucent shapes
/// - Glassmorphism-style form card
/// - Email validation, password toggle, subdomain pre-fill
/// - Loading spinner + disabled button while authenticating
/// - Snackbar error messages for 400/403/network errors
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -14, end: 14).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailController.text,
          password: _passwordController.text,
          subdomain: ApiConfig.subdomain, // Always "beemmobile"
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white,
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(state.message,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                backgroundColor: cs.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
              ));
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──────────────────────────────────
            _buildBackground(cs),

            // ── Floating blobs ──────────────────────────────
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, _) => _buildFloatingBlobs(size, cs),
            ),

            // ── Content ─────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(cs),
                        const SizedBox(height: 36),
                        _buildFormCard(cs),
                        const SizedBox(height: 28),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Theme & Language Switchers Top Right ───────
            const SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 12, right: 20, left: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ThemeToggleButton(),
                      SizedBox(width: 8),
                      LanguageToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient background ────────────────────────────────────
  Widget _buildBackground(ColorScheme cs) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B465A), // Deep BeemView teal
            Color(0xFF1E96BE), // BeemView primary cyan
            Color(0xFF072935), // Rich dark teal
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
    );
  }

  // ── Floating shapes ────────────────────────────────────────
  Widget _buildFloatingBlobs(Size size, ColorScheme cs) {
    return Stack(
      children: [
        _blob(-50 + _floatAnim.value, null, null, -30, 220,
            Colors.white.withValues(alpha: 0.06)),
        _blob(size.height * 0.28 + _floatAnim.value * 1.3, null, -70, null,
            280, const Color(0xFFFAAA3C).withValues(alpha: 0.08)), // Warm Amber
        _blob(null, -90 - _floatAnim.value, null, -50, 340,
            const Color(0xFF1E96BE).withValues(alpha: 0.15)), // Cyan
        _blob(size.height * 0.12 - _floatAnim.value * 0.7, null, null,
            size.width * 0.65, 90, Colors.white.withValues(alpha: 0.07)),
        _blob(null, size.height * 0.2 + _floatAnim.value * 0.5,
            size.width * 0.18, null, 55, const Color(0xFFFAAA3C).withValues(alpha: 0.12)),
      ],
    );
  }

  Widget _blob(double? top, double? bottom, double? left, double? right,
      double d, Color c) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      ),
    );
  }

  // ── Logo & branding ────────────────────────────────────────
  Widget _buildLogo(ColorScheme cs) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.4),
        child: child,
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFAAA3C).withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/beemview_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'BeemView',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PROJECT MANAGEMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.70),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ──────────────────────────────────────────────
  Widget _buildFormCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF1E96BE).withValues(alpha: 0.08),
            blurRadius: 80,
            spreadRadius: -10,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                context.tr('welcome_back'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('sign_in_subtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 28),

              // Email / Username
              _label(context.tr('username')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _deco(
                  hint: context.tr('username_hint'),
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 18),

              // Password
              _label(context.tr('password')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: Validators.validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onFieldSubmitted: (_) => _submit(),
                decoration: _deco(
                  hint: context.tr('password_hint'),
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Button
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E96BE),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF1E96BE).withValues(alpha: 0.55),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.7),
                        elevation: loading ? 0 : 4,
                        shadowColor:
                            const Color(0xFF1E96BE).withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('sign_in'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.2,
        ),
      );

  InputDecoration _deco(
      {required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFooter() => Text(
        'Powered by BeemView',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.55),
          letterSpacing: 0.5,
        ),
      );
}
