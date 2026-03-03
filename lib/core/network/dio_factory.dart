import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class DioFactory {
  DioFactory(this._talker);

  final Talker _talker;

  Dio create({
    required String baseUrl,
    Map<String, String>? headers,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: <String, String>{
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      LoggingInterceptor(_talker),
      RetryInterceptor(dio),
      ErrorInterceptor(),
    ]);

    return dio;
  }
}
