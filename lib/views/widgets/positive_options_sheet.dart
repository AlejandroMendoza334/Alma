// lib/views/widgets/positive_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PositiveOptionsSheet extends StatelessWidget {
  final String moodSubtitle;
  final VoidCallback onGoToAffirmations;
  final VoidCallback onTalkToAlma;
  final VoidCallback onFinish;

  const PositiveOptionsSheet({
    super.key,
    required this.moodSubtitle,
    required this.onGoToAffirmations,
    required this.onTalkToAlma,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF131126),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador superior
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3F3B59),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Ícono personalizado (icon.jpg)
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/icon.jpg'), // Asegúrate de agregarlo a pubspec.yaml
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Título dinámico según la opción
          Text(
            moodSubtitle == 'Excelente' ? '¡Nos alegra verte brillar!' : '¡Qué gran momento!',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aprovecha esta buena energía para potenciar tu día y cultivar tu bienestar.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF8A889D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Opción 1: Ver Afirmaciones del Día
          _buildOptionCard(
            context: context,
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFFFFD700),
            title: 'Afirmación del Día',
            subtitle: 'Encuentra pensamientos que potencien tu energía.',
            onTap: onGoToAffirmations,
          ),
          const SizedBox(height: 12),

          // Opción 2: Compartir o Reflexionar con Alma
          _buildOptionCard(
            context: context,
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF8B73FF),
            title: 'Compartir con Alma',
            subtitle: 'Cuéntale qué hizo que hoy fuera un buen día.',
            onTap: onTalkToAlma,
          ),
          const SizedBox(height: 20),

          // Botón secundario para finalizar e ir al Home
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onFinish,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Guardar y volver al inicio',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A889D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1936),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B264A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF29244D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF8A889D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5A567D), size: 20),
          ],
        ),
      ),
    );
  }
}