import 'package:flutter/material.dart';

class VenueSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;
  final Function(String) onChanged;

  const VenueSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search venues or cuisines...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasActiveFilters
                    ? const Color(0xFFFFD00B)
                    : (isDark ? const Color(0xFF252525) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.tune,
                      color: hasActiveFilters
                          ? Colors.black
                          : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
