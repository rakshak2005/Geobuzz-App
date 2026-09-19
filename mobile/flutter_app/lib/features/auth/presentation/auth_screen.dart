import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/hero_video_background.dart';
import '../domain/auth_provider.dart';
import '../../home/presentation/responsive_scaffold.dart';
import 'auth_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _keepMeSignedIn = true;
  String? _inlineError;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _selectMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _inlineError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    if (_isLogin) {
      success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() {
      _inlineError = success ? null : authProvider.authError;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isLogin ? 'Welcome back!' : 'Account registered successfully!'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResponsiveScaffold()),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    // Pre-fill email or let user pick/enter email if provided
    final currentEmail = _emailController.text.trim();
    final name = _nameController.text.trim();

    final success = await authProvider.signInWithGoogle(
      customEmail: currentEmail.isNotEmpty ? currentEmail : null,
      customName: name.isNotEmpty ? name : null,
    );

    if (!mounted) return;
    setState(() {
      _inlineError = success ? null : authProvider.authError;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${authProvider.userName ?? "User"}!'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResponsiveScaffold()),
      );
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent to your email.'),
        backgroundColor: Color(0xFF00A2A5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 800;
    final isSmall = size.width <= 380;
    final isShort = size.height < 560;
    final condensedPrivacy = size.width < 480;
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final hPad = isDesktop ? 32.0 : (isSmall ? 16.0 : 20.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kept: purple Earth / starfield background.
          RepaintBoundary(
            child: HeroVideoBackground(reducedMotion: reducedMotion),
          ),
          // Subtle readability scrim only — the globe stays clearly visible.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x8C000000),
                    Color(0x99000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pinned top bar.
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 10),
                  child: EntranceFade(
                    slide: 8,
                    child: GeoBuzzTopBar(condensed: condensedPrivacy),
                  ),
                ),
                // Center content: scrolls when tight, centers when roomy.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: viewport.maxHeight <= 24
                                ? 0.0
                                : viewport.maxHeight - 24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 460,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AuthHeader(
                                    isLogin: _isLogin,
                                    compact: isShort,
                                  ),
                                  SizedBox(
                                      height: isShort || isSmall ? 12 : 16),
                                  EntranceFade(
                                    delay: const Duration(milliseconds: 380),
                                    slide: 18,
                                    child: _AuthCard(
                                      isLogin: _isLogin,
                                      isSmall: isSmall,
                                      isLoading: authProvider.isLoading,
                                      inlineError: _inlineError,
                                      keepMeSignedIn: _keepMeSignedIn,
                                      obscurePassword: _obscurePassword,
                                      obscureConfirmPassword:
                                          _obscureConfirmPassword,
                                      nameController: _nameController,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      confirmPasswordController:
                                          _confirmPasswordController,
                                      formKey: _formKey,
                                      onSelectMode: _selectMode,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      onToggleConfirmPassword: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                      onToggleRemember: (value) => setState(
                                        () => _keepMeSignedIn = value ?? true,
                                      ),
                                      onForgotPassword: _forgotPassword,
                                      onSubmit: _submit,
                                      onGoogleSignIn: _signInWithGoogle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Pinned trust footer.
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 14),
                  child: const EntranceFade(
                    delay: Duration(milliseconds: 500),
                    slide: 8,
                    child: AuthTrustFooter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact white authentication surface. Pure UI — every side effect
/// (submit, validation, navigation) lives in the parent screen.
class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isLogin,
    required this.isSmall,
    required this.isLoading,
    required this.inlineError,
    required this.keepMeSignedIn,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onSelectMode,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onToggleRemember,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onGoogleSignIn,
  });

  final bool isLogin;
  final bool isSmall;
  final bool isLoading;
  final String? inlineError;
  final bool keepMeSignedIn;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final ValueChanged<bool> onSelectMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onToggleRemember;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(isSmall ? 20 : 22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(isSmall ? 20 : 26),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x8C1A2530),
                Color(0x66111A23),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthModeToggle(
                    isLogin: isLogin,
                    onSelect: onSelectMode,
                  ),
                  const SizedBox(height: 18),
                  if (!isLogin) ...[
                    AuthInput(
                      label: 'Full name',
                      controller: nameController,
                      hintText: 'Jane Doe',
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      autofillHints: const [AutofillHints.name],
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 15),
                  ],
                  AuthInput(
                    label: 'Email address',
                    controller: emailController,
                    hintText: 'you@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                      if (isLogin)
                        TextButton(
                          onPressed: onForgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: kAuthCyan,
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Forgot password?'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  AuthInput(
                    controller: passwordController,
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    autofillHints: isLogin
                        ? const [AutofillHints.password]
                        : const [AutofillHints.newPassword],
                    suffixIcon: _VisibilityToggle(
                      obscured: obscurePassword,
                      onPressed: onTogglePassword,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 15),
                    AuthInput(
                      label: 'Confirm password',
                      controller: confirmPasswordController,
                      hintText: 'Re-enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: _VisibilityToggle(
                        obscured: obscureConfirmPassword,
                        onPressed: onToggleConfirmPassword,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (val != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 19,
                        width: 19,
                        child: Checkbox(
                          value: keepMeSignedIn,
                          activeColor: kAuthCyan,
                          checkColor: kAuthCyanInk,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(
                            color: Color(0x66FFFFFF),
                            width: 1.5,
                          ),
                          onChanged: onToggleRemember,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                  AuthInlineError(message: inlineError),
                  const SizedBox(height: 17),
                  PrimaryAuthButton(
                    label: isLogin ? 'Sign in' : 'Create account',
                    isLoading: isLoading,
                    onPressed: onSubmit,
                  ),
                  const SizedBox(height: 14),
                  const AuthDivider(),
                  const SizedBox(height: 14),
                  GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: onGoogleSignIn,
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0x73FFFFFF),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'By continuing, you agree to GeoBuzz ',
                        ),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: Color(0xBFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' and acknowledge the '),
                        TextSpan(
                          text: 'Privacy Notice',
                          style: TextStyle(
                            color: Color(0xBFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
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

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.obscured,
    required this.onPressed,
  });

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0x73FFFFFF),
        size: 18,
      ),
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
    );
  }
}
