import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: StorageKeys.accessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
          
          if (refreshToken != null) {
            try {
              // Try to refresh the token
              final refreshResponse = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
                ApiConstants.authRefresh,
                data: {'refreshToken': refreshToken},
              );

              if (refreshResponse.statusCode == 200) {
                final newData = refreshResponse.data;
                final newAccessToken = newData['accessToken'];
                final newRefreshToken = newData['refreshToken'];

                await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
                await _storage.write(key: StorageKeys.refreshToken, value: newRefreshToken);

                // Retry the original request
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final retryResponse = await _dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              if (kDebugMode) print('Token refresh failed: $refreshError');
            }
          }
          
          // If refresh failed or no token, clear everything and fail
          await _storage.delete(key: StorageKeys.accessToken);
          await _storage.delete(key: StorageKeys.refreshToken);
        }

        return handler.next(e);
      },
    ));

    // Add logging interceptor only in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));
    }
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final body = response.data;
    
    // Most of our APIs return { "success": true, "data": ..., "message": ... }
    if (body is Map<String, dynamic>) {
      if (body['success'] == true || body['success'] == null) {
        final data = body['data'] ?? body;
        if (fromJson != null && data != null) {
          try {
            return ApiResponse.success(fromJson(data), body['message']);
          } catch (e) {
            return ApiResponse.error('Data parsing error: $e');
          }
        }
        return ApiResponse.success(data as T?, body['message']);
      }
      return ApiResponse.error(body['message'] ?? 'Unknown error');
    }

    // Direct data response
    if (fromJson != null && body != null) {
      try {
        return ApiResponse.success(fromJson(body));
      } catch (e) {
        return ApiResponse.error('Data parsing error: $e');
      }
    }
    
    return ApiResponse.success(body as T?);
  }

  ApiResponse<T> _handleDioError<T>(DioException e) {
    String message = 'An unexpected error occurred';
    List<String>? errors;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    } else if (e.response != null) {
      final body = e.response!.data;
      if (body is Map<String, dynamic>) {
        message = body['message'] ?? 'Server error: ${e.response!.statusCode}';
        if (body['errors'] != null) {
          errors = List<String>.from(body['errors']);
        }
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }
    }

    return ApiResponse.error(message, errors);
  }

  // Token management helper for legacy services if still needed
  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<String>? errors;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.success(T? data, [String? message]) {
    return ApiResponse._(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, [List<String>? errors]) {
    return ApiResponse._(success: false, message: message, errors: errors);
  }
}
