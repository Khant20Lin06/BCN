import '../../features/auth/domain/entities/session_entity.dart';
import 'permission_flags.dart';

enum AppModule {
  items,
  customers,
  salesInvoices,
  itemPrices,
  stockBalances,
  profile,
  rolePermissions,
}

extension AppModuleX on AppModule {
  String get key {
    switch (this) {
      case AppModule.items:
        return 'items';
      case AppModule.customers:
        return 'customers';
      case AppModule.salesInvoices:
        return 'sales_invoices';
      case AppModule.itemPrices:
        return 'item_prices';
      case AppModule.stockBalances:
        return 'stock_balances';
      case AppModule.profile:
        return 'profile';
      case AppModule.rolePermissions:
        return 'role_permissions';
    }
  }

  String get routePath {
    switch (this) {
      case AppModule.items:
        return '/items';
      case AppModule.customers:
        return '/customers';
      case AppModule.salesInvoices:
        return '/sales-invoices';
      case AppModule.itemPrices:
        return '/item-prices';
      case AppModule.stockBalances:
        return '/stock-balances';
      case AppModule.profile:
        return '/profile';
      case AppModule.rolePermissions:
        return '/role-permissions';
    }
  }

  String get label {
    switch (this) {
      case AppModule.items:
        return 'Items';
      case AppModule.customers:
        return 'Customers';
      case AppModule.salesInvoices:
        return 'Sales Invoice';
      case AppModule.itemPrices:
        return 'Item Price';
      case AppModule.stockBalances:
        return 'Stock Balance';
      case AppModule.profile:
        return 'Profile';
      case AppModule.rolePermissions:
        return 'Role Permissions';
    }
  }
}

enum PermissionAction { read, create, write, delete }

class AppPermissionResolver {
  const AppPermissionResolver._();

  static bool can(
    SessionEntity? session,
    AppModule module,
    PermissionAction action,
  ) {
    final PermissionFlags permission = permissionForModule(session, module);
    switch (action) {
      case PermissionAction.read:
        return permission.read || permission.select;
      case PermissionAction.create:
        return permission.create;
      case PermissionAction.write:
        return permission.write;
      case PermissionAction.delete:
        return permission.delete;
    }
  }

  static PermissionFlags permissionForModule(
    SessionEntity? session,
    AppModule module,
  ) {
    if (session == null) {
      return PermissionFlags.none;
    }

    final PermissionFlags? mapped = session.permissions[module.key];
    final PermissionFlags? fallback = _fallbackByRole(session.roles, module);
    if (module == AppModule.profile) {
      final PermissionFlags baseline = const PermissionFlags(read: true);
      PermissionFlags resolved = baseline;
      if (mapped != null) {
        resolved = resolved.merge(mapped);
      }
      if (fallback != null) {
        resolved = resolved.merge(fallback);
      }
      return resolved;
    }

    if (mapped != null) {
      if (fallback != null) {
        return mapped.merge(fallback);
      }
      return mapped;
    }

    return fallback ?? PermissionFlags.none;
  }

  static bool canAccessLocation(SessionEntity? session, String location) {
    final _RoutePermission? routePermission = _routePermissionForLocation(
      location,
    );
    if (routePermission == null) {
      return true;
    }
    return can(session, routePermission.module, routePermission.action);
  }

  static String firstAllowedHome(SessionEntity? session) {
    for (final AppModule module in <AppModule>[
      AppModule.items,
      AppModule.customers,
      AppModule.salesInvoices,
      AppModule.itemPrices,
      AppModule.stockBalances,
      AppModule.profile,
      AppModule.rolePermissions,
    ]) {
      if (can(session, module, PermissionAction.read)) {
        return module.routePath;
      }
    }
    return '/profile';
  }

  static bool isAdmin(SessionEntity? session) {
    if (session == null) {
      return false;
    }
    return session.roles.any(_isAdminRole);
  }

  static _RoutePermission? _routePermissionForLocation(String location) {
    if (location == '/items' || location.startsWith('/items/')) {
      if (location == '/items/new') {
        return const _RoutePermission(AppModule.items, PermissionAction.create);
      }
      if (location.contains('/edit')) {
        return const _RoutePermission(AppModule.items, PermissionAction.write);
      }
      return const _RoutePermission(AppModule.items, PermissionAction.read);
    }

    if (location == '/customers' || location.startsWith('/customers/')) {
      if (location == '/customers/new') {
        return const _RoutePermission(
          AppModule.customers,
          PermissionAction.create,
        );
      }
      if (location.contains('/edit')) {
        return const _RoutePermission(
          AppModule.customers,
          PermissionAction.write,
        );
      }
      return const _RoutePermission(AppModule.customers, PermissionAction.read);
    }

    if (location == '/sales-invoices' ||
        location.startsWith('/sales-invoices/')) {
      if (location == '/sales-invoices/new') {
        return const _RoutePermission(
          AppModule.salesInvoices,
          PermissionAction.create,
        );
      }
      if (location.contains('/edit')) {
        return const _RoutePermission(
          AppModule.salesInvoices,
          PermissionAction.write,
        );
      }
      return const _RoutePermission(
        AppModule.salesInvoices,
        PermissionAction.read,
      );
    }

    if (location == '/item-prices' || location.startsWith('/item-prices/')) {
      if (location == '/item-prices/new') {
        return const _RoutePermission(
          AppModule.itemPrices,
          PermissionAction.create,
        );
      }
      if (location.contains('/edit')) {
        return const _RoutePermission(
          AppModule.itemPrices,
          PermissionAction.write,
        );
      }
      return const _RoutePermission(
        AppModule.itemPrices,
        PermissionAction.read,
      );
    }

    if (location == '/stock-balances' ||
        location.startsWith('/stock-balances/')) {
      if (location == '/stock-balances/new') {
        return const _RoutePermission(
          AppModule.stockBalances,
          PermissionAction.create,
        );
      }
      if (location.contains('/edit')) {
        return const _RoutePermission(
          AppModule.stockBalances,
          PermissionAction.write,
        );
      }
      return const _RoutePermission(
        AppModule.stockBalances,
        PermissionAction.read,
      );
    }

    if (location == '/profile' || location.startsWith('/profile/')) {
      if (location.contains('/edit')) {
        return const _RoutePermission(
          AppModule.profile,
          PermissionAction.write,
        );
      }
      return const _RoutePermission(AppModule.profile, PermissionAction.read);
    }

    if (location == '/role-permissions' ||
        location.startsWith('/role-permissions')) {
      return const _RoutePermission(
        AppModule.rolePermissions,
        PermissionAction.read,
      );
    }

    return null;
  }

  static PermissionFlags? _fallbackByRole(
    List<String> roles,
    AppModule module,
  ) {
    if (roles.isEmpty) {
      return null;
    }

    final Set<String> normalizedRoles = roles
        .map((String role) => role.trim().toLowerCase())
        .where((String role) => role.isNotEmpty)
        .toSet();

    if (normalizedRoles.any(_isAdminRole)) {
      return PermissionFlags.full;
    }

    bool hasRoleContaining(String keyword) {
      return normalizedRoles.any((String role) => role.contains(keyword));
    }

    switch (module) {
      case AppModule.items:
        if (hasRoleContaining('stock')) {
          return const PermissionFlags(
            select: true,
            read: true,
            create: true,
            write: true,
            delete: true,
            report: true,
          );
        }
        if (hasRoleContaining('sales') || hasRoleContaining('accounts')) {
          return const PermissionFlags(select: true, read: true, report: true);
        }
        break;
      case AppModule.customers:
        if (hasRoleContaining('sales') || hasRoleContaining('accounts')) {
          final bool canManage =
              hasRoleContaining('manager') ||
              normalizedRoles.contains('sales user');
          return PermissionFlags(
            select: true,
            read: true,
            create: canManage,
            write: canManage,
            delete: hasRoleContaining('manager'),
            report: true,
            print: true,
            email: true,
            share: canManage,
          );
        }
        break;
      case AppModule.salesInvoices:
        if (hasRoleContaining('sales')) {
          final bool canManage =
              hasRoleContaining('manager') ||
              normalizedRoles.contains('sales user');
          return PermissionFlags(
            select: true,
            read: true,
            create: canManage,
            write: canManage,
            delete: hasRoleContaining('manager'),
            report: true,
            print: true,
            email: true,
            share: canManage,
          );
        }
        break;
      case AppModule.itemPrices:
        if (hasRoleContaining('sales') || hasRoleContaining('accounts')) {
          final bool canManage = hasRoleContaining('manager');
          return PermissionFlags(
            select: true,
            read: true,
            create: canManage,
            write: canManage,
            delete: canManage,
            report: true,
          );
        }
        break;
      case AppModule.stockBalances:
        if (hasRoleContaining('stock')) {
          final bool canManage = hasRoleContaining('manager');
          return PermissionFlags(
            select: true,
            read: true,
            create: canManage,
            write: canManage,
            delete: canManage,
            report: true,
          );
        }
        break;
      case AppModule.profile:
        return const PermissionFlags(read: true, write: true);
      case AppModule.rolePermissions:
        if (hasRoleContaining('manager')) {
          return const PermissionFlags(read: true);
        }
        break;
    }
    return null;
  }

  static bool _isAdminRole(String role) {
    final String normalized = role.trim().toLowerCase();
    return normalized == 'administrator' || normalized == 'system manager';
  }
}

class _RoutePermission {
  const _RoutePermission(this.module, this.action);

  final AppModule module;
  final PermissionAction action;
}
