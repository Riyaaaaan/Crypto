import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message);
}

class ApiService {
  // Backend API base URL - update this to match your backend server
  static const String _baseUrl = "http://localhost:8000/api/v1";

  // --- PUBLIC METHODS ---

  /// Fetches the conversion rate between two currencies.
  ///
  /// Throws [ApiException] or [RateLimitException] for network errors or unsupported pairs.
  static Future<double> getConversionRate(String from, String to) async {
    if (from == to) return 1.0;

    try {
      final url = Uri.parse("$_baseUrl/rate/$from/$to");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // FastAPI returns a float as JSON number, which decodes to double in Dart
        if (data is double) {
          return data;
        } else if (data is int) {
          return data.toDouble();
        }
        throw ApiException("Invalid response format from server.");
      } else {
        return _handleErrorResponse(response);
      }
    } on SocketException {
      throw ApiException("Network unavailable. Please check your connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Please try again.");
    } on http.ClientException catch (e) {
      throw ApiException("Network error: ${e.message}");
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Failed to get conversion rate: ${e.toString()}");
    }
  }

  /// Fetches top coins market data.
  static Future<List<dynamic>> getMarketData() async {
    final url = Uri.parse("$_baseUrl/market-data");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
    } catch (e) {
      // For this method, we can return an empty list on failure
      // as it's not as critical as the conversion.
    }
    return [];
  }

  // --- PRIVATE HELPERS ---

  /// Handles HTTP error response and throws appropriate exception.
  static double _handleErrorResponse(http.Response response) {
    if (response.statusCode == 429) {
      throw RateLimitException("Rate limit exceeded. Please try again later.");
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? errorData['message'] ?? "Unknown error";
        throw ApiException("Failed to fetch data: $errorMessage");
      } catch (e) {
        throw ApiException("Failed to fetch data (Error ${response.statusCode}).");
      }
    }
  }
}
