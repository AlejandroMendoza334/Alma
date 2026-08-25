import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BreathingPhase { inhale, hold, exhale }

class BreathingExerciseCard extends StatefulWidget {
  final Function(bool)? onFinished;
  final VoidCallback? onStopped;

  const BreathingExerciseCard({
    super.key,
    this.onFinished,
    this.onStopped,
  });

  @override
  State<BreathingExerciseCard> createState() => BreathingExerciseCardState();
}

// Hacemos el State público (quitamos el guion bajo) para usarlo con GlobalKey
class BreathingExerciseCardState extends State<BreathingExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  int _cyclesCount = 0;
  int _secondsRemaining = 4;
  BreathingPhase _currentPhase = BreathingPhase.inhale;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final int _inhaleTime = 4;
  final int _holdTime = 4;
  final int _exhaleTime = 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleTime),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  // Método público para iniciar el ejercicio desde la IA o cualquier parte externa
  void startExercise() {
    if (!_isActive) {
      _startExerciseLogic();
    }
  }

  void _startExerciseLogic() {
    setState(() {
      _isActive = true;
      _cyclesCount = 0;
      _currentPhase = BreathingPhase.inhale;
      _secondsRemaining = _inhaleTime;
    });

    _runPhaseAnimation();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _nextPhase();
        }
      });
    });
  }

  void _runPhaseAnimation() {
    _animController.stop();

    if (_currentPhase == BreathingPhase.inhale) {
      _animController.duration = Duration(seconds: _inhaleTime);
      _animController.forward(from: _animController.value);
    } else if (_currentPhase == BreathingPhase.hold) {
      _animController.value = 1.0;
    } else if (_currentPhase == BreathingPhase.exhale) {
      _animController.duration = Duration(seconds: _exhaleTime);
      _animController.reverse(from: _animController.value);
    }
  }

  void _nextPhase() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        _currentPhase = BreathingPhase.hold;
        _secondsRemaining = _holdTime;
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.exhale;
        _secondsRemaining = _exhaleTime;
        break;
      case BreathingPhase.exhale:
        _currentPhase = BreathingPhase.inhale;
        _secondsRemaining = _inhaleTime;
        _cyclesCount++;
        break;
    }
    _runPhaseAnimation();
  }

void _stopExercise() {
    _timer?.cancel();
    _animController.stop();
    _animController.animateTo(0.0, duration: const Duration(milliseconds: 500));
    
    // 🔔 Avisamos al chat que se detuvo
    widget.onStopped?.call();

    if (mounted) {
      setState(() {
        _isActive = false;
        _secondsRemaining = 4;
        _currentPhase = BreathingPhase.inhale;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String get _phaseTitle {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'Inhala...';
      case BreathingPhase.hold:
        return 'Mantén...';
      case BreathingPhase.exhale:
        return 'Exhala...';
    }
  }

  Color get _phaseColor {
    if (!_isActive) return const Color(0xFF8B73FF);
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return const Color(0xFF6C5CE7);
      case BreathingPhase.hold:
        return const Color(0xFFFFB067);
      case BreathingPhase.exhale:
        return const Color(0xFF00CEC9);
    }
  }

  IconData get _phaseIcon {
    if (!_isActive) return Icons.spa_rounded;
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return Icons.filter_drama_rounded;
      case BreathingPhase.hold:
        return Icons.grain_rounded;
      case BreathingPhase.exhale:
        return Icons.air_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131126),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF231F3D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respiración 4-4-6',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_cyclesCount ${_cyclesCount == 1 ? "ciclo" : "ciclos"}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF8A889D),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: _isActive ? _stopExercise : _startExerciseLogic,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isActive ? const Color(0xFFFF6B6B) : const Color(0xFF6C5CE7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  _isActive ? 'Detener' : 'Iniciar',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isActive ? const Color(0xFFFF6B6B) : const Color(0xFF8B73FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final double scale = _isActive ? _scaleAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _phaseColor.withOpacity(0.15),
                    border: Border.all(color: _phaseColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor.withOpacity(_isActive ? 0.4 * (scale - 0.5) : 0.2),
                        blurRadius: _isActive ? 20 * scale : 10,
                        spreadRadius: _isActive ? 4 * scale : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _phaseIcon,
                      color: _phaseColor,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _isActive ? _phaseTitle : 'Presiona Iniciar',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isActive ? '$_secondsRemaining segundos' : '1 min para calmar tu mente',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF8A889D),
            ),
          ),
        ],
      ),
    );
  }
}