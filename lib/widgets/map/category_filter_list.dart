import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/venues_provider.dart';
import '../../utils/category_icons.dart';

class CategoryFilterList extends StatelessWidget {
  final String activeCategory;
  final bool isDark;
  final Function(String) onCategorySelected;

  const CategoryFilterList({
    super.key,
    required this.activeCategory,
    required this.isDark,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Consumer<VenuesProvider>(
        builder: (context, venuesProvider, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: venuesProvider.categories.length,
            itemBuilder: (context, index) {
              final category = venuesProvider.categories[index];
              final isActive = activeCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: GestureDetector(
                  onTap: () => onCategorySelected(category),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFFD00B)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                                .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFFFD00B)
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(category),
                          size: 16,
                          color: isActive
                              ? Colors.black
                              : (isDark ? Colors.white : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.black
                                : (isDark
                                      ? Colors.white
                                      : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
