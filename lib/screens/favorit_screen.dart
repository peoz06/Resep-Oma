import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class FavoritScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String>? onShowToast;

  const FavoritScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onToggleFavorite,
    this.onShowToast,
  });

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeCategory = 'all';
  String _sortOrder = 'newest'; // 'newest' or 'popular'

  final List<Map<String, String>> _chips = [
    {'id': 'all', 'label': 'Semua'},
    {'id': 'asian', 'label': 'Asian Food'},
    {'id': 'western', 'label': 'Western'},
    {'id': 'pasta', 'label': 'Pasta'},
    {'id': 'dessert', 'label': 'Camilan & Dessert'},
    {'id': 'healthy', 'label': 'Diet Sehat'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    var favorites = widget.recipes.where((r) => r.isFavorite).where((r) {
      final matchCat = _activeCategory == 'all' ||
          r.filterKey.toLowerCase().contains(_activeCategory) ||
          r.category.toLowerCase().contains(_activeCategory);

      final matchSearch = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.author.toLowerCase().contains(query);

      return matchCat && matchSearch;
    }).toList();

    if (_sortOrder == 'popular') {
      favorites.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resep Favorit', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 2),
                const Text(
                  'Kumpulan inspirasi masakan yang kamu simpan',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark, color: AppColors.primary, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Search Field
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Cari di resep favorit...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortOrder = _sortOrder == 'newest' ? 'popular' : 'newest';
                });
                widget.onShowToast?.call(
                  'Diurutkan berdasarkan ${_sortOrder == 'newest' ? 'Terbaru Disimpan' : 'Paling Disukai'}',
                );
              },
              icon: const Icon(Icons.tune, color: AppColors.onSurface, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(48, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: _chips.map((chip) {
              final active = _activeCategory == chip['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(chip['label']!),
                  selected: active,
                  onSelected: (val) {
                    if (val) setState(() => _activeCategory = chip['id']!);
                  },
                  selectedColor: AppColors.inverseSurface,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Count & Sort Dropdown Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${favorites.length} Resep Ditampilkan',
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _sortOrder = _sortOrder == 'newest' ? 'popular' : 'newest';
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      _sortOrder == 'newest' ? 'Terbaru Disimpan' : 'Paling Disukai',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const Icon(Icons.expand_more, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Favorites Cards List
        if (favorites.isNotEmpty) ...[
          ...favorites.map((r) => _buildFavoriteCard(r)),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ramen_dining, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text('Resep Tidak Ditemukan', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text(
                  'Coba kata kunci lain atau telusuri koleksi kategori resep lainnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _activeCategory = 'all';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inverseSurface,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Reset Pencarian'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Weekly Meal Plan CTA Tip
        InkWell(
          onTap: () {
            widget.onShowToast?.call('Jadwal masak mingguan tersinkronisasi dengan favorit Anda!');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mau masak apa minggu ini?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Atur jadwal masak mingguan dari resep tersimpanmu.',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.onSurfaceVariant, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFavoriteCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCachedImage(
                    imageUrl: recipe.image,
                    width: 90,
                    height: 90,
                    isCircle: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            recipe.category,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          recipe.author,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.white60, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              recipe.time,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.equalizer, color: Colors.white60, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              recipe.difficulty,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, color: AppColors.primaryFixedDim, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.likes} Suka',
                        style: const TextStyle(
                          color: AppColors.primaryFixedDim,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onSelectRecipe(recipe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Lihat Resep', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => widget.onToggleFavorite(recipe.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
