import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/book.dart';

class BookApiService {
  BookApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _resourcePath = '/api/books';
  static const String _baseUrlOverride = String.fromEnvironment(
    'BOOK_API_BASE_URL',
  );

  String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_baseUrlOverride);
    }

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.0.2.2:8080$_resourcePath';
    }

    return 'http://localhost:8080$_resourcePath';
  }

  Future<List<Book>> fetchBooks() async {
    final response = await _client.get(Uri.parse(baseUrl));
    _ensureSuccess(response, const [200]);

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const BookApiException(
        statusCode: 500,
        message: 'La reponse API n est pas une liste de livres.',
      );
    }

    return decoded
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Book> fetchBook(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/$id'));
    _ensureSuccess(response, const [200]);
    return Book.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Book> createBook(Book book) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _jsonHeaders,
      body: jsonEncode(book.toJson(includeId: false)),
    );
    _ensureSuccess(response, const [201]);
    return Book.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Book> updateBook(Book book) async {
    final id = book.id;
    if (id == null) {
      throw const BookApiException(
        statusCode: 400,
        message: 'Impossible de modifier un livre sans identifiant.',
      );
    }

    final response = await _client.put(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders,
      body: jsonEncode(book.toJson(includeId: false)),
    );
    _ensureSuccess(response, const [200]);
    return Book.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteBook(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/$id'));
    _ensureSuccess(response, const [204]);
  }

  void _ensureSuccess(http.Response response, List<int> allowedStatusCodes) {
    if (allowedStatusCodes.contains(response.statusCode)) {
      return;
    }

    throw _parseError(response);
  }

  BookApiException _parseError(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return BookApiException(
        statusCode: response.statusCode,
        message: 'Erreur API ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final validationErrors =
            (decoded['validationErrors'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const <String, String>{};

        return BookApiException(
          statusCode: response.statusCode,
          message: (decoded['message'] ?? decoded['error'] ?? body).toString(),
          validationErrors: validationErrors,
        );
      }
    } catch (_) {
      // Fall back to raw text if the backend did not return JSON.
    }

    return BookApiException(statusCode: response.statusCode, message: body);
  }

  String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith(_resourcePath)) {
      return trimmed;
    }
    return '${trimmed.replaceFirst(RegExp(r'/$'), '')}$_resourcePath';
  }

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };
}

class BookApiException implements Exception {
  const BookApiException({
    required this.statusCode,
    required this.message,
    this.validationErrors = const <String, String>{},
  });

  final int statusCode;
  final String message;
  final Map<String, String> validationErrors;

  String get displayMessage {
    final lines = <String>[];

    switch (statusCode) {
      case 400:
        lines.add('Validation echouee.');
      case 404:
        lines.add('Livre introuvable.');
      case 409:
        lines.add('ISBN deja utilise.');
      default:
        lines.add('Erreur API $statusCode.');
    }

    if (message.isNotEmpty) {
      lines.add(message);
    }

    validationErrors.forEach((field, error) {
      lines.add('$field: $error');
    });

    return lines.join('\n');
  }

  @override
  String toString() => displayMessage;
}
