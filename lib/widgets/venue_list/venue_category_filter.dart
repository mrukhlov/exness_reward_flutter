import 'package:flutter/material.dart';
import '../../utils/category_icons.dart';

class VenueCategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String activeCategory;
  final Function(String) onCategorySelected;

  const VenueCategoryFilter({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = activeCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFD00B)
                      : (isDark ? const Color(0xFF252525) : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: isActive
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getCategoryIcon(category),
                      size: 18,
                      color: isActive ? Colors.black : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? Colors.black
                            : (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
