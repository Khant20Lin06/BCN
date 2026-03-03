import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import 'frappe_api_client.dart';

class FrappeFileUploadService {
  const FrappeFileUploadService(this._apiClient);

  final FrappeApiClient _apiClient;

  Future<String> uploadImage({
    required String filePath,
    String? doctype,
    String? docname,
    String? fieldname,
    bool isPrivate = false,
  }) async {
    final Response<dynamic> response = await _postWithFallback(
      filePath: filePath,
      doctype: doctype,
      docname: docname,
      fieldname: fieldname,
      isPrivate: isPrivate,
    );
    final Map<String, dynamic> payload = _asMap(response.data);
    final String? fileUrl = _extractFileUrl(payload);
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      throw AppException(
        message: 'Upload succeeded but file URL is missing from response.',
      );
    }
    return fileUrl.trim();
  }

  Future<FormData> _buildFormData({
    required String filePath,
    required bool isPrivate,
    String? doctype,
    String? docname,
    String? fieldname,
  }) async {
    final String fileName = path.basename(filePath);
    return FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'is_private': isPrivate ? 1 : 0,
      if (doctype != null && doctype.trim().isNotEmpty) 'doctype': doctype,
      if (docname != null && docname.trim().isNotEmpty) 'docname': docname,
      if (fieldname != null && fieldname.trim().isNotEmpty)
        'fieldname': fieldname,
    });
  }

  Future<Response<dynamic>> _postWithFallback({
    required String filePath,
    required bool isPrivate,
    String? doctype,
    String? docname,
    String? fieldname,
  }) async {
    final FormData firstAttemptData = await _buildFormData(
      filePath: filePath,
      doctype: doctype,
      docname: docname,
      fieldname: fieldname,
      isPrivate: isPrivate,
    );

    try {
      return await _apiClient.postRaw(
        ApiConstants.uploadFilePath,
        data: firstAttemptData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }
    }

    // Some environments expose upload endpoint under /api/v2.
    final FormData secondAttemptData = await _buildFormData(
      filePath: filePath,
      doctype: doctype,
      docname: docname,
      fieldname: fieldname,
      isPrivate: isPrivate,
    );

    return _apiClient.postRaw(
      ApiConstants.uploadFileV2Path,
      data: secondAttemptData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw AppException(message: 'Invalid upload response format.');
  }

  String? _extractFileUrl(Map<String, dynamic> payload) {
    String? readUrl(Object? source) {
      if (source is! Map<String, dynamic>) {
        return null;
      }
      final Object? fileUrl = source['file_url'] ?? source['url'];
      if (fileUrl is String && fileUrl.trim().isNotEmpty) {
        return fileUrl;
      }
      return null;
    }

    final String? fromMessage = readUrl(payload['message']);
    if (fromMessage != null) {
      return fromMessage;
    }

    final String? fromData = readUrl(payload['data']);
    if (fromData != null) {
      return fromData;
    }

    final Object? rootFileUrl = payload['file_url'] ?? payload['url'];
    if (rootFileUrl is String && rootFileUrl.trim().isNotEmpty) {
      return rootFileUrl;
    }

    return null;
  }
}
