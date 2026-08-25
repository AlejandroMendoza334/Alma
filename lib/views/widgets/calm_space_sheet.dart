import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'breathing_exercise_card.dart';

class CalmSpaceSheet extends StatefulWidget {
  final bool startWithBreathing;

  const CalmSpaceSheet({super.key, this.startWithBreathing = true});

  @override
  State<CalmSpaceSheet> createState() => _CalmSpaceSheetState();
}

class _CalmSpaceSheetState extends State<CalmSpaceSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSoundLabel;

  // Mapeo de etiqueta a nombre de archivo MP3 dentro de assets/audio/
  final Map<String, String> _soundFiles = {
    'Lluvia': 'rain.mp3',
    'Océano': 'ocean.mp3',
    'Bosque': 'forest.mp3',
    'Noche': 'night.mp3',
  };

  @override
  void initState() {
    super.initState();
    // Repetir el sonido en bucle continuo
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose(); // Libera la memoria del reproductor al cerrar el modal
    super.dispose();
  }

  Future<void> _toggleSound(String label) async {
    if (_selectedSoundLabel == label) {
      // Si presiona el sonido activo, lo detiene
      await _audioPlayer.stop();
      setState(() {
        _selectedSoundLabel = null;
      });
    } else {
      // Cambia de sonido o inicia la reproducción
      final fileName = _soundFiles[label];
      if (fileName != null) {
        try {
          await _audioPlayer.stop();
          // Ruta relativa a la carpeta assets/
          await _audioPlayer.play(AssetSource('audio/$fileName'));
          setState(() {
            _selectedSoundLabel = label;
          });
        } catch (e) {
          debugPrint('Error al reproducir audio audio/$fileName: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3B59),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.startWithBreathing ? 'Pausa de Respiración' : 'Espacio en Silencio',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            if (widget.startWithBreathing) ...[
              const BreathingExerciseCard(),
              const SizedBox(height: 24),
            ],

            Text(
              'Sonidos de Ambiente',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8A889D),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSoundChip(Icons.water_drop_outlined, 'Lluvia'),
                _buildSoundChip(Icons.waves_rounded, 'Océano'),
                _buildSoundChip(Icons.forest_outlined, 'Bosque'),
                _buildSoundChip(Icons.nightlight_round, 'Noche'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundChip(IconData icon, String label) {
    final isSelected = _selectedSoundLabel == label;

    return GestureDetector(
      onTap: () => _toggleSound(label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF1C1936),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : const Color(0xFF2B264A),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B73FF),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF8A889D),
            ),
          ),
        ],
      ),
    );
  }
}