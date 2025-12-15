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

class ApiService {
  static const String _baseUrl = "https://api.coingecko.com/api/v3";
  static const List<String> _fiatCurrencies = ["usd", "inr"];

  // --- PUBLIC METHODS ---

  /// Fetches the conversion rate between two currencies.
  ///
  /// Throws [ApiException] for network errors or unsupported pairs.
  static Future<double> getConversionRate(String from, String to) async {
    if (from == to) return 1.0;

    try {
      // Use USD as a common base for all conversions.
      final fromUsdRate = await _getUsdPrice(from);
      final toUsdRate = await _getUsdPrice(to);
      
      if (toUsdRate == 0) {
        throw ApiException("Rate for '$to' is zero, cannot divide.");
      }

      return fromUsdRate / toUsdRate;

    } on SocketException {
      throw ApiException("Network unavailable. Please check your connection.");
    } on TimeoutException {
       throw ApiException("Request timed out. Please try again.");
    } on http.ClientException catch (e) {
      throw ApiException("Network error: ${e.message}");
    }
  }

  /// Fetches top coins market data.
  static Future<List<dynamic>> getMarketData() async {
    final url = Uri.parse(
        "$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // For this method, we can return an empty list on failure
      // as it's not as critical as the conversion.
    }
    return [];
  }

  // --- PRIVATE HELPERS ---

  /// Gets the price of 1 unit of a given currency in USD.
  static Future<double> _getUsdPrice(String currency) async {
    if (currency == 'usd') {
      return 1.0;
    }

    if (_fiatCurrencies.contains(currency)) {
      // For other fiat currencies, get their rate relative to USD via a crypto (bitcoin).
      // e.g. (BTC -> USD) / (BTC -> INR) = INR -> USD
      final url = Uri.parse("$_baseUrl/simple/price?ids=bitcoin&vs_currencies=usd,$currency");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);

      final usdRate = data['bitcoin']?['usd']?.toDouble();
      final otherFiatRate = data['bitcoin']?[currency]?.toDouble();

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
  static const String _baseUrl = "https://api.coingecko.com/api/v3";
  static const List<String> _fiatCurrencies = ["usd", "inr"];

  // --- PUBLIC METHODS ---

  /// Fetches the conversion rate between two currencies.
  ///
  /// Throws [ApiException] or [RateLimitException] for network errors or unsupported pairs.
  static Future<double> getConversionRate(String from, String to) async {
    if (from == to) return 1.0;

    try {
      // Use USD as a common base for all conversions.
      final fromUsdRate = await _getUsdPrice(from);
      final toUsdRate = await _getUsdPrice(to);
      
      if (toUsdRate == 0) {
        throw ApiException("Rate for '$to' is zero, cannot divide.");
      }

      return fromUsdRate / toUsdRate;

    } on SocketException {
      throw ApiException("Network unavailable. Please check your connection.");
    } on TimeoutException {
       throw ApiException("Request timed out. Please try again.");
    } on http.ClientException catch (e) {
      throw ApiException("Network error: ${e.message}");
    }
  }

  /// Fetches top coins market data.
  static Future<List<dynamic>> getMarketData() async {
    final url = Uri.parse(
        "$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // For this method, we can return an empty list on failure
      // as it's not as critical as the conversion.
    }
    return [];
  }

  // --- PRIVATE HELPERS ---

  /// Gets the price of 1 unit of a given currency in USD.
  static Future<double> _getUsdPrice(String currency) async {
    if (currency == 'usd') {
      return 1.0;
    }

    if (_fiatCurrencies.contains(currency)) {
      // For other fiat currencies, get their rate relative to USD via a crypto (bitcoin).
      // e.g. (BTC -> USD) / (BTC -> INR) = INR -> USD
      final url = Uri.parse("$_baseUrl/simple/price?ids=bitcoin&vs_currencies=usd,$currency");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);

      final usdRate = data['bitcoin']?['usd']?.toDouble();
      final otherFiatRate = data['bitcoin']?[currency]?.toDouble();

      if (usdRate == null || otherFiatRate == null || otherFiatRate == 0) {
        throw ApiException("Rate for '$currency' is currently unavailable.");
      }
      return usdRate / otherFiatRate; // This gives how many USD 1 of the other fiat is.

    } else {
      // For crypto-currencies, get their price directly in USD.
      final url = Uri.parse("$_baseUrl/simple/price?ids=$currency&vs_currencies=usd");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);

      final rate = data[currency.toLowerCase()]?['usd']?.toDouble();

      if (rate == null) {
        throw ApiException("Pair not supported for '$currency'.");
      }
      return rate;
    }
  }

  /// Handles HTTP response, checking for errors and decoding JSON.
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null || (data is Map && data.isEmpty)) {
        throw ApiException("Rate temporarily unavailable (empty response).");
      }
      return data;
    } else if (response.statusCode == 429) {
      throw RateLimitException("Rate limit exceeded. Please try again later.");
    } else {
      throw ApiException("Failed to fetch data (Error ${response.statusCode}).");
    }
  }
}
      return usdRate / otherFiatRate; // This gives how many USD 1 of the other fiat is.

    } else {
      // For crypto-currencies, get their price directly in USD.
      final url = Uri.parse("$_baseUrl/simple/price?ids=$currency&vs_currencies=usd");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);

      final rate = data[currency.toLowerCase()]?['usd']?.toDouble();

      if (rate == null) {
        throw ApiException("Pair not supported for '$currency'.");
      }
      return rate;
    }
  }

  /// Handles HTTP response, checking for errors and decoding JSON.
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null || (data is Map && data.isEmpty)) {
        throw ApiException("Rate temporarily unavailable (empty response).");
      }
      return data;
    } else if (response.statusCode == 429) {
      throw ApiException("Rate limit exceeded. Please try again later.");
    } else {
      throw ApiException("Failed to fetch data (Error ${response.statusCode}).");
    }
  }
}