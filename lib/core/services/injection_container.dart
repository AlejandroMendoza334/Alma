import 'package:get_it/get_it.dart';

// Affirmations Imports
import '../../features/affirmations/data/repositories/affirmation_repository_impl.dart';
import '../../features/affirmations/domain/repositories/affirmation_repository.dart';
import '../../features/affirmations/domain/usecases/get_daily_affirmation.dart';
import '../../features/affirmations/domain/usecases/get_affirmations_by_category.dart';
import '../../features/affirmations/presentation/providers/affirmation_provider.dart';

// Notifications Imports
import '../../features/notifications/domain/usecases/schedule_daily_notification.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. Repositorios
  sl.registerLazySingleton<AffirmationRepository>(
    () => AffirmationRepositoryImpl(),
  );

  // 2. Casos de Uso
  sl.registerLazySingleton(
    () => GetDailyAffirmation(sl<AffirmationRepository>()),
  );

  sl.registerLazySingleton(
    () => GetAffirmationsByCategory(sl<AffirmationRepository>()),
  );

  sl.registerLazySingleton(
    () => ScheduleDailyNotification(
      notificationRepository: sl(),
      getDailyAffirmation: sl(),
    ),
  );

  // 3. Presentation / Providers (ESTE ES EL QUE FALTABA)
  sl.registerFactory(
    () => AffirmationProvider(
      getDailyAffirmation: sl(),
      getAffirmationsByCategory: sl(),
    ),
  );
}