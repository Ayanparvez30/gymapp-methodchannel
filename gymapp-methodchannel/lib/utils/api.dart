import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';

enum HttpMethod { get, post, put, delete }

class BaseModel {
  BaseModel({this.message = '', this.data, this.statusCode = 0});
  String message;
  dynamic data;
  int statusCode;
}

class ApiService {
  final Dio dio;

  // Singleton
  ApiService._internal({required this.dio});
  static final ApiService _instance = ApiService._internal(dio: Dio());
  factory ApiService() => _instance;

  static const String baseUrl = 'http://192.168.10.29:8000/';
  static String token = '';

  /// Token save function
  void setToken(String newToken) {
    token = newToken;
    log('Token saved: $token');
  }

  /// Authorization header getter
  Options get authOptions => Options(
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

  /// Core request function
  Future<BaseModel> _makeRequest(
    String url,
    dynamic data,
    HttpMethod method, {
    String contentType = 'application/json',
    bool useAuth = true,
  }) async {
    try {
      log("API URL: $url");
      log("Request Data: $data");

      final headers = {
        'Content-Type': contentType,
        if (useAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      Response response;

      switch (method) {
        case HttpMethod.get:
          response = await dio.get(url,
              queryParameters: data, options: Options(headers: headers));
          break;
        case HttpMethod.post:
          response = await dio.post(url, data: data, options: Options(headers: headers));
          break;
        case HttpMethod.put:
          response = await dio.put(url, data: data, options: Options(headers: headers));
          break;
        case HttpMethod.delete:
          response = await dio.delete(url,
              queryParameters: data, options: Options(headers: headers));
          break;
      }

      log("Response Code: ${response.statusCode}");
      log("Response Body: ${response.data}");

      return BaseModel(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        message: response.statusMessage ?? '',
      );
    } on DioException catch (e) {
      log("DioException: ${e.message}");
      log("StackTrace: ${e.stackTrace}");

      if (e.error is SocketException) {
        return BaseModel(message: 'No Internet Connection', statusCode: 0);
      }
      return BaseModel(message: e.message ?? 'Unknown DioException', statusCode: 0);
    } catch (err) {
      log("Error: $err");
      if (err is SocketException) {
        return BaseModel(message: 'No Internet Connection', statusCode: 0);
      }
      return BaseModel(message: err.toString(), statusCode: 0);
    }
  }

  /// GET request
  Future<BaseModel> makeGetRequest(String endpoint,
      {Map<String, dynamic>? queryParameters, bool useAuth = true}) async {
    final safeUrl = baseUrl + endpoint;
    return _makeRequest(
      safeUrl,
      queryParameters ?? {},
      HttpMethod.get,
      useAuth: useAuth,
    );
  }

  /// POST request with JSON
  Future<BaseModel> makePostRequest(String endpoint, Map<String, dynamic> data,
      {bool useAuth = true}) async {
    final safeUrl = baseUrl + endpoint;
    return _makeRequest(
      safeUrl,
      data,
      HttpMethod.post,
      useAuth: useAuth,
      contentType: 'application/json',
    );
  }

  /// POST request with FormData (x-www-form-urlencoded or multipart)
  Future<BaseModel> makePostRequestWithFormData(String endpoint, FormData data,
      {bool useAuth = true}) async {
    final safeUrl = baseUrl + endpoint;
    return _makeRequest(
      safeUrl,
      data,
      HttpMethod.post,
      useAuth: useAuth,
      contentType: 'multipart/form-data',
    );
  }

  /// PUT request
  Future<BaseModel> makePutRequest(String endpoint, Map<String, dynamic> data,
      {bool useAuth = true}) async {
    final safeUrl = baseUrl + endpoint;
    return _makeRequest(
      safeUrl,
      data,
      HttpMethod.put,
      useAuth: useAuth,
    );
  }

  /// DELETE request
  Future<BaseModel> makeDeleteRequest(String endpoint,
      {Map<String, dynamic>? queryParameters, bool useAuth = true}) async {
    final safeUrl = baseUrl + endpoint;
    return _makeRequest(
      safeUrl,
      queryParameters ?? {},
      HttpMethod.delete,
      useAuth: useAuth,
    );
  }
}
