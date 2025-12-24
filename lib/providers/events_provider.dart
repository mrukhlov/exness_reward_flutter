import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class EventsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, List<Event>> _eventsByMonth = {}; // Key: "YYYY-MM", Value: List<Event>
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;
  DateTime? _lastSelectedDate;
  bool _hasBeenVisited = false;

  List<Event> get events {
    // Return all events from all months
    return _eventsByMonth.values.expand((events) => events).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEvents => _eventsByMonth.isNotEmpty;

  bool isStaleForMonth(DateTime date) {
    final monthKey = _getMonthKey(date);
    if (!_eventsByMonth.containsKey(monthKey)) return true;
    if (_lastFetchTime == null) return true;
    // Consider data stale after 5 minutes
    return DateTime.now().difference(_lastFetchTime!).inMinutes > 5;
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get events for a specific month
  List<Event> getEventsForMonth(DateTime date) {
    final monthKey = _getMonthKey(date);
    return _eventsByMonth[monthKey] ?? [];
  }

  /// Fetch events for a specific month
  Future<void> fetchEventsForMonth({
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    final monthKey = _getMonthKey(date);
    
    // Don't fetch if data is fresh and not forcing refresh
    if (!forceRefresh && !isStaleForMonth(date) && _eventsByMonth.containsKey(monthKey)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final year = date.year;
      final month = date.month;
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final events = await _apiService.getEvents(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      _eventsByMonth[monthKey] = events;
      _lastFetchTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the last selected date
  void setLastSelectedDate(DateTime date) {
    _lastSelectedDate = date;
    _hasBeenVisited = true;
    notifyListeners();
  }

  /// Get the last selected date
  DateTime? get lastSelectedDate => _lastSelectedDate;

  /// Check if events screen has been visited before
  bool get hasBeenVisited => _hasBeenVisited;

  /// Clear events data
  void clear() {
    _eventsByMonth.clear();
    _error = null;
    _lastFetchTime = null;
    notifyListeners();
  }
}

