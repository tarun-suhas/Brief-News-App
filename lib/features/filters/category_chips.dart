import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:news_app/generated/app_localizations.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: AppStrings.categories.length,
        itemBuilder: (context, index) {
          final category = AppStrings.categories[index];
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                            ? AppColors.primary.withValues(alpha: 0.3) 
                            : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getCategoryLabel(context, category),
                      style: AppTextStyles.button.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'All': return l10n.catAll;
      case 'Politics': return l10n.catPolitics;
      case 'Sports': return l10n.catSports;
      case 'Tech': return l10n.catTech;
      case 'Local': return l10n.catLocal;
      case 'Business': return l10n.catBusiness;
      case 'Entertainment': return l10n.catEntertainment;
      default: return category;
    }
  }
}
