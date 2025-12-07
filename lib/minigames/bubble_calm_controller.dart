import 'dart:math';

import 'package:flutter/material.dart';

/// Handles bubble creation, animation updates and explosions for BubbleCalm.
class BubbleCalmController {
  BubbleCalmController({this.bubbleCount = 14}) {
    _createBubbles();
  }

  final int bubbleCount;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();
  Size _screenSize = Size.zero;

  List<Bubble> get bubbles => List.unmodifiable(_bubbles);

  void updateScreenSize(Size size) {
    _screenSize = size;
    if (_screenSize == Size.zero) return;
    for (final bubble in _bubbles) {
      if (!bubble.initialized) {
        _resetBubble(bubble);
      }
    }
  }

  void tick() {
    if (_screenSize == Size.zero) return;
    for (final bubble in _bubbles) {
      if (bubble.isExploding) {
        bubble.explosionProgress += 0.05;
        if (bubble.explosionProgress >= 1) {
          _resetBubble(bubble);
        }
        continue;
      }

      bubble.y -= bubble.speed;
      if (bubble.y + bubble.size < 0) {
        _resetBubble(bubble);
      }
    }
  }

  void explode(Bubble bubble) {
    if (bubble.isExploding) return;
    bubble
      ..isExploding = true
      ..explosionProgress = 0;
  }

  void _createBubbles() {
    for (var i = 0; i < bubbleCount; i++) {
      _bubbles.add(
        Bubble(
          size: 40 + _random.nextDouble() * 30,
          speed: 0.8 + _random.nextDouble() * 1.4,
        ),
      );
    }
  }

  void _resetBubble(Bubble bubble) {
    if (_screenSize == Size.zero) return;
    bubble
      ..size = 40 + _random.nextDouble() * 40
      ..speed = 0.8 + _random.nextDouble() * 1.6
      ..x = _random.nextDouble() *
          (_screenSize.width - bubble.size - 16).clamp(0, double.infinity) +
          8
      ..y = _screenSize.height + _random.nextDouble() * 200
      ..isExploding = false
      ..explosionProgress = 0
      ..initialized = true;
  }
}

class Bubble {
  Bubble({
    required this.size,
    required this.speed,
  });

  double x = 0;
  double y = 0;
  double size;
  double speed;
  bool isExploding = false;
  double explosionProgress = 0;
  bool initialized = false;
}
