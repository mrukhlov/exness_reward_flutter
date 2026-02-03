import 'package:flutter/material.dart';

class VenueFilters extends StatelessWidget {
  final String? selectedPriceLevel;
  final double minRating;
  final bool openNowOnly;
  final bool partnerOnly;
  final Function(String?) onPriceLevelChanged;
  final Function(double) onRatingChanged;
  final Function(bool) onOpenNowChanged;
  final Function(bool) onPartnerChanged;
  final VoidCallback onReset;

  const VenueFilters({
    super.key,
    required this.selectedPriceLevel,
    required this.minRating,
    required this.openNowOnly,
    required this.partnerOnly,
    required this.onPriceLevelChanged,
    required this.onRatingChanged,
    required this.onOpenNowChanged,
    required this.onPartnerChanged,
    required this.onReset,
  });

  bool get _hasActiveFilters {
    return selectedPriceLevel != null ||
        minRating > 0.0 ||
        openNowOnly ||
        partnerOnly;
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD00B)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD00B)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: onReset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Color(0xFFFFD00B), fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Price Level Filter
          Text(
            'Price Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                context,
                label: 'Any',
                isSelected: selectedPriceLevel == null,
                onTap: () => onPriceLevelChanged(null),
              ),
              _buildFilterChip(
                context,
                label: '\$',
                isSelected: selectedPriceLevel == '\$',
                onTap: () => onPriceLevelChanged('\$'),
              ),
              _buildFilterChip(
                context,
                label: '\$\$',
                isSelected: selectedPriceLevel == '\$\$',
                onTap: () => onPriceLevelChanged('\$\$'),
              ),
              _buildFilterChip(
                context,
                label: '\$\$\$',
                isSelected: selectedPriceLevel == '\$\$\$',
                onTap: () => onPriceLevelChanged('\$\$\$'),
              ),
              _buildFilterChip(
                context,
                label: '\$\$\$\$',
                isSelected: selectedPriceLevel == '\$\$\$\$',
                onTap: () => onPriceLevelChanged('\$\$\$\$'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Rating Filter
          Text(
            'Minimum Rating',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: minRating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  activeColor: const Color(0xFFFFD00B),
                  inactiveColor: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  onChanged: onRatingChanged,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  minRating.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Open Now Filter
          Row(
            children: [
              Expanded(
                child: Text(
                  'Open Now Only',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
              Switch(
                value: openNowOnly,
                onChanged: onOpenNowChanged,
                activeColor: const Color(0xFFFFD00B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Partner Only Filter
          Row(
            children: [
              Expanded(
                child: Text(
                  'Partner Venues Only',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
              Switch(
                value: partnerOnly,
                onChanged: onPartnerChanged,
                activeColor: const Color(0xFFFFD00B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
