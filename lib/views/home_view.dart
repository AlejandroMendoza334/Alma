import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_flow/views/widgets/calm_space_sheet.dart';
import '../features/affirmations/data/models/models.dart';
import '../services/theme.dart';

class HomeView extends StatelessWidget {
  final Affirmation dailyAffirmation;
  final VoidCallback onRefreshAffirmation;
  final ProviderAI provider;
  final bool hasApiKey;
  final Function(ViewState) onNavigate;
  final List<Affirmation> affirmationsList;

  const HomeView({
    super.key,
    required this.dailyAffirmation,
    required this.onRefreshAffirmation,
    required this.provider,
    required this.hasApiKey,
    required this.onNavigate,
    required this.affirmationsList,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        // --- 1. CABECERA CON ESTADO DE IA INTEGRADO ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido a Alma',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu espacio seguro de bienestar',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AlmaTheme.mutedForeground,
                  ),
                ),
              ],
            ),
            _buildAiBadgeCompact(),
          ],
        ),

        const SizedBox(height: 20),

        // --- 2. TARJETA AFIRMACIÓN DEL DÍA (Más estilizada y moderna) ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AlmaTheme.primary.withOpacity(0.35), width: 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2458), Color(0xFF141229)],
            ),
            boxShadow: [
              BoxShadow(
                color: AlmaTheme.primary.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AlmaTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'AFIRMACIÓN DEL DÍA',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AlmaTheme.primary,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onRefreshAffirmation,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'otra',
                            style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.refresh_rounded, size: 13, color: AlmaTheme.mutedForeground),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '"${dailyAffirmation.text}"',
                style: GoogleFonts.lora(
                  fontSize: 19,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AlmaTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dailyAffirmation.category,
                  style: GoogleFonts.nunito(
                    color: AlmaTheme.primary, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        
        Text(
          'ACCESOS RÁPIDOS',
          style: GoogleFonts.nunito(
            fontSize: 11, 
            color: AlmaTheme.mutedForeground, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),

        // --- 3. ACCIONES PRINCIPALES ---
        _buildActionCard(
          emoji: '🌸',
          title: '¿Cómo te sientes hoy?',
          subtitle: 'Registra tu estado de ánimo',
          onTap: () => onNavigate(ViewState.mood),
        ),

        const SizedBox(height: 12),

        _buildActionCard(
          emoji: '💬',
          title: 'Habla con Alma',
          subtitle: 'Apoyo emocional · siempre aquí',
          onTap: () => onNavigate(ViewState.chat),
        ),

        const SizedBox(height: 12),

        // --- 4. CARD RESPIRACIÓN 4-4-6 ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AlmaTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AlmaTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                ),
                child: const Center(child: Icon(Icons.air_rounded, color: Colors.cyanAccent, size: 22)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Respiración 4-4-6',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tómate un respiro consciente',
                      style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CalmSpaceSheet(startWithBreathing: true),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlmaTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Iniciar', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // --- 5. LISTA "MÁS AFIRMACIONES" ---
        Row( // <--- Sin 'const' aquí
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MÁS AFIRMACIONES',
              style: GoogleFonts.nunito(
                fontSize: 11, 
                color: AlmaTheme.mutedForeground, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2,
              ),
            ),
            const Icon(Icons.auto_stories_rounded, size: 14, color: AlmaTheme.mutedForeground),
          ],
        ),
        const SizedBox(height: 12),

        ...affirmationsList.take(6).map(
          (a) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AlmaTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlmaTheme.border),
            ),
            child: Row(
              children: [
                const Text('◆', style: TextStyle(color: AlmaTheme.primary, fontSize: 10)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.text,
                    style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiBadgeCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AlmaTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasApiKey ? AlmaTheme.border : AlmaTheme.accent.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: hasApiKey
            ? [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: provider == ProviderAI.anthropic
                        ? Colors.purpleAccent
                        : provider == ProviderAI.openai
                            ? Colors.greenAccent
                            : Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  provider == ProviderAI.anthropic
                      ? 'Claude'
                      : provider == ProviderAI.openai
                          ? 'ChatGPT'
                          : 'Gemini',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AlmaTheme.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                const Icon(Icons.warning_amber_rounded, size: 13, color: AlmaTheme.accent),
                const SizedBox(width: 4),
                Text(
                  'Sin Key',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AlmaTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildActionCard({required String emoji, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: AlmaTheme.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AlmaTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AlmaTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AlmaTheme.border),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: AlmaTheme.mutedForeground)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AlmaTheme.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}