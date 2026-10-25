import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/events_provider.dart';
import '../widgets/events/events_header.dart';
import '../widgets/events/events_category_selector.dart';
import '../widgets/events/calendar_view.dart';
import '../widgets/events/event_list_item.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<Map<String, dynamic>> _categories = [
    {'id': 'All', 'label': 'All', 'color': 0xFFFFD00B, 'dot': false},
    {'id': 'Corporate', 'label': 'Corporate', 'color': 0xFF3B82F6, 'dot': true},
    {'id': 'Community', 'label': 'Community', 'color': 0xFF22C55E, 'dot': true},
  ];

  @override
  void initState() {
    super.initState();
    // Restore selected date from route query parameters or provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventsProvider = Provider.of<EventsProvider>(
        context,
        listen: false,
      );

      final selectedDateStr = GoRouterState.of(
        context,
      ).uri.queryParameters['selectedDate'];

      DateTime? dateToRestore;

      // First priority: query parameter from navigation
      if (selectedDateStr != null) {
        try {
          dateToRestore = DateTime.parse(selectedDateStr);
        } catch (e) {
          // Invalid date format, ignore
        }
      }

      // Second priority: stored date from provider (if not first visit)
      if (dateToRestore == null && eventsProvider.hasBeenVisited) {
        dateToRestore = eventsProvider.lastSelectedDate;
      }

      if (dateToRestore != null) {
        final restoredDate = dateToRestore;
        setState(() {
          _selectedDate = restoredDate;
          // Also update current date to show the correct month
          _currentDate = DateTime(restoredDate.year, restoredDate.month, 1);
        });
        // Save to provider
        eventsProvider.setLastSelectedDate(restoredDate);
      } else {
        // First visit or no stored date - save current date
        eventsProvider.setLastSelectedDate(_selectedDate);
      }

      if (eventsProvider.isStaleForMonth(_currentDate)) {
        eventsProvider.fetchEventsForMonth(date: _currentDate);
      }
    });
  }

  Future<void> _fetchEvents({bool forceRefresh = false}) async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    await eventsProvider.fetchEventsForMonth(
      date: _currentDate,
      forceRefresh: forceRefresh,
    );
  }

  List<Event> _getEventsForDate(DateTime date, List<Event> events) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return events.where((event) {
      final matchesDate = event.date == dateStr;
      final matchesCategory =
          _selectedCategory == 'All' ||
          event.type.name == _selectedCategory.toLowerCase();
      return matchesDate && matchesCategory;
    }).toList();
  }

  List<String> _getEventColorsForDate(DateTime date, List<Event> events) {
    final dateEvents = _getEventsForDate(date, events);
    if (dateEvents.isEmpty) return [];
    // Dot color follows the event type, like the badges (blue Corporate, green Community)
    return dateEvents
        .map((e) => e.type == EventType.corporate ? '#3B82F6' : '#22C55E')
        .toList();
  }

  List<Event> _getFilteredEventsList(List<Event> events) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return events.where((event) {
      final matchesDate = event.date == dateStr;
      final matchesCategory =
          _selectedCategory == 'All' ||
          event.type.name == _selectedCategory.toLowerCase();
      return matchesDate && matchesCategory;
    }).toList();
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentDate = DateTime(
        _currentDate.year,
        _currentDate.month + increment,
        1,
      );
    });
    // Fetch events for new month if stale
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    if (eventsProvider.isStaleForMonth(_currentDate)) {
      eventsProvider.fetchEventsForMonth(date: _currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Adaptive scaling factor based on screen height
    final isSmallScreen = screenHeight < 800;

    // Adaptive spacing
    final horizontalPadding = isSmallScreen
        ? 16.0
        : math.max(20.0, math.min(24.0, screenWidth * 0.06));
    final sectionSpacing = isSmallScreen
        ? 20.0
        : math.max(24.0, math.min(32.0, screenHeight * 0.04));

    final selectedDateFontSize = isSmallScreen ? 18.0 : 20.0;
    final eventCountFontSize = isSmallScreen ? 12.0 : 14.0;

    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, _) {
        final events = eventsProvider.getEventsForMonth(_currentDate);
        final isLoading = eventsProvider.isLoading;
        final error = eventsProvider.error;

        if (isLoading && events.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFFD00B)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading events...',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (error != null && events.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _fetchEvents(forceRefresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD00B),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final filteredEventsList = _getFilteredEventsList(events);

        return Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _fetchEvents(forceRefresh: true),
              color: const Color(0xFFFFD00B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EventsHeader(),
                    EventsCategorySelector(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                      categories: _categories,
                    ),
                    SizedBox(height: sectionSpacing),
                    CalendarView(
                      currentDate: _currentDate,
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                        final eventsProvider = Provider.of<EventsProvider>(
                          context,
                          listen: false,
                        );
                        eventsProvider.setLastSelectedDate(date);
                      },
                      onMonthChanged: _changeMonth,
                      events: events,
                      getEventColorsForDate: _getEventColorsForDate,
                    ),
                    SizedBox(height: sectionSpacing),
                    // Selected Date Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.day}',
                              style: TextStyle(
                                fontSize: selectedDateFontSize,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredEventsList.length} Event${filteredEventsList.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: eventCountFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Events List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ...filteredEventsList.map(
                            (event) => EventListItem(
                              event: event,
                              selectedDate: _selectedDate,
                            ),
                          ),
                          if (filteredEventsList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 48,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No events scheduled',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
