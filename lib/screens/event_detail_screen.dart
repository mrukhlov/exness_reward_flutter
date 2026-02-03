import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/event_detail/event_header.dart';
import '../widgets/event_detail/event_date_badge.dart';
import '../widgets/event_detail/event_time_card.dart';
import '../widgets/event_detail/event_location_card.dart';
import '../widgets/event_detail/event_about_section.dart';
import '../widgets/event_detail/event_action_footer.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _apiService = ApiService();
  Event? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvent();
  }

  Future<void> _fetchEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _apiService.getEvent(widget.eventId);
      setState(() {
        _event = event;
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      // Preserve selected date from route query parameters
      final selectedDateStr = GoRouterState.of(
        context,
      ).uri.queryParameters['selectedDate'];
      if (selectedDateStr != null) {
        context.go('/events?selectedDate=$selectedDateStr');
      } else {
        context.go('/events');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async {
          _handleBack();
          return false;
        },
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD00B)),
          ),
        ),
      );
    }

    if (_error != null || _event == null) {
      return WillPopScope(
        onWillPop: () async {
          _handleBack();
          return false;
        },
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error ?? 'Event not found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleBack,
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final eventDate = DateTime.parse(event.date);
    final eventColor = _parseColor(event.color);

    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              EventHeader(
                title: 'Event Details',
                isDark: isDark,
                onBack: _handleBack,
                // Uncomment to enable share functionality
                // onShare: () {
                //   Share.share(
                //     'Join me at ${event.title} on ${event.date} at ${event.location}!',
                //   );
                // },
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      EventDateBadge(
                        eventDate: eventDate,
                        eventType: event.type,
                        eventColor: eventColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      EventTimeCard(
                        eventDate: eventDate,
                        startTime: event.startTime,
                        endTime: event.endTime,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      EventLocationCard(
                        location: event.location,
                        address: event.address,
                        isDark: isDark,
                        onViewMap: () {
                          // TODO: Open in maps
                        },
                      ),
                      const SizedBox(height: 32),
                      EventAboutSection(
                        description: event.description,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              EventActionFooter(
                isDark: isDark,
                onAddToCalendar: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to calendar!')),
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
