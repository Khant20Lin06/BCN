import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../../core/permissions/permission_flags.dart';
import '../../domain/entities/session_entity.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';

class RolePermissionsPage extends ConsumerWidget {
  const RolePermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);
    final session = authState.session;

    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<String> roles = session.roles;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Role Permissions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            children: <Widget>[
              Text(
                'Logged-in Roles',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (roles.isEmpty)
                Text(
                  'No explicit roles returned by server.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles
                      .map((String role) => Chip(label: Text(role)))
                      .toList(growable: false),
                ),
              const SizedBox(height: 16),
              Text(
                'Effective Module Permissions',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _PermissionsTable(session: session),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionsTable extends StatelessWidget {
  const _PermissionsTable({required this.session});

  final SessionEntity session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 58,
        columns: const <DataColumn>[
          DataColumn(label: Text('Document Type')),
          DataColumn(label: Text('Read')),
          DataColumn(label: Text('Create')),
          DataColumn(label: Text('Write')),
          DataColumn(label: Text('Delete')),
          DataColumn(label: Text('Report')),
          DataColumn(label: Text('Print')),
          DataColumn(label: Text('Export')),
          DataColumn(label: Text('Import')),
          DataColumn(label: Text('Share')),
        ],
        rows: <DataRow>[
          _rowForModule(session, AppModule.items),
          _rowForModule(session, AppModule.customers),
          _rowForModule(session, AppModule.salesInvoices),
          _rowForModule(session, AppModule.itemPrices),
          _rowForModule(session, AppModule.stockBalances),
          _rowForModule(session, AppModule.profile),
        ],
      ),
    );
  }

  DataRow _rowForModule(SessionEntity session, AppModule module) {
    final PermissionFlags p = AppPermissionResolver.permissionForModule(
      session,
      module,
    );
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(module.label)),
        DataCell(_PermissionIcon(enabled: p.read || p.select)),
        DataCell(_PermissionIcon(enabled: p.create)),
        DataCell(_PermissionIcon(enabled: p.write)),
        DataCell(_PermissionIcon(enabled: p.delete)),
        DataCell(_PermissionIcon(enabled: p.report)),
        DataCell(_PermissionIcon(enabled: p.print)),
        DataCell(_PermissionIcon(enabled: p.export)),
        DataCell(_PermissionIcon(enabled: p.importData)),
        DataCell(_PermissionIcon(enabled: p.share)),
      ],
    );
  }
}

class _PermissionIcon extends StatelessWidget {
  const _PermissionIcon({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color = enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Icon(
      enabled ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
      size: 18,
      color: color,
    );
  }
}
