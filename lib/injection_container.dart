import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/home/data/datasources/course_remote_datasource.dart';
import 'features/home/data/datasources/category_remote_datasource.dart';
import 'features/home/data/datasources/test_remote_datasource.dart';
import 'features/home/data/datasources/banner_remote_datasource.dart';
import 'features/home/data/datasources/notification_remote_datasource.dart';
import 'features/home/data/datasources/teacher_remote_datasource.dart';
import 'features/home/data/datasources/payment_remote_datasource.dart';
import 'features/home/data/datasources/saved_courses_local_datasource.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Core
  getIt.registerLazySingleton<DioClient>(() => DioClient(sharedPreferences));

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<TestRemoteDataSource>(
    () => TestRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSource(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<BannerRemoteDataSource>(
    () => BannerRemoteDataSource(),
  );
  getIt.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(),
  );
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<SavedCoursesLocalDataSource>(
    () => SavedCoursesLocalDataSource(getIt<SharedPreferences>()),
  );
}
