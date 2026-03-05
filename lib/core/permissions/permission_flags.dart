class PermissionFlags {
  const PermissionFlags({
    this.select = false,
    this.read = false,
    this.write = false,
    this.create = false,
    this.delete = false,
    this.report = false,
    this.print = false,
    this.email = false,
    this.export = false,
    this.importData = false,
    this.share = false,
  });

  static const PermissionFlags none = PermissionFlags();
  static const PermissionFlags full = PermissionFlags(
    select: true,
    read: true,
    write: true,
    create: true,
    delete: true,
    report: true,
    print: true,
    email: true,
    export: true,
    importData: true,
    share: true,
  );

  final bool select;
  final bool read;
  final bool write;
  final bool create;
  final bool delete;
  final bool report;
  final bool print;
  final bool email;
  final bool export;
  final bool importData;
  final bool share;

  PermissionFlags merge(PermissionFlags other) {
    return PermissionFlags(
      select: select || other.select,
      read: read || other.read,
      write: write || other.write,
      create: create || other.create,
      delete: delete || other.delete,
      report: report || other.report,
      print: print || other.print,
      email: email || other.email,
      export: export || other.export,
      importData: importData || other.importData,
      share: share || other.share,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'select': select,
      'read': read,
      'write': write,
      'create': create,
      'delete': delete,
      'report': report,
      'print': print,
      'email': email,
      'export': export,
      'import': importData,
      'share': share,
    };
  }

  factory PermissionFlags.fromJson(Map<String, dynamic> json) {
    return PermissionFlags(
      select: _toBool(json['select']),
      read: _toBool(json['read']),
      write: _toBool(json['write']),
      create: _toBool(json['create']),
      delete: _toBool(json['delete']),
      report: _toBool(json['report']),
      print: _toBool(json['print']),
      email: _toBool(json['email']),
      export: _toBool(json['export']),
      importData: _toBool(json['import']),
      share: _toBool(json['share']),
    );
  }

  factory PermissionFlags.fromDocPermRow(Map<String, dynamic> row) {
    return PermissionFlags(
      select: _toBool(row['select']),
      read: _toBool(row['read']),
      write: _toBool(row['write']),
      create: _toBool(row['create']),
      delete: _toBool(row['delete']),
      report: _toBool(row['report']),
      print: _toBool(row['print']),
      email: _toBool(row['email']),
      export: _toBool(row['export']),
      importData: _toBool(row['import']),
      share: _toBool(row['share']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }
}
