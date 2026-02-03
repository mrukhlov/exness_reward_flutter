import 'package:flutter/material.dart';

class EventsCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<Map<String, dynamic>> categories;

  const EventsCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenHeight < 800;

    final categoryHeight = isSmallScreen ? 36.0 : 40.0;
    final categoryPadding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    final categoryFontSize = isSmallScreen ? 12.0 : 14.0;
    final categorySpacing = isSmallScreen ? 6.0 : 12.0;
    final horizontalPadding = isSmallScreen
        ? 16.0
        : (screenWidth * 0.06).clamp(20.0, 24.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isActive = selectedCategory == cat['id'];
            return Padding(
              padding: EdgeInsets.only(right: categorySpacing),
              child: GestureDetector(
                onTap: () => onCategorySelected(cat['id'] as String),
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
                              : (isDark ? Colors.white : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
