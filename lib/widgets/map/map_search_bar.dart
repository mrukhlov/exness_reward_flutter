import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDark;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const MapSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isDark,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E1E) : Colors.white).withOpacity(
          0.9,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search venues...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 24,
            color: isDark ? Colors.white : Colors.grey.shade600,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: isDark ? Colors.white : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
