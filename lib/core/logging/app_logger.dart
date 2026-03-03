import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

final appLoggerProvider = Provider<Talker>((ref) {
  return TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: true,
      enabled: true,
      maxHistoryItems: 500,
    ),
  );
});
