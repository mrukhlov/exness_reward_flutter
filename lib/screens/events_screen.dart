import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/events_provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  static const List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
          event.type.toString().split('.').last == _selectedCategory;
      return matchesDate && matchesCategory;
    }).toList();
  }

  List<String> _getEventColorsForDate(DateTime date, List<Event> events) {
    final dateEvents = _getEventsForDate(date, events);
    if (dateEvents.isEmpty) return [];
    return dateEvents.map((e) => e.color).toList();
  }

  List<Event> _getFilteredEventsList(List<Event> events) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return events.where((event) {
      final matchesDate = event.date == dateStr;
      final matchesCategory =
          _selectedCategory == 'All' ||
          event.type.toString().split('.').last == _selectedCategory;
      return matchesDate && matchesCategory;
    }).toList();
  }

  List<DateTime?> _getCalendarDays() {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1).weekday % 7;

    final days = <DateTime?>[];
    for (int i = 0; i < firstDayOfMonth; i++) {
      days.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(year, month, i));
    }
    return days;
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
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
    final verticalSpacing = isSmallScreen 
        ? 16.0 
        : math.max(20.0, math.min(32.0, screenHeight * 0.025));
    final sectionSpacing = isSmallScreen 
        ? 20.0 
        : math.max(24.0, math.min(32.0, screenHeight * 0.04));
    
    // Adaptive font sizes
    final headerFontSize = isSmallScreen ? 20.0 : 24.0;
    final categoryFontSize = isSmallScreen ? 12.0 : 14.0;
    final categoryHeight = isSmallScreen ? 36.0 : 40.0;
    final categoryPadding = isSmallScreen 
        ? EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    final categorySpacing = isSmallScreen ? 6.0 : 12.0;
    final monthFontSize = isSmallScreen ? 16.0 : 20.0;
    final calendarDayFontSize = isSmallScreen ? 12.0 : 16.0;
    final calendarCellSize = isSmallScreen ? 28.0 : 40.0;
    final calendarPadding = isSmallScreen ? 6.0 : 16.0;
    final calendarOuterPadding = isSmallScreen ? 6.0 : 16.0;
    final calendarSpacing = isSmallScreen ? 4.0 : 8.0;
    final selectedDateFontSize = isSmallScreen ? 18.0 : 20.0;
    final eventCountFontSize = isSmallScreen ? 12.0 : 14.0;
    final eventTitleFontSize = isSmallScreen ? 16.0 : 18.0;
    final eventDateBoxWidth = isSmallScreen ? 56.0 : 64.0;
    final eventDateBoxHeight = isSmallScreen ? 72.0 : 80.0;
    final eventDateDayFontSize = isSmallScreen ? 20.0 : 24.0;
    final eventDateMonthFontSize = isSmallScreen ? 10.0 : 12.0;
    final eventTimeFontSize = isSmallScreen ? 11.0 : 12.0;
    
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
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Events',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          // Container(
                          //   width: 40,
                          //   height: 40,
                          //   decoration: BoxDecoration(
                          //     color: isDark
                          //         ? Colors.white.withOpacity(0.1)
                          //         : Colors.white,
                          //     shape: BoxShape.circle,
                          //   ),
                          //   child: IconButton(
                          //     icon: Icon(
                          //       Icons.tune,
                          //       size: 24,
                          //       color: isDark ? Colors.white : Colors.black,
                          //     ),
                          //     onPressed: () {},
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    // Categories
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._categories.map((cat) {
                              final isActive = _selectedCategory == cat['id'];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: categorySpacing,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () =>
                                          _selectedCategory = cat['id'] as String,
                                    );
                                  },
                                  child: Container(
                                    height: categoryHeight,
                                    padding: categoryPadding,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFFFD00B)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isActive
                                            ? const Color(0xFFFFD00B)
                                            : (isDark
                                                  ? Colors.white.withOpacity(0.2)
                                                  : Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (cat['dot'] == true) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(cat['color'] as int),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        cat['label'] as String,
                                        style: TextStyle(
                                          fontSize: categoryFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: isActive
                                              ? Colors.black
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.grey.shade600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    // Calendar Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: calendarOuterPadding),
                      child: Container(
                        padding: EdgeInsets.all(calendarPadding),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF121212)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Month Navigation
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 0.0 : 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_left,
                                      size: isSmallScreen ? 20.0 : 28.0,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () => _changeMonth(-1),
                                  ),
                                  Text(
                                    '${_monthNames[_currentDate.month - 1]} ${_currentDate.year}',
                                    style: TextStyle(
                                      fontSize: monthFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      size: isSmallScreen ? 20.0 : 28.0,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () => _changeMonth(1),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                            // Week Days
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;
                                final cellWidth = availableWidth / 7;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: _weekDays.map((day) {
                                    return SizedBox(
                                      width: cellWidth,
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10.0 : 12.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            SizedBox(height: calendarSpacing),
                            // Calendar Grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;
                                final cellSize = availableWidth / 7;
                                return Wrap(
                                  children: _getCalendarDays().map((date) {
                                    if (date == null) {
                                      return SizedBox(
                                        width: cellSize,
                                        height: cellSize,
                                      );
                                    }

                                    final isSelected =
                                        _selectedDate.year == date.year &&
                                        _selectedDate.month == date.month &&
                                        _selectedDate.day == date.day;
                                    final eventColors = _getEventColorsForDate(
                                      date,
                                      events,
                                    );

                                    return SizedBox(
                                      width: cellSize,
                                      height: cellSize,
                                      child: Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () => _selectedDate = date,
                                                );
                                                // Save selected date to provider
                                                final eventsProvider =
                                                    Provider.of<EventsProvider>(
                                                      context,
                                                      listen: false,
                                                    );
                                                eventsProvider.setLastSelectedDate(
                                                  date,
                                                );
                                              },
                                              child: Container(
                                                width: calendarCellSize,
                                                height: calendarCellSize,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFFFFD00B)
                                                      : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${date.day}',
                                                    style: TextStyle(
                                                      fontSize: calendarDayFontSize,
                                                      fontWeight: FontWeight.w500,
                                                      color: isSelected
                                                          ? Colors.black
                                                          : (isDark
                                                                ? Colors.white
                                                                : Colors.black),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        // Event Indicators
                                        if (eventColors.isNotEmpty)
                                          Positioned(
                                            bottom: 4,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: eventColors.map((
                                                color,
                                              ) {
                                                return Container(
                                                  width: 6,
                                                  height: 6,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 1,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.black
                                                        : _parseColor(color),
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Selected Date Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                          SizedBox(width: 8),
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
                          ...filteredEventsList.map((event) {
                            final eventDate = DateTime.parse(event.date);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {
                                  final selectedDateStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate);
                                  context.go(
                                    '/event/${event.id}?selectedDate=$selectedDateStr',
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Date Box
                                      Container(
                                        width: 64,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _monthNames[eventDate.month - 1]
                                                  .substring(0, 3)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${eventDate.day}',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Event Type Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _parseColor(
                                                  event.color,
                                                ).withOpacity(0.1),
                                                border: Border.all(
                                                  color: _parseColor(
                                                    event.color,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                event.type
                                                    .toString()
                                                    .split('.')
                                                    .last
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: _parseColor(
                                                    event.color,
                                                  ),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Event Title
                                            Text(
                                              event.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.normal,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            // Time and Location
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.schedule,
                                                  size: 14,
                                                  color: Color(0xFFFFD00B),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${event.startTime} - ${event.endTime}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Icon(
                                                  Icons.place,
                                                  size: 14,
                                                  color: Color(0xFFFFD00B),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    event.location,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
