import 'package:flutter/material.dart';

class BreathingWidget extends StatefulWidget {
  const BreathingWidget({super.key});

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<String> _phrases = [
    'Inhala',
    'Sostén',
    'Exhala',
    'Descansa',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
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
        final cycle = (_controller.value * _phrases.length).floor();
        final phaseIndex = cycle.clamp(0, _phrases.length - 1);
        final scale = 0.8 + 0.4 * (0.5 - ( (_controller.value * 2) % 1 - 0.5).abs());
        return Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8FB3FF).withOpacity(0.2),
              ),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8FB3FF), Color(0xFFAED9FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _phrases[phaseIndex],
              style: const TextStyle(
                color: Color(0xFF35527D),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
