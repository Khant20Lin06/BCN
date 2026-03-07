import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/auth_gate_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/server_setup_page.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../core/permissions/app_permission_resolver.dart';
import '../../features/items/presentation/pages/item_detail_page.dart';
import '../../features/items/presentation/pages/item_form_page.dart';
import '../../features/items/presentation/pages/item_list_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/shell/presentation/pages/reports_page.dart';
import '../../features/shell/presentation/pages/theme_customization_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/customer_form_page.dart';
import '../../features/customers/presentation/pages/customer_list_page.dart';
import '../../features/sales_invoices/presentation/pages/sales_invoice_detail_page.dart';
import '../../features/sales_invoices/presentation/pages/sales_invoice_form_page.dart';
import '../../features/sales_invoices/presentation/pages/sales_invoice_list_page.dart';
import '../../features/item_prices/presentation/pages/item_price_detail_page.dart';
import '../../features/item_prices/presentation/pages/item_price_form_page.dart';
import '../../features/item_prices/presentation/pages/item_price_list_page.dart';
import '../../features/stock_balances/presentation/pages/stock_balance_detail_page.dart';
import '../../features/stock_balances/presentation/pages/stock_balance_form_page.dart';
import '../../features/stock_balances/presentation/pages/stock_balance_list_page.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/users/presentation/pages/user_form_page.dart';
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
  const String setupPath = '/setup';
  const String loginPath = '/login';
  const String forgotPasswordPath = '/forgot-password';
  const String itemsPath = '/items';
  const String profilePath = '/profile';
  const String customersPath = '/customers';
  const String salesInvoicesPath = '/sales-invoices';
  const String itemPricesPath = '/item-prices';
  const String stockBalancesPath = '/stock-balances';
  const String reportsPath = '/reports';

  return GoRouter(
    initialLocation: authGatePath,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) async {
      final AuthState authState = ref.read(authControllerProvider);
      final SecureStorageService secureStorageService = ref.read(
        secureStorageServiceProvider,
      );
      final String location = state.matchedLocation;
      final bool hasConfiguredBaseUrl =
          (await secureStorageService.getPreferredBaseUrl())?.isNotEmpty ??
          false;
      final bool goingSetup = location == setupPath;
      final bool goingLogin = location == loginPath;
      final bool goingForgotPassword = location == forgotPasswordPath;
      final bool goingAuthGate = location == authGatePath;

      if (!hasConfiguredBaseUrl) {
        return goingSetup ? null : setupPath;
      }

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return goingAuthGate ? null : authGatePath;
      }

      final bool authenticated = authState.status == AuthStatus.authenticated;
      if (authenticated) {
        final session =
            authState.session ?? await secureStorageService.getSession();
        if (session == null) {
          ref.read(authControllerProvider.notifier).setUnauthenticated(
            message: 'Session expired. Please log in again.',
          );
          return goingLogin ? null : loginPath;
        }

        if (goingLogin || goingSetup || goingAuthGate || goingForgotPassword) {
          return AppPermissionResolver.firstAllowedHome(session);
        }

        if (!AppPermissionResolver.canAccessLocation(session, location)) {
          return AppPermissionResolver.firstAllowedHome(session);
        }

        return null;
      }

      if (goingSetup) {
        return loginPath;
      }

      return (goingLogin || goingForgotPassword) ? null : loginPath;
    },
    routes: <RouteBase>[
      GoRoute(
        path: authGatePath,
        builder: (BuildContext context, GoRouterState state) =>
            const AuthGatePage(),
      ),
      GoRoute(
        path: setupPath,
        builder: (BuildContext context, GoRouterState state) =>
            const ServerSetupPage(),
      ),
      GoRoute(
        path: loginPath,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordPage(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShellPage(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: itemsPath,
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
            path: profilePath,
            builder: (BuildContext context, GoRouterState state) {
              final AuthState authState = ref.read(authControllerProvider);
              final String username = authState.session?.username.trim() ?? '';
              if (username.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return UserDetailPage(userId: username, isProfileMode: true);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (BuildContext context, GoRouterState state) {
                  final AuthState authState = ref.read(authControllerProvider);
                  final String username =
                      authState.session?.username.trim() ?? '';
                  if (username.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return UserFormPage(userId: username, isProfileMode: true);
                },
              ),
            ],
          ),
          GoRoute(
            path: customersPath,
            builder: (BuildContext context, GoRouterState state) =>
                const CustomerListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const CustomerFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id'] ?? '';
                  return CustomerDetailPage(
                    customerId: Uri.decodeComponent(id),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id'] ?? '';
                      return CustomerFormPage(
                        customerId: Uri.decodeComponent(id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: salesInvoicesPath,
            builder: (BuildContext context, GoRouterState state) =>
                const SalesInvoiceListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const SalesInvoiceFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id'] ?? '';
                  return SalesInvoiceDetailPage(
                    salesInvoiceId: Uri.decodeComponent(id),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id'] ?? '';
                      return SalesInvoiceFormPage(
                        salesInvoiceId: Uri.decodeComponent(id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: itemPricesPath,
            builder: (BuildContext context, GoRouterState state) =>
                const ItemPriceListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const ItemPriceFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id'] ?? '';
                  return ItemPriceDetailPage(
                    itemPriceId: Uri.decodeComponent(id),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id'] ?? '';
                      return ItemPriceFormPage(
                        itemPriceId: Uri.decodeComponent(id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: stockBalancesPath,
            builder: (BuildContext context, GoRouterState state) =>
                const StockBalanceListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const StockBalanceFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['id'] ?? '';
                  return StockBalanceDetailPage(
                    stockBalanceId: Uri.decodeComponent(id),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['id'] ?? '';
                      return StockBalanceFormPage(
                        stockBalanceId: Uri.decodeComponent(id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: reportsPath,
            builder: (BuildContext context, GoRouterState state) =>
                const ReportsPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'theme',
                builder: (BuildContext context, GoRouterState state) =>
                    const ThemeCustomizationPage(),
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
