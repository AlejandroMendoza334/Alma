import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/affirmations/data/models/models.dart';
import 'widgets/support_options_sheet.dart';
import 'widgets/positive_options_sheet.dart';
import 'widgets/calm_space_sheet.dart';

class MoodItem {
  final String title;
  final String subtitle;
  final String icon;

  const MoodItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class MoodSelectionView extends StatefulWidget {
  final String apiKey;
  final VoidCallback? onBack;
  final Function(ViewState)? onNavigate;
  final Function(dynamic)? onStateSelected;

  const MoodSelectionView({
    super.key,
    this.apiKey = '',
    this.onBack,
    this.onNavigate,
    this.onStateSelected,
  });

  @override
  State<MoodSelectionView> createState() => _MoodSelectionViewState();
}

class _MoodSelectionViewState extends State<MoodSelectionView> {
  int? _selectedIndex;

  // 3 Opciones principales simplificadas
  final List<MoodItem> _moods = const [
    MoodItem(title: 'Me siento bien', subtitle: 'Bien', icon: '🌸'),
    MoodItem(title: 'Más o menos', subtitle: 'Regular', icon: '🌤️'),
    MoodItem(title: 'No muy bien', subtitle: 'Mal', icon: '🌧️'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _selectedIndex != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Botón Volver
              GestureDetector(
                onTap: widget.onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: Color(0xFF9E9DAB), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Volver',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF9E9DAB),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Encabezado
              Text(
                '¿Cómo te encuentras hoy?',
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No hay respuesta incorrecta. Solo sé honesto/a contigo.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: const Color(0xFF8A889D),
                ),
              ),

              const SizedBox(height: 24),

              // Lista de 3 Opciones
              Expanded(
                child: ListView.separated(
                  itemCount: _moods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mood = _moods[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF231C3D) : const Color(0xFF131126),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF8B73FF) : const Color(0xFF24203D),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(mood.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mood.title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mood.subtitle,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: const Color(0xFF8A889D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Botón Continuar con lógica de 3 vías
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          final selectedMood = _moods[_selectedIndex!];

                          if (selectedMood.subtitle == 'Mal') {
                            // 1. ESTADO "MAL": Desahogo, Respiración o Chat
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SupportOptionsSheet(
                                apiKey: widget.apiKey,
                                onOpenSettings: () {
                                  Navigator.pop(context);
                                  widget.onNavigate?.call(ViewState.settings);
                                },
                                onStartVenting: () {
                                  Navigator.pop(context);
                                  widget.onNavigate?.call(ViewState.chat);
                                },
                                onStartBreathing: () {
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const CalmSpaceSheet(startWithBreathing: true),
                                  );
                                },
                                onStartCalmSpace: () {
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const CalmSpaceSheet(startWithBreathing: false),
                                  );
                                },
                              ),
                            );
                          } else if (selectedMood.subtitle == 'Regular') {
                            // 2. ESTADO "MÁS O MENOS": Abrir directamente pausa de calma
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const CalmSpaceSheet(startWithBreathing: true),
                            );
                          } else {
                            // 3. ESTADO "BIEN": Celebración suave / Paz Interior
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => PositiveOptionsSheet(
                                moodSubtitle: 'Bien',
                                onGoToAffirmations: () {
                                  Navigator.pop(context);
                                  widget.onNavigate?.call(ViewState.home);
                                },
                                onTalkToAlma: () {
                                  Navigator.pop(context);
                                  widget.onNavigate?.call(ViewState.chat);
                                },
                                onFinish: () {
                                  Navigator.pop(context);
                                  widget.onNavigate?.call(ViewState.home);
                                },
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue ? const Color(0xFF6C5CE7) : const Color(0xFF1A182E),
                    disabledBackgroundColor: const Color(0xFF18152B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: canContinue ? Colors.white : const Color(0xFF3F3B59),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: canContinue ? Colors.white : const Color(0xFF3F3B59),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}