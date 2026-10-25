import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class SuggestEventScreen extends StatefulWidget {
  const SuggestEventScreen({super.key});

  @override
  State<SuggestEventScreen> createState() => _SuggestEventScreenState();
}

class _SuggestEventScreenState extends State<SuggestEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final ApiService _api = ApiService();

  DateTime? _date;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        // Force 24h format to match the API (HH:MM) and existing events
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final statusCode = await _api.createEventRequest(
        title: _titleController.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date!),
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (!mounted) return;
      if (statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks! Our team will review your event.'),
            backgroundColor: Colors.green,
          ),
        );
        // Opened via context.go, so pop may not be possible
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/events');
        }
      } else if (statusCode == 409) {
        // Duplicate pending request (deduped by title + date)
        setState(() =>
            _error = 'This event has already been suggested and is pending review.');
      } else {
        throw Exception('Failed to send suggestion');
      }
    } catch (_) {
      setState(() => _error = 'Failed to send suggestion. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = Colors.grey.shade500;

    InputDecoration decoration(String label, String hint) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor, fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: hintColor.withOpacity(0.6), fontSize: 14),
          filled: true,
          fillColor: fillColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD00B)),
          ),
        );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade400),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/events');
            }
          },
        ),
        title: Text(
          'Suggest an Event',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Know a great community event? Tell us and our team will review it.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration:
                      decoration('Event title', 'e.g., Beach Cleanup Day'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: decoration(
                      'Description (optional)', 'What is this event about?'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_startTimeController),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
                  decoration: decoration('Start time', 'Select time')
                      .copyWith(suffixIcon: const Icon(Icons.schedule)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Start time is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_endTimeController),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
                  decoration: decoration('End time', 'Select time')
                      .copyWith(suffixIcon: const Icon(Icons.schedule)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'End time is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration:
                      decoration('Location', 'e.g., Governors Beach'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: decoration('Address', 'Full address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text:
                        _date == null ? '' : DateFormat('d MMM yyyy').format(_date!),
                  ),
                  onTap: _pickDate,
                  decoration: decoration('Date', 'Select date')
                      .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                  validator: (_) =>
                      _date == null ? 'Date is required' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD00B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Send Suggestion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
