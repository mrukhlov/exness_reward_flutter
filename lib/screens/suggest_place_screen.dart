import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/venue_category.dart';
import '../services/api_service.dart';

class SuggestPlaceScreen extends StatefulWidget {
  const SuggestPlaceScreen({super.key});

  @override
  State<SuggestPlaceScreen> createState() => _SuggestPlaceScreenState();
}

class _SuggestPlaceScreenState extends State<SuggestPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  final ApiService _api = ApiService();

  List<VenueCategory> _categories = [];
  VenueCategory? _category;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.getCategories();
      if (mounted) setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final statusCode = await _api.createVenueRequest(
        name: _nameController.text.trim(),
        categoryId: _category?.id,
        locationName: _locationController.text.trim(),
        address: _addressController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      if (!mounted) return;
      if (statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks! Our team will review your suggestion.'),
            backgroundColor: Colors.green,
          ),
        );
        // Opened via context.go, so pop may not be possible (see appBar back button)
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      } else if (statusCode == 409) {
        // Duplicate pending request (deduped by name + address)
        setState(() =>
            _error = 'This place has already been suggested and is pending review.');
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
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Suggest a Place',
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
                  'Know a great place your colleagues would love? Tell us and our team will review it.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      decoration('Place name', 'e.g., Sunset Bakery'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VenueCategory>(
                  initialValue: _category,
                  decoration: decoration(
                    'Category (optional)',
                    _isLoadingCategories ? 'Loading…' : 'Select a category',
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c.name, style: TextStyle(color: textColor)),
                          ))
                      .toList(),
                  onChanged: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration:
                      decoration('Location', 'e.g., Limassol Marina'),
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
                  controller: _commentController,
                  maxLines: 3,
                  decoration: decoration(
                      'Comment (optional)', 'Why is this place worth adding?'),
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
