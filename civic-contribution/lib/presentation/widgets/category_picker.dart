import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/constants.dart';

class CategoryPicker extends StatelessWidget {
  final IssueCategory selected;
  final ValueChanged<IssueCategory> onSelected;

  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const categories = IssueCategory.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

