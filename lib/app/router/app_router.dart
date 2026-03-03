import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/auth_gate_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/items/presentation/pages/item_detail_page.dart';
import '../../features/items/presentation/pages/item_form_page.dart';
import '../../features/items/presentation/pages/item_list_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/users/presentation/pages/user_form_page.dart';
import '../../features/users/presentation/pages/user_list_page.dart';
import '../../core/storage/secure_storage_service.dart';

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((
  Ref ref,
) {
  final RouterRefreshNotifier notifier = RouterRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (
    AuthState? previous,
    AuthState next,
  ) {
    notifier.notify();
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final RouterRefreshNotifier refreshNotifier = ref.watch(
    routerRefreshNotifierProvider,
  );
  const String authGatePath = '/auth-gate';
  const String loginPath = '/login';
  const String itemsPath = '/items';
  const String usersPath = '/users';

  return GoRouter(
    initialLocation: authGatePath,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) async {
      final AuthState authState = ref.read(authControllerProvider);
      final SecureStorageService secureStorageService = ref.read(
        secureStorageServiceProvider,
      );
      final String location = state.matchedLocation;
      final bool goingLogin = location == loginPath;
      final bool goingAuthGate = location == authGatePath;

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return goingAuthGate ? null : authGatePath;
      }

      final bool authenticated = authState.status == AuthStatus.authenticated;
      if (authenticated) {
        final session = await secureStorageService.getSession();
        if (session == null) {
          ref.read(authControllerProvider.notifier).setUnauthenticated();
          return goingLogin ? null : loginPath;
        }
        return (goingLogin || goingAuthGate) ? itemsPath : null;
      }

      return goingLogin ? null : loginPath;
    },
    routes: <RouteBase>[
      GoRoute(
        path: authGatePath,
        builder: (BuildContext context, GoRouterState state) =>
            const AuthGatePage(),
      ),
      GoRoute(
        path: loginPath,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShellPage(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/items',
            builder: (BuildContext context, GoRouterState state) =>
                const ItemListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const ItemFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id']!;
                  return ItemDetailPage(itemId: id);
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id']!;
                      return ItemFormPage(itemId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: usersPath,
            builder: (BuildContext context, GoRouterState state) =>
                const UserListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const UserFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id'] ?? '';
                  return UserDetailPage(userId: Uri.decodeComponent(id));
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id'] ?? '';
                      return UserFormPage(userId: Uri.decodeComponent(id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
