import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/geobuzz_brand_logo.dart';
import '../../auth/domain/auth_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../home/presentation/responsive_scaffold.dart';
import 'permission_onboarding_screen.dart';

double _min(num first, num second, [num? third]) {
  final result = third == null
      ? math.min(first, second)
      : math.min(math.min(first, second), third);
  return result.toDouble();
}

double _max(num first, num second, [num? third]) {
  final result = third == null
      ? math.max(first, second)
      : math.max(math.max(first, second), third);
  return result.toDouble();
}

class HeroOnboardingScreen extends StatefulWidget {
  const HeroOnboardingScreen({super.key});

  @override
  State<HeroOnboardingScreen> createState() => _HeroOnboardingScreenState();
}

class _HeroOnboardingScreenState extends State<HeroOnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _menuOpen = false;
  bool _reducedMotion = false;
  bool _didInitEntrance = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1670),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (_reducedMotion != reducedMotion) {
      _reducedMotion = reducedMotion;
    }
    if (_reducedMotion) {
      _entranceController.value = 1;
    } else if (!_didInitEntrance) {
      _didInitEntrance = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 900), _startEntrance);
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _startEntrance() {
    if (!mounted || _entranceController.isCompleted) return;
    _entranceController.forward();
  }

  void _setMenuOpen(bool value) {
    if (!mounted) return;
    setState(() => _menuOpen = value);
  }

  void _closeMenu() => _setMenuOpen(false);

  void _openAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _continue() {
    final authProvider = context.read<AuthProvider>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.isAuthenticated
            ? const ResponsiveScaffold()
            : const PermissionOnboardingScreen(),
      ),
    );
  }

  void _showContactDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF101014),
        title: const Text(
          'Contact Sales',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Tell us where your day takes you. We will help you shape GeoBuzz around it.',
          style: TextStyle(color: Color(0xFFD9D9D9), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                  color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  double _unit(Size size) {
    if (size.width <= 552) return 1;
    final base = _min(size.width / 1280, size.height / 760);
    if (size.width > 1160) return base;
    return _min(
      _max(0.9, base),
      (size.width - 72) / 575,
      size.height / 620,
    );
  }

  TextStyle _font({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _headlineFont({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final unit = _unit(size);
    final isDesktop = width > 1160;
    final isCompact = width <= 552;
    final isNarrow = width <= 353;
    final isShort = isCompact && height <= 460;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _closeMenu,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              RepaintBoundary(
                child: _HeroVideoBackground(reducedMotion: _reducedMotion),
              ),
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF000000).withValues(alpha: 0.18),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    _buildHeroContent(
                        size, unit, isDesktop, isCompact, isShort, isNarrow),
                    if (!isDesktop && _menuOpen) _buildMenuBackdrop(),
                    if (!isDesktop && _menuOpen)
                      _buildMenu(size, unit, isCompact),
                    _buildNav(size, unit, isDesktop, isCompact),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNav(Size size, double unit, bool isDesktop, bool isCompact) {
    final navHeight = isDesktop ? 67 * unit : _max(58, 67 * unit);
    final horizontalPadding = isDesktop ? 24.5 * unit : _max(24, 28 * unit);
    final rightPadding = isDesktop ? 50.7 * unit : _max(24, 28 * unit);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: navHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            rightPadding,
            0,
          ),
          child: Row(
            children: [
              _Reveal(
                controller: _entranceController,
                start: 0.46,
                duration: 0.62,
                slideY: 9 * unit,
                child: GeoBuzzBrandLogo(
                  size: _max(24, 26 * unit),
                  showTagline: isDesktop,
                  isDark: true,
                ),
              ),
              if (isDesktop) ...[
                Expanded(
                  child: Align(
                    alignment: const Alignment(-0.14, 0),
                    child: Transform.translate(
                      offset: Offset(-23 * unit, 0),
                      child: _buildDesktopLinks(unit),
                    ),
                  ),
                ),
                _buildDesktopActions(unit),
              ] else ...[
                const Spacer(),
                _Reveal(
                  controller: _entranceController,
                  start: 0.68,
                  duration: 0.55,
                  slideY: 8 * unit,
                  child: _buildBurger(unit),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLinks(double unit) {
    const labels = <String>[
      'Products',
      'Pricing',
      'Developers',
      'Resources',
      'Contact Sales',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        labels.length,
        (index) => _Reveal(
          controller: _entranceController,
          start: 0.54 + index * 0.045,
          duration: 0.55,
          slideY: 9 * unit,
          child: _NavLink(
            label: labels[index],
            color: const Color(0xFFEDEDED),
            onTap:
                labels[index] == 'Contact Sales' ? _showContactDialog : () {},
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActions(double unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Reveal(
          controller: _entranceController,
          start: 0.68,
          duration: 0.55,
          slideY: 8 * unit,
          child: _ActionButton(
            label: 'Login',
            height: _max(28, 28 * unit),
            fontSize: _max(11.5, 11.5 * unit),
            horizontalPaddingStart: _max(12.9, 12.9 * unit),
            horizontalPaddingEnd: _max(12.9, 12.9 * unit),
            arrowSize: const Size(11.5, 9.6),
            onPressed: _openAuth,
          ),
        ),
        SizedBox(width: _max(6.8, 6.8 * unit)),
        _Reveal(
          controller: _entranceController,
          start: 0.73,
          duration: 0.55,
          slideY: 8 * unit,
          child: _ActionButton(
            label: 'Get Started',
            height: _max(28, 28 * unit),
            fontSize: _max(11.1, 11.1 * unit),
            horizontalPaddingStart: _max(13.5, 13.5 * unit),
            horizontalPaddingEnd: _max(14.5, 14.5 * unit),
            arrowSize: Size(
              _max(11.5, 11.5 * unit),
              _max(9.6, 9.6 * unit),
            ),
            onPressed: _continue,
          ),
        ),
      ],
    );
  }

  Widget _buildBurger(double unit) {
    final height = _max(38, 34 * unit);
    final width = _max(46, 48 * unit);
    return Material(
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(height / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(height / 2),
        onTap: () => _setMenuOpen(!_menuOpen),
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            _menuOpen ? Icons.close_rounded : Icons.menu_rounded,
            color: const Color(0xFFEDEDED),
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(
    Size size,
    double unit,
    bool isDesktop,
    bool isCompact,
    bool isShort,
    bool isNarrow,
  ) {
    final width = size.width;
    final headlineSize = isCompact ? _min(64, (width - 44) / 9.4) : 89 * unit;
    final headlineLineHeight = isCompact ? 1.04 : 90 * unit / headlineSize;
    final subSize = isCompact
        ? _min(16.5, _max(15.5, width * 0.04))
        : _max(16, 17.4 * unit);
    final subLineHeight = isCompact ? 1.6 : 27 * unit / subSize;
    final ctaHeight = isCompact ? _max(46, 39 * unit) : _max(44, 39 * unit);
    final ctaFontSize =
        isCompact ? _max(15, 13.3 * unit) : _max(15, 13.3 * unit);
    final subCopy = isCompact
        ? 'GeoBuzz automatically triggers the right action when you arrive, leave, or enter a place.'
        : 'GeoBuzz automatically triggers the right action\nwhen you arrive, leave, or enter a place.';
    final horizontalPadding = isCompact ? 20.0 : 24.0;
    final maxWidth = isCompact ? width - 40 : _min(width - 48, 900);

    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(
            isDesktop ? 8.5 * unit : 0,
            isDesktop ? 13.1 * unit : 0,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _max(1, maxWidth)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Reveal(
                    controller: _entranceController,
                    start: 0.12,
                    duration: 1.05,
                    slideY: 0,
                    mask: true,
                    child: Text(
                      'Your Location.',
                      softWrap: false,
                      style: _headlineFont(
                        size: headlineSize,
                        weight: FontWeight.w500,
                        color: Colors.white,
                        height: headlineLineHeight,
                        letterSpacing: isCompact ? -0.02 : -1 * unit,
                      ),
                    ),
                  ),
                  _Reveal(
                    controller: _entranceController,
                    start: 0.22,
                    duration: 1.05,
                    slideY: 0,
                    mask: true,
                    child: Text(
                      'Your Automation.',
                      softWrap: false,
                      style: _headlineFont(
                        size: headlineSize,
                        weight: FontWeight.w500,
                        color: Colors.white,
                        height: headlineLineHeight,
                        letterSpacing: isCompact ? -0.02 : -1 * unit,
                      ),
                    ),
                  ),
                  _Reveal(
                    controller: _entranceController,
                    start: 0.58,
                    duration: 0.85,
                    slideY: isCompact ? 12 * unit : 14 * unit,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isCompact ? 16 : _max(26, 16.1 * unit),
                      ),
                      child: Text(
                        subCopy,
                        textAlign: TextAlign.center,
                        style: _font(
                          size: subSize,
                          weight: FontWeight.w300,
                          color: const Color(0xFFF6F6F6),
                          height: subLineHeight,
                          letterSpacing: isCompact ? 0 : -0.3 * unit,
                        ),
                      ),
                    ),
                  ),
                  _Reveal(
                    controller: _entranceController,
                    start: isCompact ? 0.84 : 0.9,
                    duration: 0.7,
                    slideY: 8 * unit,
                    scale: 0.972,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isCompact
                            ? (isShort ? 18 : 24)
                            : _max(26, 21.8 * unit),
                      ),
                      child: _buildCtas(
                        width,
                        unit,
                        isCompact,
                        isNarrow,
                        ctaHeight,
                        ctaFontSize,
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

  Widget _buildCtas(
    double width,
    double unit,
    bool isCompact,
    bool isNarrow,
    double height,
    double fontSize,
  ) {
    final primary = _ActionButton(
      label: 'Get Started',
      isPrimary: true,
      height: height,
      fontSize: fontSize,
      horizontalPaddingStart:
          isCompact ? _max(20, 18.2 * unit) : _max(21, 18.2 * unit),
      horizontalPaddingEnd:
          isCompact ? _max(21, 19.2 * unit) : _max(22, 19.2 * unit),
      arrowSize: Size(
        isCompact ? 13 : _max(14, 13 * unit),
        isCompact ? 11 : _max(11.6, 10.8 * unit),
      ),
      onPressed: _continue,
    );

    if (isNarrow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _min(width - 40, 272),
            child: primary,
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: isCompact ? 10 : _max(10, 7 * unit),
      runSpacing: 10,
      children: [primary],
    );
  }

  Widget _buildMenuBackdrop() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildMenu(Size size, double unit, bool isCompact) {
    final top = _max(58, 67 * unit) - 6;
    final horizontal = isCompact ? 16.0 : _max(24, 28 * unit);
    final width = isCompact ? null : _min(320, size.width - 48);

    return Positioned(
      top: top,
      left: isCompact ? horizontal : null,
      right: isCompact ? horizontal : horizontal,
      width: width,
      child: IgnorePointer(
        ignoring: !_menuOpen,
        child: AnimatedOpacity(
          opacity: _menuOpen ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Transform.scale(
            alignment: Alignment.topRight,
            scale: _menuOpen ? 1 : 0.985,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                // sigma 22 -> 14: visually identical for a dark card,
                // ~2x cheaper on the GPU. This subtree is now only built
                // when _menuOpen, so it no longer blurs the video each frame.
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0C).withValues(alpha: 0.86),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 32,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem('Products', () {}),
                      _buildMenuItem('Pricing', () {}),
                      _buildMenuItem('Developers', () {}),
                      _buildMenuItem('Resources', () {}),
                      _buildMenuItem('Contact Sales', _showContactDialog),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem('Login', _openAuth),
                      const SizedBox(height: 6),
                      _ActionButton(
                        label: 'Get Started',
                        isPrimary: true,
                        height: 46,
                        fontSize: 15,
                        horizontalPaddingStart: 16,
                        horizontalPaddingEnd: 16,
                        arrowSize: const Size(13, 11),
                        onPressed: _continue,
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

  Widget _buildMenuItem(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _closeMenu();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HeroVideoBackground extends StatefulWidget {
  const _HeroVideoBackground({required this.reducedMotion});

  final bool reducedMotion;

  @override
  State<_HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<_HeroVideoBackground> {
  static const String _videoUrl =
      'https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260912_104036_bd6924f6-3c8e-417e-8465-6d03c8c2e9e6.mp4';
  static const String _posterUrl =
      'https://d2ol7oe51mr4n9.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/82e7eb75-c65f-490a-99b5-f3d1cad54200.webp';

  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
  }

  @override
  void didUpdateWidget(covariant _HeroVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      _applyReducedMotion();
    }
  }

  Future<void> _initializeVideo() async {
    final options = VideoPlayerOptions(
      mixWithOthers: true,
      allowBackgroundPlayback: false,
      preventsDisplaySleepDuringVideoPlayback: false,
      webOptions: VideoPlayerWebOptions(
        controls: const VideoPlayerWebOptionsControls.disabled(),
        allowContextMenu: false,
        allowRemotePlayback: false,
        poster: Uri.parse(_posterUrl),
      ),
    );
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_videoUrl),
      videoPlayerOptions: options,
    );
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted) return;
      setState(() => _initialized = true);
      await _applyReducedMotion();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _failed = true;
      });
    }
  }

  Future<void> _applyReducedMotion() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    try {
      if (widget.reducedMotion) {
        await controller.pause();
        await controller.seekTo(Duration.zero);
      } else if (_initialized && !_failed) {
        await controller.play();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        // Poster is always in the tree so there is no black flash while
        // the video buffers. It is covered once the first frame renders.
        Positioned.fill(
          child: Image.network(
            _posterUrl,
            fit: BoxFit.cover,
            alignment: const Alignment(0.51, -0.84),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        if (_initialized && !_failed && _controller != null)
          _CoveredVideo(controller: _controller!),
      ],
    );
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_disposeController(controller));
    }
    super.dispose();
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    try {
      await controller.pause();
    } catch (_) {}
    await controller.dispose();
  }
}

class _CoveredVideo extends StatelessWidget {
  const _CoveredVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        const videoRatio = 16.0 / 9.0;
        final containerRatio = constraints.maxWidth / constraints.maxHeight;
        final scale = _max(
          containerRatio / videoRatio,
          videoRatio / containerRatio,
        );
        return ClipRect(
          child: Align(
            alignment: const Alignment(0.02, -0.84),
            child: Transform.scale(
              // Transform alone would repaint the video every frame.
              // RepaintBoundary isolates it from the text/buttons above.
              scale: scale,
              child: RepaintBoundary(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.controller,
    required this.start,
    required this.duration,
    this.slideY = 0,
    this.scale = 1,
    this.mask = false,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final double duration;
  final double slideY;
  final double scale;
  final bool mask;
  final Widget child;

  double _progress() {
    if (controller.value <= start) return 0;
    final raw = ((controller.value - start) / duration).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.isCompleted ? 1.0 : _progress();
        Widget result = child!;
        if (mask) result = ClipRect(child: result);
        // RepaintBoundary keeps these per-tick opacity/transform updates
        // from repainting the video layer underneath.
        return RepaintBoundary(
          child: Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, slideY * (1 - progress)),
              child: Transform.scale(
                scale: scale + (1 - scale) * (1 - progress),
                child: result,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? Colors.white : widget.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.isPrimary = false,
    required this.height,
    required this.fontSize,
    required this.horizontalPaddingStart,
    required this.horizontalPaddingEnd,
    required this.arrowSize,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final double height;
  final double fontSize;
  final double horizontalPaddingStart;
  final double horizontalPaddingEnd;
  final Size arrowSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(height / 2);
    return Material(
      color: isPrimary
          ? const Color(0xFFFDFDFD)
          : const Color(0xFF000000).withValues(alpha: 0.78),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: Container(
          height: height,
          padding: EdgeInsets.only(
            left: horizontalPaddingStart,
            right: horizontalPaddingEnd,
          ),
          decoration: BoxDecoration(
            border: isPrimary
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? const Color(0xFF050505)
                      : const Color(0xFFD9D9D9),
                  fontSize: fontSize,
                  fontWeight: isPrimary ? FontWeight.w500 : FontWeight.w500,
                  letterSpacing: isPrimary ? 0 : -0.15,
                  height: 1,
                ),
              ),
              SizedBox(width: _max(7, arrowSize.width * 0.62)),
              CustomPaint(
                size: arrowSize,
                painter: _ArrowPainter(
                  color: isPrimary
                      ? const Color(0xFF050505)
                      : const Color(0xFFD9D9D9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.35
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.07, size.height * 0.5)
      ..lineTo(size.width * 0.92, size.height * 0.5)
      ..moveTo(size.width * 0.62, size.height * 0.14)
      ..lineTo(size.width * 0.94, size.height * 0.5)
      ..lineTo(size.width * 0.62, size.height * 0.86);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
