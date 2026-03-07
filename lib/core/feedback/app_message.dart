import 'package:flutter/material.dart';

enum AppMessageType { success, error, info }

@immutable
class AppMessage {
  const AppMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.sticky,
    required this.duration,
  });

  final String id;
  final String message;
  final AppMessageType type;
  final bool sticky;
  final Duration duration;
}
