import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shared hero video background (single looping controller).
///
/// Used by both the marketing hero and the auth screen so the login page
/// appears over the exact same background.
class HeroVideoBackground extends StatefulWidget {
  const HeroVideoBackground({super.key, required this.reducedMotion});

  final bool reducedMotion;

  @override
  State<HeroVideoBackground> createState() => HeroVideoBackgroundState();
}

class HeroVideoBackgroundState extends State<HeroVideoBackground> {
  static const String videoUrl =
      'https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260912_104036_bd6924f6-3c8e-417e-8465-6d03c8c2e9e6.mp4';
  static const String posterUrl =
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
  void didUpdateWidget(covariant HeroVideoBackground oldWidget) {
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
        poster: Uri.parse(posterUrl),
      ),
    );
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
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
            posterUrl,
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
        final scale = math.max(
          containerRatio / videoRatio,
          videoRatio / containerRatio,
        );
        return ClipRect(
          child: Align(
            alignment: const Alignment(0.02, -0.84),
            child: Transform.scale(
              // Transform alone would repaint the video every frame.
              // RepaintBoundary isolates it from the content above.
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
