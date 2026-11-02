import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class EksplorScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String>? onShowToast;

  const EksplorScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onToggleFavorite,
    this.onShowToast,
  });

  @override
  State<EksplorScreen> createState() => _EksplorScreenState();
}

class _EksplorScreenState extends State<EksplorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeTab = 'populer';
  String? _selectedCategory;

  final List<String> _trendingTags = ['#MentaiRice', '#PastaCarbonara', '#VeganDiet', '#DimsumRumahan'];

  final List<Map<String, dynamic>> _categoryGrid = [
    {'name': 'Sarapan', 'count': '84 resep', 'icon': Icons.wb_twilight, 'filter': 'Sarapan'},
    {'name': 'Makan Siang', 'count': '152 resep', 'icon': Icons.wb_sunny, 'filter': 'Asian Food'},
    {'name': 'Makan Malam', 'count': '110 resep', 'icon': Icons.nightlight_round, 'filter': 'Western'},
    {'name': 'Minuman Segar', 'count': '67 resep', 'icon': Icons.local_bar, 'filter': 'Minuman'},
    {'name': 'Kue & Dessert', 'count': '95 resep', 'icon': Icons.cake, 'filter': 'Dessert'},
    {'name': 'Diet Sehat', 'count': '73 resep', 'icon': Icons.eco, 'filter': 'Japanese'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = widget.recipes.where((r) {
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.author.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(query));

      final matchesCat = _selectedCategory == null ||
          r.category.toLowerCase().contains(_selectedCategory!.toLowerCase()) ||
          r.title.toLowerCase().contains(_selectedCategory!.toLowerCase());

      return matchesQuery && matchesCat;
    }).toList();

    if (_activeTab == 'populer') {
      filtered.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    } else if (_activeTab == 'recook') {
      filtered.sort((a, b) => (b.recooks ?? '').compareTo(a.recooks ?? ''));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Search & Filter Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
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
                        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'Cari resep, bahan, atau koki...',
                          hintStyle: TextStyle(color: AppColors.secondary, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close, color: AppColors.secondary, size: 18),
                      )
                    else
                      GestureDetector(
                        onTap: () => widget.onShowToast?.call('Pencarian suara siap mendengarkan...'),
                        child: const Icon(Icons.mic, color: AppColors.secondary, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                });
                widget.onShowToast?.call('Filter eksplorasi direset');
              },
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.inverseSurface,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Trending Tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.primary, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'TREN:',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              ..._trendingTags.map((tag) {
                final clean = tag.replaceAll('#', '');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(tag),
                    onPressed: () {
                      _searchController.text = clean;
                      setState(() {});
                    },
                    backgroundColor: AppColors.surfaceContainer,
                    labelStyle: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Featured Collections Banners
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Koleksi Spesial', style: Theme.of(context).textTheme.headlineSmall),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                });
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildCollectionBanner(
                tag: 'Populer Minggu Ini',
                tagColor: AppColors.primaryContainer,
                title: 'Kreasi Western Food Otentik',
                subtitle: '18 menu gourmet resto bintang 5',
                image: MockImages.westernBanner,
                filterValue: 'Western',
              ),
              const SizedBox(width: 16),
              _buildCollectionBanner(
                tag: 'Inspirasi Weekend',
                tagColor: AppColors.tertiaryContainer,
                title: 'Sajian Hangat Meja Keluarga',
                subtitle: '24 olahan hidangan nusantara',
                image: MockImages.nusantaraBanner,
                filterValue: 'Asian',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 6-Tile Category Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kategori Resep', style: Theme.of(context).textTheme.headlineSmall),
            const Text('6 Kategori', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categoryGrid.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final cat = _categoryGrid[index];
            final isSelected = _selectedCategory == cat['filter'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : cat['filter'] as String;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryFixed.withValues(alpha: 0.5)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat['icon'] as IconData, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      cat['count'] as String,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        // Trending Recipes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Katalog Resep Tren', style: Theme.of(context).textTheme.headlineSmall),
                const Text(
                  'Dipilih khusus oleh komunitas koki rumahan',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                });
              },
              child: const Text(
                'Semua',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs: Terpopuler, Terbaru, Paling Banyak Di-recook
        Row(
          children: [
            _buildTrendTab('populer', 'Terpopuler'),
            const SizedBox(width: 8),
            _buildTrendTab('terbaru', 'Terbaru'),
            const SizedBox(width: 8),
            _buildTrendTab('recook', 'Paling Di-recook'),
          ],
        ),
        const SizedBox(height: 16),

        // Recipe Stack
        ...filtered.map((r) => _buildExploreRecipeCard(r)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCollectionBanner({
    required String tag,
    required Color tagColor,
    required String title,
    required String subtitle,
    required String image,
    required String filterValue,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                InkWell(
                  onTap: () {
                    _searchController.text = filterValue;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Eksplor',
                          style: TextStyle(
                            color: AppColors.inverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12, color: AppColors.inverseSurface),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppCachedImage(
            imageUrl: image,
            width: 100,
            height: 100,
            isCircle: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendTab(String id, String label) {
    final active = _activeTab == id;
    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.inverseSurface : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildExploreRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: category & likes & heart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recipe.category,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, color: AppColors.primaryContainer, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        recipe.likes,
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => widget.onToggleFavorite(recipe.id),
                icon: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite ? const Color(0xFFFF4D6D) : Colors.white70,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle row: Circular food plate + title & details
          Row(
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
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AppCachedImage(
                          imageUrl: recipe.authorAvatar ?? MockImages.chefKenjiAvatar,
                          width: 20,
                          height: 20,
                          isCircle: true,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recipe.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          recipe.time,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.repeat, color: AppColors.primaryFixedDim, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          recipe.recooks ?? '640 recook',
                          style: const TextStyle(color: AppColors.primaryFixedDim, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Action: Tingkat + Lihat Resep
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tingkat: ${recipe.difficulty}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              InkWell(
                onTap: () => widget.onSelectRecipe(recipe),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Resep',
                      style: TextStyle(
                        color: AppColors.primaryFixedDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.primaryFixedDim, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
