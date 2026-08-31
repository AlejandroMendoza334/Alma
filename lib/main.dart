import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mind_flow/features/affirmations/data/repositories/affirmation_repository_impl.dart';
import 'package:mind_flow/features/affirmations/domain/usecases/get_daily_affirmation.dart';
import 'package:mind_flow/features/notifications/domain/repositories/notification_repository_impl.dart';
import 'package:mind_flow/features/notifications/domain/usecases/schedule_daily_notification.dart';
import 'features/affirmations/data/models/models.dart';
import 'services/theme.dart';
import 'views/home_view.dart';
import 'views/mood_view.dart';
import 'views/chat_view.dart';
import 'views/settings_view.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final NotificationRepositoryImpl notificationRepository =
    NotificationRepositoryImpl(
  flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga la base de datos de zonas horarias y fija la del dispositivo.
  // Sin setLocalLocation(), tz.local queda en UTC y zonedSchedule agenda
  // las notificaciones a la hora equivocada de forma silenciosa.
  tz.initializeTimeZones();
  try {
    final TimezoneInfo deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone.identifier));
  } catch (e) {
    debugPrint('[Notifications] No se pudo obtener la zona horaria del dispositivo: $e');
  }

  // Inicializa el plugin y solicita el permiso de notificaciones (Android 13+)
  // en el orden correcto, una sola vez, aquí al arrancar la app.
  await notificationRepository.init();
  await notificationRepository.requestPermission();

  runApp(const AlmaApp());
}

class AlmaApp extends StatefulWidget {
  const AlmaApp({super.key});

  @override
  State<AlmaApp> createState() => _AlmaAppState();
}

class _AlmaAppState extends State<AlmaApp> {
  ViewState _currentView = ViewState.home;
  ProviderAI _selectedProvider = ProviderAI.gemini;
  String _apiKey = '';

  // Lista de afirmaciones iniciada vacía y cargada dinámicamente
  List<Affirmation> _affirmations = [];
  late Affirmation _dailyAffirmation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Afirmación por defecto mientras carga el JSON
    _dailyAffirmation = Affirmation(
      id: 0,
      text: "Cargando afirmación del día...",
      category: "Inicio",
    );
    _loadAffirmationsFromJson();
    _loadSavedSettings();
  }

  // La API key y el proveedor se guardaban en SharedPreferences al tocar
  // Guardar, pero nunca se volvían a leer al abrir la app — por eso todo
  // parecía "reiniciarse" al matar y reabrir la app, aunque seguía
  // guardado en el dispositivo.
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApiKey = prefs.getString('api_key') ?? '';
    final savedProvider = prefs.getString('selected_provider');
    if (!mounted) return;
    setState(() {
      // _apiKey se asigna primero y fuera de cualquier código que pueda
      // lanzar una excepción (como el parseo del provider) — si esto
      // llegara a fallar, no debe poder tumbarse la restauración de la key.
      _apiKey = savedApiKey;
      if (savedProvider != null) {
        try {
          _selectedProvider = ProviderAI.values.byName(savedProvider);
        } catch (e) {
          debugPrint('[Settings] Proveedor guardado inválido ("$savedProvider"): $e');
        }
      }
    });
  }

  Future<void> _loadAffirmationsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/afirmaciones.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      setState(() {
        _affirmations = jsonList.map((item) {
          return Affirmation(
            id: item['id'] as int,
            text: item['text'] as String,
            category: item['category'] as String,
          );
        }).toList();

        if (_affirmations.isNotEmpty) {
          _affirmations.shuffle();
          _dailyAffirmation = _affirmations.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar afirmaciones: $e');
      setState(() => _isLoading = false);
    }
  }

  void _loadRandomAffirmation() {
    if (_affirmations.isEmpty) return;
    setState(() {
      _dailyAffirmation = (_affirmations..shuffle()).first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AlmaTheme.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AlmaTheme.primary,
    brightness: Brightness.dark,
    background: AlmaTheme.background,
    surface: AlmaTheme.card,
  ),
),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: AlmaTheme.card,
          elevation: 0,
          title: const Row(
            children: [
              Text('🌙', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Alma', style: TextStyle(fontFamily: 'Lora', color: Colors.white)),
            ],
          ),
          actions: [
            if (_currentView != ViewState.settings)
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: AlmaTheme.primary),
        onPressed: () => setState(() => _currentView = ViewState.settings),
      ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AlmaTheme.primary))
            : _buildCurrentBody(),
        bottomNavigationBar: BottomNavigationBar(
  backgroundColor: AlmaTheme.card,
  selectedItemColor: AlmaTheme.primary,
  unselectedItemColor: AlmaTheme.mutedForeground,
  currentIndex: _getBottomIndex(),
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  unselectedLabelStyle: const TextStyle(fontSize: 12),
  onTap: (index) {
    setState(() {
      if (index == 0) _currentView = ViewState.home;
      if (index == 1) _currentView = ViewState.mood;
      if (index == 2) _currentView = ViewState.chat;
    });
  },
  items: const [
    BottomNavigationBarItem(
      icon: Text('🏠', style: TextStyle(fontSize: 18)),
      label: 'Inicio',
    ),
    BottomNavigationBarItem(
      icon: Text('🌸', style: TextStyle(fontSize: 18)),
      label: 'Estado',
    ),
    BottomNavigationBarItem(
      icon: Text('💬', style: TextStyle(fontSize: 18)),
      label: 'Alma',
    ),
  ],
),
      ),
    );
  }

  int _getBottomIndex() {
    switch (_currentView) {
      case ViewState.home: return 0;
      case ViewState.mood: return 1;
      case ViewState.chat: return 2;
      default: return 0;
    }
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case ViewState.home:
        return HomeView(
          dailyAffirmation: _dailyAffirmation,
          onRefreshAffirmation: _loadRandomAffirmation,
          provider: _selectedProvider,
          hasApiKey: _apiKey.isNotEmpty,
          onNavigate: (view) => setState(() => _currentView = view),
          affirmationsList: _affirmations,
        );
      case ViewState.mood:
        return MoodSelectionView(
          apiKey: _apiKey, 
          onBack: () => setState(() => _currentView = ViewState.home),
          onNavigate: (view) => setState(() => _currentView = view), 
          onStateSelected: (_) => setState(() => _currentView = ViewState.chat),
        );
      case ViewState.chat:
        return ChatView(
          provider: _selectedProvider,
          apiKey: _apiKey,
          onNavigate: (view) => setState(() => _currentView = view),
        );
      case ViewState.settings:
  return SettingsView(
    selectedProvider: _selectedProvider,
    apiKey: _apiKey,
    onProviderChanged: (p) => setState(() => _selectedProvider = p),
    onApiKeyChanged: (k) => setState(() => _apiKey = k),
    onBack: () => setState(() => _currentView = ViewState.home),
    scheduleDailyNotification: ScheduleDailyNotification(
  // Reutiliza el repositorio ya inicializado en main(); crear aquí una
  // instancia nueva de FlutterLocalNotificationsPlugin dejaba el plugin
  // sin initialize() y sin el permiso de Android 13+ solicitado.
  notificationRepository: notificationRepository,
  getDailyAffirmation: GetDailyAffirmation(
    AffirmationRepositoryImpl(),
  ),
),
    notificationRepository: notificationRepository,
  );
    }
  }
}