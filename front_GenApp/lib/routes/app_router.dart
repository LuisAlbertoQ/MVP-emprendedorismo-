import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front_genapp/ui/core/constants.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';
import 'package:front_genapp/ui/features/auth/views/login_screen.dart';
import 'package:front_genapp/ui/features/auth/views/register_screen.dart';
import 'package:front_genapp/ui/features/home/views/home_shell.dart';
import 'package:front_genapp/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:front_genapp/ui/features/animales/views/animal_list_screen.dart';
import 'package:front_genapp/ui/features/animales/views/animal_detail_screen.dart';
import 'package:front_genapp/ui/features/animales/views/animal_form_screen.dart';
import 'package:front_genapp/ui/features/animales/views/arbol_screen.dart';
import 'package:front_genapp/ui/features/reportes/views/reportes_screen.dart';
import 'package:front_genapp/ui/features/perfil/views/perfil_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final location = state.uri.toString();
      final isAuthRoute = location.startsWith('/auth');
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/animales',
            builder: (_, __) => const AnimalListScreen(),
            routes: [
              GoRoute(
                path: 'crear',
                builder: (_, __) => const AnimalFormScreen(),
              ),
              GoRoute(
                path: ':uid',
                builder: (_, state) => AnimalDetailScreen(
                  uid: state.pathParameters['uid']!,
                ),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, state) => AnimalFormScreen(
                      uid: state.pathParameters['uid']!,
                    ),
                  ),
                  GoRoute(
                    path: 'arbol',
                    builder: (_, state) => ArbolScreen(
                      uid: state.pathParameters['uid']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/reportes',
            builder: (_, __) => const ReportesScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (_, __) => const PerfilScreen(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (_, __) {
    goRouter.refresh();
  });

  return goRouter;
});
