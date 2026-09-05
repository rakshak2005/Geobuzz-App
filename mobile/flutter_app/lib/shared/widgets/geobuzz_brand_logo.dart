import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GeoBuzzBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;
  final bool isDark;
  final bool useBanner;

  const GeoBuzzBrandLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.showTagline = false,
    this.isDark = true,
    this.useBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useBanner) {
      return Image.asset(
        'assets/images/logo_banner.png',
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/logo.png',
          height: size,
          width: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Official GeoBuzz Pin & Wave Logo Asset
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.brandGradient : const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: size * 0.6,
                ),
              );
            },
          ),
        ),

        if (showText) ...[
          SizedBox(width: size * 0.3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Geo',
                      style: TextStyle(
                        fontSize: size * 0.54,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Buzz',
                      style: TextStyle(
                        fontSize: size * 0.54,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.accent : const Color(0xFF0D9488),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 2),
                Text(
                  'AUTOMATE BY LOCATION',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
