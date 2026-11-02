import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import 'app_cached_image.dart';

class AiFridgeSheet extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;

  const AiFridgeSheet({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
  });

  static void show(
    BuildContext context, {
    required List<Recipe> recipes,
    required ValueChanged<Recipe> onSelectRecipe,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiFridgeSheet(
        recipes: recipes,
        onSelectRecipe: onSelectRecipe,
      ),
    );
  }

  @override
  State<AiFridgeSheet> createState() => _AiFridgeSheetState();
}

class _AiFridgeSheetState extends State<AiFridgeSheet> {
  final List<String> _pantryItems = [
    'Telur',
    'Nasi',
    'Ayam',
    'Salmon',
    'Pasta',
    'Keju',
    'Daging Sapi',
    'Matcha',
    'Udang',
    'Santan',
  ];

  final Set<String> _selected = {'Telur', 'Nasi', 'Ayam'};

  @override
  Widget build(BuildContext context) {
    final matched = widget.recipes.where((r) {
      final titleLower = r.title.toLowerCase();
      final ingMatch = r.ingredients.any(
        (ing) => _selected.any((s) => ing.name.toLowerCase().contains(s.toLowerCase())),
      );
      final titleMatch = _selected.any((s) => titleLower.contains(s.toLowerCase()));
      return ingMatch || titleMatch;
    }).toList();

    final results = matched.isNotEmpty ? matched.take(3).toList() : widget.recipes.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kocok Bahan Kulkasmu',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'Pilih bahan yang tersedia di dapurmu hari ini',
                        style: TextStyle(color: AppColors.secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pantry item pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pantryItems.map((item) {
              final active = _selected.contains(item);
              return ChoiceChip(
                label: Text(item),
                selected: active,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selected.add(item);
                    } else {
                      _selected.remove(item);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: active ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Matching Recipes
          Text(
            'REKOMENDASI RESEP COCOK (${results.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),

          ...results.map((r) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onSelectRecipe(r);
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    AppCachedImage(
                      imageUrl: r.image,
                      width: 48,
                      height: 48,
                      isCircle: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.time} • ${r.difficulty}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Masak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
