import 'package:flutter/material.dart';
import '../../models/event.dart';

class CalendarView extends StatelessWidget {
  final DateTime currentDate;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(int) onMonthChanged;
  final List<Event> events;
  final Function(DateTime, List<Event>) getEventColorsForDate;

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

  const CalendarView({
    super.key,
    required this.currentDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.events,
    required this.getEventColorsForDate,
  });

  List<DateTime?> _getCalendarDays() {
    final year = currentDate.year;
    final month = currentDate.month;
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
    final isSmallScreen = screenHeight < 800;

    final calendarOuterPadding = isSmallScreen ? 6.0 : 16.0;
    final calendarPadding = isSmallScreen ? 6.0 : 16.0;
    final monthFontSize = isSmallScreen ? 16.0 : 20.0;
    final calendarSpacing = isSmallScreen ? 4.0 : 8.0;
    final calendarCellSize = isSmallScreen ? 28.0 : 40.0;
    final calendarDayFontSize = isSmallScreen ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: calendarOuterPadding),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -500) {
              onMonthChanged(1);
            } else if (details.primaryVelocity! > 500) {
              onMonthChanged(-1);
            }
          }
        },
        child: Container(
          padding: EdgeInsets.all(calendarPadding),
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 0.0 : 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: isSmallScreen ? 20.0 : 28.0,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onMonthChanged(-1),
                    ),
                    Text(
                      '${_monthNames[currentDate.month - 1]} ${currentDate.year}',
                      style: TextStyle(
                        fontSize: monthFontSize,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        size: isSmallScreen ? 20.0 : 28.0,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onMonthChanged(1),
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
                        return SizedBox(width: cellSize, height: cellSize);
                      }

                      final isSelected =
                          selectedDate.year == date.year &&
                          selectedDate.month == date.month &&
                          selectedDate.day == date.day;

                      // We need to implement this logic properly using the passed function
                      // Since getEventColorsForDate returns List<String> (hex colors)
                      // we need to convert them to Color objects inside the builder
                      // But the signature in parameter expects List<Event> second arg
                      // Let's assume the passed function handles the filtering

                      // Actually, let's simplify. The parent can pass a function that takes a date
                      // and returns List<String> of color strings.
                      // I'll adjust the type definition in the class.

                      final eventColorStrings = getEventColorsForDate(
                        date,
                        events,
                      );
                      // Note: I defined getEventColorsForDate as (DateTime, List<Event>) -> List<String> implicitly in the main file
                      // But here I declared it as dynamic or generic function.
                      // Wait, I declared: final Function(DateTime, List<Event>) getEventColorsForDate;
                      // And _getEventColorsForDate returns List<String>.
                      // So eventColorStrings is List<String> (dynamic, strictly speaking unless typed)

                      final eventColors = (eventColorStrings as List)
                          .cast<String>();

                      return SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => onDateSelected(date),
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
                                    children: eventColors.map((color) {
                                      return Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _parseColor(color),
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
    );
  }
}
