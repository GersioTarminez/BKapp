import 'dart:async';
import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'bubble_calm_controller.dart';

class BubbleCalmScreen extends StatefulWidget {
  const BubbleCalmScreen({super.key});

  @override
  State<BubbleCalmScreen> createState() => _BubbleCalmScreenState();
}

class _BubbleCalmScreenState extends State<BubbleCalmScreen> {
  final BubbleCalmController _controller = BubbleCalmController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(_controller.tick);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _controller.updateScreenSize(screenSize);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Calm'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFBFD7FF),
          image: DecorationImage(
            image: AssetImage('assets/images/bubble_bg.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.35,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 26,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Respira hondo y deja que las burbujas suban lentas como tus pensamientos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF35527D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ..._controller.bubbles.map((burbuja) {
              return Positioned(
                left: burbuja.x,
                top: burbuja.y,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.explode(burbuja);
                      SoundService.instance.playBubblePop();
                    });
                  },
                  child: Opacity(
                    opacity: burbuja.isExploding
                        ? (1 - burbuja.explosionProgress).clamp(0.0, 1.0)
                        : 1,
                    child: Transform.scale(
                      scale: burbuja.isExploding
                          ? 1 + burbuja.explosionProgress * 0.3
                          : 1,
                      child: Container(
                        width: burbuja.size,
                        height: burbuja.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.35),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tap a bubble to let it float away.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
