import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/affirmations/data/models/models.dart';
import '../features/notifications/domain/usecases/schedule_daily_notification.dart';
import '../services/theme.dart';
import '../services/api_validation_service.dart';

class SettingsView extends StatefulWidget {
  final ProviderAI selectedProvider;
  final String apiKey;
  final Function(ProviderAI) onProviderChanged;
  final Function(String) onApiKeyChanged;
  final VoidCallback onBack;
  final ScheduleDailyNotification scheduleDailyNotification;

  const SettingsView({
    super.key,
    required this.selectedProvider,
    required this.apiKey,
    required this.onProviderChanged,
    required this.onApiKeyChanged,
    required this.onBack,
    required this.scheduleDailyNotification,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _apiKeyController;

  bool _isValidating = false;
  bool? _isKeyValid;
  bool _notificationsEnabled = true;
  String _notificationPermission = 'default';
  
  // Nuevas variables para múltiples frecuencias y horas
  int _frequency = 1; 
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _apiKeyController = TextEditingController(text: widget.apiKey);
    
    _apiKeyController.addListener(() {
      setState(() {});
    });

    _checkNotificationPermission();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('auto_affirmations') ?? true;
      _frequency = prefs.getInt('notif_frequency') ?? 1;

      // Cargamos las horas guardadas o rellenamos por defecto según la frecuencia
      _selectedTimes = List.generate(_frequency, (index) {
        final hour = prefs.getInt('notif_hour_$index') ?? (8 + (index * 6));
        final minute = prefs.getInt('notif_minute_$index') ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      });
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_affirmations', _notificationsEnabled);
    await prefs.setInt('notif_frequency', _frequency);
    
    // Guardamos cada hora de la lista de forma individual en SharedPreferences
    for (int i = 0; i < _selectedTimes.length; i++) {
      await prefs.setInt('notif_hour_$i', _selectedTimes[i].hour);
      await prefs.setInt('notif_minute_$i', _selectedTimes[i].minute);
    }

    await prefs.setString('api_key', _apiKeyController.text);
    widget.onApiKeyChanged(_apiKeyController.text);

    if (_notificationsEnabled) {
      // Llamamos al caso de uso pasando la lista completa de horarios
      await widget.scheduleDailyNotification.call(
        times: _selectedTimes,
      );
    }
  }

  void _updateFrequency(int newFrequency) {
    setState(() {
      _frequency = newFrequency;
      // Ajustamos el tamaño de la lista manteniendo las horas anteriores o rellenando con nuevas por defecto
      _selectedTimes = List.generate(_frequency, (index) {
        if (index < _selectedTimes.length) {
          return _selectedTimes[index];
        }
        int defaultHour = 8 + (index * 6);
        if (defaultHour > 23) defaultHour = 20;
        return TimeOfDay(hour: defaultHour, minute: 0);
      });
    });
  }

  void _checkNotificationPermission() {
    setState(() {
      _notificationPermission = 'granted';
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _notificationPermission = 'granted');
  }

  Future<void> _verifyApiKey() async {
    setState(() {
      _isValidating = true;
      _isKeyValid = null;
    });

    final isValid = await ApiValidationService.validateKey(
      widget.selectedProvider,
      _apiKeyController.text,
    );

    setState(() {
      _isValidating = false;
      _isKeyValid = isValid;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlmaTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: Text('Cancelar', style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 13)),
                  ),
                  Text('Ajustes', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(
                    onPressed: _apiKeyController.text.trim().isEmpty
                        ? null
                        : () async {
                            await _savePreferences();
                            widget.onBack();
                          },
                    child: Text(
                      'Guardar', 
                      style: GoogleFonts.nunito(
                        color: _apiKeyController.text.trim().isEmpty 
                            ? AlmaTheme.mutedForeground 
                            : AlmaTheme.primary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AlmaTheme.primary,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: AlmaTheme.mutedForeground,
              tabs: const [
                Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: 'IA'),
                Tab(icon: Icon(Icons.notifications_none_rounded, size: 18), text: 'Notificaciones'),
                Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Acerca de'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIATab(),
                  _buildNotifsTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIATab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('PROVEEDOR DE INTELIGENCIA ARTIFICIAL', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AlmaTheme.primary, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildProviderTile(ProviderAI.anthropic, 'Claude (Anthropic)', 'Recomendado para respuestas empáticas.', '🟠'),
        _buildProviderTile(ProviderAI.openai, 'ChatGPT (OpenAI)', 'Respuestas ágiles y precisas.', '⚪'),
        _buildProviderTile(ProviderAI.gemini, 'Gemini (Google)', 'Respuestas fluidas e integradas.', '🔵'),
        
        const SizedBox(height: 24),
        Text('LLAVE DE API (API KEY)', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AlmaTheme.primary, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text('Tu API Key se guarda localmente en tu dispositivo y nunca se comparte.', style: GoogleFonts.nunito(fontSize: 12, color: AlmaTheme.mutedForeground)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _apiKeyController,
                obscureText: true,
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Pega tu API Key aquí...',
                  hintStyle: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 13),
                  filled: true,
                  fillColor: AlmaTheme.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AlmaTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AlmaTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AlmaTheme.primary)),
                ),
                onChanged: (_) => setState(() => _isKeyValid = null),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isValidating ? null : _verifyApiKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AlmaTheme.card,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AlmaTheme.border),
                ),
              ),
              child: _isValidating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Probar', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        if (_isKeyValid != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isKeyValid! ? Icons.check_circle_outline : Icons.error_outline,
                color: _isKeyValid! ? Colors.greenAccent : Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isKeyValid! ? 'API Key válida y lista para usar.' : 'API Key inválida o sin conexión.',
                style: GoogleFonts.nunito(color: _isKeyValid! ? Colors.greenAccent : Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNotifsTab() {
    final bool isDenied = _notificationPermission == 'denied';
    final bool isGranted = _notificationPermission == 'granted';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Estado de Notificaciones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AlmaTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AlmaTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notificaciones del sistema', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDenied ? Colors.red.withOpacity(0.2) : (isGranted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDenied ? 'Bloqueadas' : (isGranted ? 'Activas' : 'Pendientes'),
                      style: GoogleFonts.nunito(
                        color: isDenied ? Colors.redAccent : (isGranted ? Colors.greenAccent : Colors.orangeAccent),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isDenied
                    ? 'Bloqueaste las notificaciones. Puedes cambiar esto en la configuración de tu dispositivo.'
                    : 'Permite que Alma te envíe mensajes de bienestar diariamente.',
                style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 12),
              ),
              if (!isGranted && !isDenied) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _requestNotificationPermission,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AlmaTheme.primary)),
                  child: Text('Permitir Notificaciones', style: GoogleFonts.nunito(color: AlmaTheme.primary, fontSize: 12)),
                )
              ]
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Switch Afirmaciones automáticas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AlmaTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AlmaTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Afirmaciones automáticas', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Recibe frases de bienestar diariamente', style: GoogleFonts.nunito(color: AlmaTheme.mutedForeground, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                activeColor: Colors.white,
                activeTrackColor: AlmaTheme.primary,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Selector de Frecuencia (1, 2 o 3 veces al día)
        Text('FRECUENCIA DIARIA', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AlmaTheme.mutedForeground, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AlmaTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AlmaTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Veces al día', style: GoogleFonts.nunito(color: Colors.white, fontSize: 14)),
              DropdownButton<int>(
                value: _frequency,
                dropdownColor: AlmaTheme.card,
                style: GoogleFonts.nunito(color: AlmaTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 vez al día')),
                  DropdownMenuItem(value: 2, child: Text('2 veces al día')),
                  DropdownMenuItem(value: 3, child: Text('3 veces al día')),
                ],
                onChanged: (val) {
                  if (val != null) _updateFrequency(val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Lista dinámica de selectores de hora
        Text('HORARIOS DE LAS NOTIFICACIONES', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AlmaTheme.mutedForeground, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        
        ...List.generate(_selectedTimes.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTimes[index],
                );
                if (picked != null) {
                  setState(() {
                    _selectedTimes[index] = picked;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AlmaTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AlmaTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AlmaTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text('Notificación ${index + 1}', style: GoogleFonts.nunito(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                    Text(
                      _selectedTimes[index].format(context),
                      style: GoogleFonts.nunito(color: AlmaTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AlmaTheme.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AlmaTheme.primary.withOpacity(0.4)),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/alma_icon.png', 
                    width: 80,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Alma', style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Versión 1.0.0', style: GoogleFonts.nunito(fontSize: 12, color: AlmaTheme.mutedForeground)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('INFORMACIÓN DEL DESARROLLADOR', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AlmaTheme.primary, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AlmaTheme.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AlmaTheme.border),
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // --- SECCIÓN 1: CREADOR ---
      Row(
        children: [
          const Icon(Icons.code_rounded, color: AlmaTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creado por', style: GoogleFonts.nunito(fontSize: 11, color: AlmaTheme.mutedForeground)),
                const SizedBox(height: 2),
                Text('Alejandro Mendoza', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: AlmaTheme.border, height: 1),
      ),

      // --- SECCIÓN 2: CONTACTO ---
      Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: AlmaTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contacto', style: GoogleFonts.nunito(fontSize: 11, color: AlmaTheme.mutedForeground)),
                const SizedBox(height: 2),
                Text(
                  'alejandromendoza6575757@gmail.com',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: AlmaTheme.border, height: 1),
      ),

      // --- SECCIÓN 3: INSTAGRAM ---
      Row(
        children: [
          const Icon(Icons.camera_alt_rounded, color: AlmaTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instagram', style: GoogleFonts.nunito(fontSize: 11, color: AlmaTheme.mutedForeground)),
                const SizedBox(height: 2),
                Text(
                  '@dewcrossward',
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),
      ],
    );
  }

 Widget _buildProviderTile(ProviderAI provider, String title, String subtitle, String emoji) {
    final isSelected = widget.selectedProvider == provider;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AlmaTheme.secondary : AlmaTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AlmaTheme.primary : AlmaTheme.border, width: isSelected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent, // Permite que conserve el color del Container
        borderRadius: BorderRadius.circular(16),
        child: RadioListTile<ProviderAI>(
          value: provider,
          groupValue: widget.selectedProvider,
          activeColor: AlmaTheme.primary,
          onChanged: (val) {
            if (val != null) {
              widget.onProviderChanged(val);
              setState(() => _isKeyValid = null);
            }
          },
          title: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ],
          ),
          subtitle: Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: AlmaTheme.mutedForeground)),
        ),
      ),
    );
  }
}