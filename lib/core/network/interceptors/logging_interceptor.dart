import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._talker);

  final Talker _talker;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Map<String, dynamic> headers = Map<String, dynamic>.from(
      options.headers,
    );
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'token ***:***';
    }
    _talker.debug(
      'REQUEST ${options.method} ${options.uri} headers=$headers query=${options.queryParameters}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _talker.info(
      'RESPONSE ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _talker.error(
      'NETWORK ERROR ${err.response?.statusCode} ${err.requestOptions.uri}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }
}
