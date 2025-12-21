import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _apiService = ApiService();
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<Map<String, dynamic>> _categories = [
    {'id': 'All', 'label': 'All', 'color': 0xFFFFD00B},
    {'id': 'Corporate', 'label': 'Corporate', 'color': 0xFF3B82F6},
    {'id': 'Community', 'label': 'Community', 'color': 0xFF22C55E},
  ];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final year = _currentDate.year;
      final month = _currentDate.month;
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final events = await _apiService.getEvents(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      setState(() {
        _events = events;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Event> _getEventsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _events.where((event) {
      final matchesDate = event.date == dateStr;
      final matchesCategory =
          _selectedCategory == 'All' ||
          event.type.toString().split('.').last == _selectedCategory;
      return matchesDate && matchesCategory;
    }).toList();
  }

  List<Event> get _filteredEventsList {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _events.where((event) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD00B)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _fetchEvents();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _categories.map((cat) {
                  final isActive = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat['id'] != 'All')
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(cat['color'] as int),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (cat['id'] != 'All') const SizedBox(width: 6),
                          Text(cat['label'] as String),
                        ],
                      ),
                      selected: isActive,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat['id'] as String);
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: const Color(0xFFFFD00B),
                      labelStyle: TextStyle(
                        color: isActive ? Colors.black : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Calendar
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Calendar Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121212) : Colors.white,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setState(() {
                                    _currentDate = DateTime(
                                      _currentDate.year,
                                      _currentDate.month - 1,
                                    );
                                  });
                                  _fetchEvents();
                                },
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_currentDate),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setState(() {
                                    _currentDate = DateTime(
                                      _currentDate.year,
                                      _currentDate.month + 1,
                                    );
                                  });
                                  _fetchEvents();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Week Days
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _weekDays.map((day) {
                              return SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Calendar Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _getCalendarDays().length,
                            itemBuilder: (context, index) {
                              final date = _getCalendarDays()[index];
                              if (date == null) {
                                return const SizedBox();
                              }

                              final isSelected =
                                  _selectedDate.year == date.year &&
                                  _selectedDate.month == date.month &&
                                  _selectedDate.day == date.day;
                              final dateEvents = _getEventsForDate(date);

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDate = date),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFD00B)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.black
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                        ),
                                      ),
                                      if (dateEvents.isNotEmpty)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: dateEvents.take(3).map((
                                            event,
                                          ) {
                                            return Container(
                                              width: 4,
                                              height: 4,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.black
                                                    : _parseColor(event.color),
                                                shape: BoxShape.circle,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Selected Date Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM d').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${_filteredEventsList.length} Event${_filteredEventsList.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Events List
                    ..._filteredEventsList.map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          child: ListTile(
                            leading: Container(
                              width: 64,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('MMM')
                                        .format(DateTime.parse(event.date))
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    '${DateTime.parse(event.date).day}',
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
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                      event.color,
                                    ).withOpacity(0.1),
                                    border: Border.all(
                                      color: _parseColor(event.color),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
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
                                      color: _parseColor(event.color),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                          color: Colors.grey.shade500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => context.go('/event/${event.id}'),
                          ),
                        ),
                      );
                    }),
                    if (_filteredEventsList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events scheduled',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }
}
