import 'package:flutter/material.dart';
import '../models/face_filter.dart';

/// Widget for selecting face filters
class FaceFilterSelector extends StatelessWidget {
  const FaceFilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.height = 80,
  });

  final FaceFilterType selectedFilter;
  final ValueChanged<FaceFilterType> onFilterSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FaceFilter.allFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = FaceFilter.allFilters[index];
          final isSelected = filter.type == selectedFilter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? filter.color.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? filter.color
                          : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filter.icon,
                    color: isSelected ? filter.color : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? filter.color : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact version for smaller spaces
class CompactFaceFilterSelector extends StatelessWidget {
  const CompactFaceFilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final FaceFilterType selectedFilter;
  final ValueChanged<FaceFilterType> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: FaceFilter.allFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = FaceFilter.allFilters[index];
          final isSelected = filter.type == selectedFilter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? filter.color.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color:
                      isSelected
                          ? filter.color
                          : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                filter.icon,
                color: isSelected ? filter.color : Colors.grey.shade600,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}
