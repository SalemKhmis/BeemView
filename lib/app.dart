import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/dashboard/dashboard_cubit.dart';
import 'blocs/locale/locale_cubit.dart';
import 'blocs/profile/profile_cubit.dart';
import 'blocs/theme/theme_cubit.dart';
import 'blocs/projects/projects_cubit.dart';
import 'blocs/tasks/tasks_cubit.dart';
import 'blocs/task_detail/task_detail_cubit.dart';
import 'config/app_theme.dart';
import 'data/api/api_client.dart';
import 'data/api/auth_api.dart';
import 'data/api/project_api.dart';
import 'data/api/task_api.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/task_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

/// Root application widget.
///
/// Sets up dependency injection (repositories, API client),
/// provides Cubits via [MultiBlocProvider], and handles
/// auth-based routing (Login ↔ Projects).
class BeemViewApp extends StatefulWidget {
  const BeemViewApp({super.key});

  @override
  State<BeemViewApp> createState() => _BeemViewAppState();
}

class _BeemViewAppState extends State<BeemViewApp> {
  late final AuthRepository _authRepository;
  late final ProjectRepository _projectRepository;
  late final TaskRepository _taskRepository;
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  void _initDependencies() {
    // Create auth repository first (needed for token provider callback)
    // Use a late reference so the closure captures the final instance.
    late final AuthRepository authRepo;

    final apiClient = ApiClient(
      tokenProvider: () => authRepo.getToken(),
      onSessionExpired: _handleSessionExpired,
    );

    // Now create the actual repository with the authenticated Dio.
    // The AuthInterceptor skips the Bearer header when token is null,
    // so login requests (before we have a token) work correctly.
    authRepo = AuthRepository(authApi: AuthApi(apiClient.dio));
    _authRepository = authRepo;

    _projectRepository = ProjectRepository(
      projectApi: ProjectApi(apiClient.dio),
    );

    _taskRepository = TaskRepository(
      taskApi: TaskApi(apiClient.dio),
    );

    // Create auth cubit and attempt session restore
    _authCubit = AuthCubit(authRepository: _authRepository);
    _authCubit.restoreSession();
  }

  void _handleSessionExpired() {
    _authCubit.onSessionExpired();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>.value(
            value: _projectRepository),
        RepositoryProvider<TaskRepository>.value(value: _taskRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<ProjectsCubit>(
            create: (_) => ProjectsCubit(
              projectRepository: _projectRepository,
            ),
          ),
          BlocProvider<TasksCubit>(
            create: (_) => TasksCubit(
              taskRepository: _taskRepository,
            ),
          ),
          BlocProvider<TaskDetailCubit>(
            create: (_) => TaskDetailCubit(
              taskRepository: _taskRepository,
            ),
          ),
          BlocProvider<DashboardCubit>(
            create: (_) => DashboardCubit(
              projectRepository: _projectRepository,
              taskRepository: _taskRepository,
            ),
          ),
          BlocProvider<LocaleCubit>(
            create: (_) => LocaleCubit(),
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
          BlocProvider<ProfileCubit>(
            create: (_) => ProfileCubit(
              authRepository: _authRepository,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, currentLocale) {
                return MaterialApp(
                  title: 'BeemView',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: currentLocale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: BlocConsumer<AuthCubit, AuthState>(
                    listener: (context, state) {
                      if (state is AuthSessionExpired) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context).translate('session_expired'),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AuthRestoring) {
                        return const _SplashScreen();
                      }
                      if (state is AuthAuthenticated) {
                        return const MainNavigationScreen();
                      }
                      return const LoginScreen();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Splash screen shown while restoring a persisted session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E5A73), // Dark teal
              Color(0xFF1E96BE), // BeemView cyan
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFAAA3C).withValues(alpha: 0.4),
                      blurRadius: 35,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/beemview_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BeemView',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFFFAAA3C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
