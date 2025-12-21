import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider _authProvider;
  
  List<String> _favorites = [];
  bool _isLoading = true;

  List<String> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider(this._authProvider) {
    _loadFavorites();
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      _loadFavorites();
    } else {
      _favorites = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    if (!_authProvider.isAuthenticated) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final favoriteVenues = await _apiService.getFavorites();
      _favorites = favoriteVenues.map((v) => v.id).toList();
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String id) {
    return _favorites.contains(id);
  }

  Future<void> addFavorite(String id) async {
    if (!_authProvider.isAuthenticated) {
      throw Exception('Please login to add favorites');
    }

    try {
      await _apiService.addFavorite(id);
      if (!_favorites.contains(id)) {
        _favorites.add(id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to add favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String id) async {
    if (!_authProvider.isAuthenticated) {
      return;
    }

    try {
      await _apiService.removeFavorite(id);
      _favorites.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove favorite: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(id);
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}

