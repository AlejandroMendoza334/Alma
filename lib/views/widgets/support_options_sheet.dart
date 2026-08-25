import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calm_space_sheet.dart';

class SupportOptionsSheet extends StatelessWidget {
  final String apiKey;
  final VoidCallback onOpenSettings;
  final VoidCallback onStartVenting;
  final VoidCallback onStartBreathing;
  final VoidCallback onStartCalmSpace;

  const SupportOptionsSheet({
    super.key,
    required this.apiKey,
    required this.onOpenSettings,
    required this.onStartVenting,
    required this.onStartBreathing,
    required this.onStartCalmSpace,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasApiKey = apiKey.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF131126),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador superior de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3B59),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Estamos contigo',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lamentamos que sea un momento difícil. ¿Cómo prefieres que te acompañemos ahora?',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF8A889D),
            ),
          ),

          const SizedBox(height: 20),

          // Aviso de API Key si no está configurada
          if (!hasApiKey) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_off_outlined, color: Color(0xFFFF6B6B), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Key requerida para hablar con Alma',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Agrega tu clave en Ajustes para activar las respuestas de IA.',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFFD3A2C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenSettings,
                    child: Text(
                      'Configurar',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B73FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Opción 1: Desahogarse con Alma
          _buildOptionCard(
            context: context,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Desahogarme con Alma',
            subtitle: 'Expresa lo que sientes sin filtros ni juicios.',
            badgeText: !hasApiKey ? 'Requiere API Key' : null,
            onTap: hasApiKey ? onStartVenting : onOpenSettings,
          ),

          const SizedBox(height: 12),

          // Opción 2: Pausa de Respiración
          _buildOptionCard(
            context: context,
            icon: Icons.self_improvement_rounded,
            title: 'Pausa de Respiración',
            subtitle: '1 minuto para liberar tensión corporal.',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CalmSpaceSheet(startWithBreathing: true),
              );
            },
          ),

          const SizedBox(height: 12),

          // Opción 3: Espacio en Silencio
          _buildOptionCard(
            context: context,
            icon: Icons.nightlight_round,
            title: 'Espacio en Silencio',
            subtitle: 'Sonidos de ambiente tranquilizadores.',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CalmSpaceSheet(startWithBreathing: false),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
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
              child: Icon(icon, color: const Color(0xFF8B73FF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B2D20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: const Color(0xFFFFB067),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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