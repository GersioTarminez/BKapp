import 'dart:async';
import 'package:flutter/material.dart';

import '../services/experience_flags_service.dart';
import '../services/session_log_service.dart';
import '../services/sound_service.dart';
import 'bubble_calm_controller.dart';

class BubbleCalmScreen extends StatefulWidget {
  const BubbleCalmScreen({super.key});

  @override
  State<BubbleCalmScreen> createState() => _BubbleCalmScreenState();
}

class _BubbleCalmScreenState extends State<BubbleCalmScreen> {
  final BubbleCalmController _controller = BubbleCalmController();
  final ExperienceFlagsService _flags = ExperienceFlagsService.instance;
  final SessionLogService _sessionLog = SessionLogService.instance;
  Timer? _timer;
  bool _currentTapHitBubble = false;

  @override
  void initState() {
    super.initState();
    _sessionLog.startBubbleSession();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(_controller.tick);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTip();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_sessionLog.endBubbleSession());
    super.dispose();
  }

  Future<void> _maybeShowTip() async {
    final shown = await _flags.wasShown('bubble_tip');
    if (shown || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calma de Burbujas'),
        content: const Text(
          'Toca las burbujas con calma, escucha su sonido suave y observa cómo desaparecen. No hay prisa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
    await _flags.markShown('bubble_tip');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _controller.updateScreenSize(screenSize);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calma de Burbujas'),
        backgroundColor: const Color(0xFF8FB3FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Información de sesión',
            icon: const Icon(Icons.insights),
            onPressed: _showSessionInfo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          _currentTapHitBubble = false;
          Future.microtask(() {
            if (!_currentTapHitBubble) {
              _sessionLog.recordBubbleMiss();
            }
          });
        },
        child: Container(
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
              ..._controller.bubbles.map(
                (burbuja) => Positioned(
                  left: burbuja.x,
                  top: burbuja.y,
                  child: GestureDetector(
                    onTap: () {
                      _currentTapHitBubble = true;
                      _sessionLog.recordBubblePop();
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
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Toca una burbuja para dejarla subir suave.',
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
      ),
    );
  }

  Future<void> _showSessionInfo() async {
    final sessions =
        await _sessionLog.loadSessions(game: SessionGame.bubbleCalm);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No session data yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[sessions.length - 1 - index];
            final metrics = session.metrics;
            final mean = metrics['mean_tap_interval_ms'] as num?;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  'Sesión ${session.startedAt.toLocal()}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Burbujas: ${metrics['bubbles_popped'] ?? 0} • Fallos: ${metrics['missed_taps'] ?? 0}\nPromedio toque: ${mean == null ? '-' : mean.toStringAsFixed(1)} ms',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
