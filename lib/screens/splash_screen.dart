import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered animations
  late Animation<Offset> _coinTranslation;
  late Animation<double> _coinOpacity;
  late Animation<double> _walletScale;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Timeline definitions
    _coinTranslation = Tween<Offset>(
      begin: const Offset(0, -250),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: Curves.bounceOut),
    ));

    _coinOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.50, curve: Curves.easeIn),
    ));

    _walletScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.90, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.60, curve: Curves.easeInOut),
    ));

    _rippleScale = Tween<double>(
      begin: 0.8,
      end: 2.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.70, curve: Curves.easeOutCubic),
    ));

    _rippleOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.70, curve: Curves.easeOutCubic),
    ));

    _logoScale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutBack),
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    ));

    _textSlide = Tween<double>(
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
    ));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeIn),
    ));

    _controller.forward().then((_) => _navigateToNextScreen());
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = prefs.getBool('isFirstTime') ?? true;
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    if (_isFirstTime) {
      Navigator.of(context).pushReplacementNamed('/welcome');
    } else {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Colors.grey[900]!,
                    colorScheme.primary.withValues(alpha: 0.08),
                    Colors.black,
                  ]
                : [
                    Colors.white,
                    colorScheme.primary.withValues(alpha: 0.04),
                    Colors.grey[50]!,
                  ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect (shown after coin lands)
                  if (_rippleScale.value > 0.8 && _rippleOpacity.value > 0)
                    Opacity(
                      opacity: _rippleOpacity.value,
                      child: Transform.scale(
                        scale: _rippleScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main Wallet / Logo transition block
                  if (_logoOpacity.value < 0.98)
                    Opacity(
                      opacity: (1.0 - _logoOpacity.value).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Falling Coin
                          if (_coinOpacity.value > 0)
                            Transform.translate(
                              offset: _coinTranslation.value,
                              child: Opacity(
                                opacity: _coinOpacity.value.clamp(0.0, 1.0),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade300,
                                        Colors.amber.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '\$',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Wallet
                          Transform.scale(
                            scale: _walletScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 60,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // PocketWise Logo and Title fade-in block
                  if (_logoOpacity.value > 0)
                    Opacity(
                      opacity: _logoOpacity.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // App Logo SVG
                            SvgPicture.asset(
                              'assets/images/logo.svg',
                              height: 80,
                              colorFilter: ColorFilter.mode(
                                colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                              placeholderBuilder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.business_center,
                                  size: 40,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Title and subtitle
                            Opacity(
                              opacity: _textOpacity.value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, _textSlide.value),
                                child: Column(
                                  children: [
                                    Text(
                                      'PocketWise',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                      child: Text(
                                        languageProvider.translate('smart_tracking_sub')?.replaceAll('\n', ' ') ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                        textAlign: TextAlign.center,
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
