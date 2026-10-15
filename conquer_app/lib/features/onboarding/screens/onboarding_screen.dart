import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/cyber_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'CLAIM YOUR WORLD',
      'subtitle': 'Real-World Territory Conquest',
      'description':
          'Transform your physical steps, jogs, and runs into real geographic territory on an interactive cyber map.',
      'icon': Icons.map_outlined,
      'color': AppColors.neonCyan,
      'tag': 'GPS EXPLORATION',
    },
    {
      'title': 'CLOSE THE LOOP',
      'subtitle': 'Algorithmic Land Claims',
      'description':
          'Walk in a loop of at least 100 meters and return to your start point. The moment your loop closes, the enclosed land is claimed!',
      'icon': Icons.all_inclusive,
      'color': AppColors.neonEmerald,
      'tag': 'LOOP DETECTION',
    },
    {
      'title': 'DEFEND YOUR EMPIRE',
      'subtitle': 'Multiplayer Rivalries & Loot',
      'description':
          'Carve out enemy sectors, reinforce your borders with coins, earn tactical XP, and climb the global leaderboards.',
      'icon': Icons.shield_outlined,
      'color': AppColors.neonCrimson,
      'tag': 'TACTICAL BATTLES',
    },
  ];

  void _finishOnboarding(WidgetRef ref) {
    ref.read(authProvider.notifier).completeOnboarding();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header with Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonCyan.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.neonCyan, width: 1.2),
                            ),
                            child: const Icon(Icons.shield, color: AppColors.neonCyan, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CONQUER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _finishOnboarding(ref),
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slide Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      final Color color = slide['color'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Graphic Icon Hero
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.12),
                                border: Border.all(color: color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(slide['icon'], size: 64, color: color),
                            ),
                            const SizedBox(height: 36),

                            // Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                slide['tag'],
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title & Subtitle
                            Text(
                              slide['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide['subtitle'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text(
                              slide['description'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indicators & Controls
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          final isSelected = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.neonCyan
                                  : AppColors.borderSubtle,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Next / Start Button
                      CyberButton(
                        text: _currentIndex == _slides.length - 1
                            ? 'COMMENCE RECON'
                            : 'NEXT BRIEFING',
                        icon: _currentIndex == _slides.length - 1
                            ? Icons.radar
                            : Icons.arrow_forward,
                        width: double.infinity,
                        variant: CyberButtonVariant.cyan,
                        onPressed: () {
                          if (_currentIndex < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding(ref);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
