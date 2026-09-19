import 'package:flutter/material.dart';

import '../../../shared/widgets/geobuzz_brand_logo.dart';
import '../../onboarding/presentation/hero_onboarding_screen.dart';

/// Local GeoBuzz auth palette (scoped to the login UI so the global app
/// theme stays untouched).
const Color kAuthCyan = Color(0xFF19E6DF);
const Color kAuthCyanInk = Color(0xFF061014);
const Color kAuthBodyNavy = Color(0xFF0F172A);

/// Staggered entrance wrapper: fades in while settling upward.
/// Honors `disableAnimations` (shows the final state immediately) and never
/// touches the Earth background — only foreground content is wrapped.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    this.delay = Duration.zero,
    this.slide = 14.0,
    required this.child,
  });

  final Duration delay;
  final double slide;
  final Widget child;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay).then((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.slide * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Pinned top bar: existing GeoBuzz logo asset (left) + refined privacy
/// action (right). On narrow screens the privacy action condenses to a
/// shield icon + "Private".
class GeoBuzzTopBar extends StatelessWidget {
  const GeoBuzzTopBar({super.key, required this.condensed});

  final bool condensed;

  void _goHome(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HeroOnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back to Home Button
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _goHome(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x3319E6DF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: kAuthCyan,
                      ),
                      if (!condensed) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _goHome(context),
                child: const GeoBuzzBrandLogo(size: 34, isDark: true),
              ),
            ),
          ],
        ),
        _PrivacyButton(condensed: condensed),
      ],
    );
  }
}

class _PrivacyButton extends StatelessWidget {
  const _PrivacyButton({required this.condensed});

  final bool condensed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Private by design. Learn how GeoBuzz protects location data.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showGeoBuzzPrivacyDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: kAuthCyan,
                ),
                const SizedBox(width: 5),
                Text(
                  condensed ? 'Private' : 'Private by design',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                if (!condensed) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: kAuthCyan,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Existing privacy copy, unchanged — surfaced from the top bar.
void showGeoBuzzPrivacyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFF00A2A5), size: 22),
          SizedBox(width: 8),
          Text(
            'Private by Design',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
      content: const Text(
        'GeoBuzz processes geofences and automations entirely on your local device. Your precise location history is never sold, tracked, or shared with third parties.',
        style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Got it',
            style: TextStyle(
              color: Color(0xFF00A2A5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Centered auth header: small logo mark, tagline, title, subtitle.
/// Set [compact] on short screens to drop the decorative mark.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.isLogin,
    required this.compact,
  });

  final bool isLogin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const EntranceFade(
            delay: Duration(milliseconds: 120),
            child: Center(
              child: GeoBuzzBrandLogo(
                size: 46,
                showText: false,
                isDark: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const EntranceFade(
          delay: Duration(milliseconds: 180),
          child: Text(
            'AUTOMATE BY LOCATION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: kAuthCyan,
            ),
          ),
        ),
        const SizedBox(height: 6),
        EntranceFade(
          delay: const Duration(milliseconds: 240),
          child: Text(
            isLogin ? 'Welcome back to GeoBuzz' : 'Create your account',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const EntranceFade(
          delay: Duration(milliseconds: 300),
          child: Text(
            'Your places and automations, ready when you are.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xBFFFFFFF),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium segmented Sign in / Create account selector.
class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({
    super.key,
    required this.isLogin,
    required this.onSelect,
  });

  final bool isLogin;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToggleTab(
            label: 'Sign in',
            selected: isLogin,
            onTap: () => onSelect(true),
          ),
          _ToggleTab(
            label: 'Create account',
            selected: !isLogin,
            onTap: () => onSelect(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? kAuthBodyNavy : const Color(0x99FFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labeled auth field with a subtle cyan focus ring. Behavior (validation,
/// obscuring, keyboard actions) is driven by the parent screen.
class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  /// When null, no label row is rendered (the parent provides its own,
  /// e.g. the Password label + Forgot password row).
  final String? label;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xE6FFFFFF),
            ),
          ),
          const SizedBox(height: 7),
        ],
        Focus(
          onFocusChange: (hasFocus) {
            if (mounted) setState(() => _focused = hasFocus);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: kAuthCyan.withValues(alpha: 0.28),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              onFieldSubmitted: widget.onFieldSubmitted,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: kAuthCyan,
                  size: 19,
                ),
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: kAuthCyan,
                    width: 1.6,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF87171),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF87171),
                    width: 1.6,
                  ),
                ),
                errorStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFFCA5A5),
                  height: 1.2,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}

/// Strongest interactive element: full-width cyan CTA with press, hover,
/// loading, and disabled states. All auth side effects stay in the screen.
class PrimaryAuthButton extends StatefulWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<PrimaryAuthButton> createState() => _PrimaryAuthButtonState();
}

class _PrimaryAuthButtonState extends State<PrimaryAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return Listener(
      onPointerDown: (_) {
        if (enabled && mounted) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (mounted) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (mounted) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ButtonStyle(
              elevation: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered) ? 3 : 0,
              ),
              shadowColor: WidgetStateProperty.all(
                kAuthCyan.withValues(alpha: 0.4),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return kAuthCyan.withValues(alpha: 0.55);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF3EEEE7);
                }
                return kAuthCyan;
              }),
              foregroundColor: WidgetStateProperty.all(kAuthCyanInk),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: kAuthCyanInk,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline auth error (replaces the oversized red SnackBar).
/// Collapses to zero height when [message] is null.
class AuthInlineError extends StatelessWidget {
  const AuthInlineError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: message == null
          ? const SizedBox.shrink(key: ValueKey('no-error'))
          : Container(
              key: ValueKey(message),
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF87171).withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFECACA),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Trust signal + subtle footer below the card.
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 15,
              color: kAuthCyan,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Your location data stays under your control.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          '© 2026 GeoBuzz · Privacy · Terms · Help',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            color: Color(0x8CFFFFFF),
          ),
        ),
      ],
    );
  }
}
