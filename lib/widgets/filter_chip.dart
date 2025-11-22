import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  final bool vaccinated;
  final bool sterilized;
  final bool adoptable;
  final Function(String) onFilterChanged;
  final VoidCallback? onClearAll;

  const FilterChipsRow({
    super.key,
    required this.vaccinated,
    required this.sterilized,
    required this.adoptable,
    required this.onFilterChanged,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = vaccinated || sterilized || adoptable;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CustomFilterChip(
            label: 'Vaccinated',
            icon: Icons.vaccines,
            isSelected: vaccinated,
            onTap: () => onFilterChanged('vaccinated'),
          ),
          const SizedBox(width: 8),
          CustomFilterChip(
            label: 'Sterilized',
            icon: Icons.medical_services,
            isSelected: sterilized,
            onTap: () => onFilterChanged('sterilized'),
          ),
          const SizedBox(width: 8),
          CustomFilterChip(
            label: 'Ready for Adoption',
            icon: Icons.favorite,
            isSelected: adoptable,
            onTap: () => onFilterChanged('adoptable'),
          ),
          if (hasActiveFilters && onClearAll != null) ...[
            const SizedBox(width: 8),
            Material(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onClearAll,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.clear_all, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Clear All',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}