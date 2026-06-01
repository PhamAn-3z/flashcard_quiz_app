import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../utils/constants.dart';

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  bool _isLoading = false;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  List<Deck> get decks => _decks;
  bool get isLoading => _isLoading;

  Future<void> fetchDecks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get('/decks');
      final List<dynamic> data = response.data['data'] != null ? response.data['data'] : response.data;
      
      _decks = data.map((json) => Deck.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Xử lý lỗi nếu cần
    }
  }
}
