import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_fridge_sheet.dart';
import '../widgets/app_cached_image.dart';
import '../widgets/notifications_sheet.dart';

class BerandaScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String> onToggleFavorite;
  final VoidCallback onNavigateToExplore;
  final String userName;

  const BerandaScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onToggleFavorite,
    required this.onNavigateToExplore,
    this.userName = 'Tamu',
  });

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  String _selectedCategory = 'Populer';
  final List<String> _categories = ['Populer', 'Vegan', 'Pasta', 'Dessert', 'Seafood'];

  @override
  Widget build(BuildContext context) {
    final recommended = widget.recipes.take(3).toList();

    // Filter berbasis data (berlaku untuk resep database maupun data contoh).
    late final List<Recipe> showcase;
    if (_selectedCategory == 'Populer') {
      // Populer: urutkan dari jumlah suka terbanyak, tampilkan 6 teratas.
      final byLikes = [...widget.recipes]
        ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
      showcase = byLikes.take(6).toList();
    } else {
      showcase = widget.recipes.where((r) {
        if (_selectedCategory == 'Vegan') {
          return r.filterKey.contains('healthy') ||
              r.filterKey.contains('diet') ||
              r.category.toLowerCase().contains('asian');
        }
        if (_selectedCategory == 'Pasta') {
          final title = r.title.toLowerCase();
          return r.filterKey.contains('pasta') ||
              title.contains('pasta') ||
              title.contains('spaghetti') ||
              title.contains('carbonara') ||
              title.contains('fettuccine') ||
              title.contains('linguine') ||
              title.contains('penne');
        }
        if (_selectedCategory == 'Dessert') {
          return r.category.toLowerCase().contains('dessert');
        }
        if (_selectedCategory == 'Seafood') {
          final title = r.title.toLowerCase();
          return title.contains('salmon') ||
              title.contains('nasi lemak') ||
              title.contains('udang') ||
              title.contains('cumi') ||
              title.contains('tuna');
        }
        return true;
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Top Greeting & Icons Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo & Selamat Memasak!',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Welcome, ${widget.userName}!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: widget.onNavigateToExplore,
                  icon: const Icon(Icons.search, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    foregroundColor: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => NotificationsSheet.show(context),
                      icon: const Icon(Icons.notifications_outlined, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        foregroundColor: AppColors.onSurface,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section 1: Recommended For You
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Recommended for You',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onNavigateToExplore,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel of Recommended Cards
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recommended.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final recipe = recommended[index];
              return _buildRecommendedCard(recipe);
            },
          ),
        ),
        const SizedBox(height: 28),

        // Section 2: Categories Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: widget.onNavigateToExplore,
              child: const Text(
                'See All',
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

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: _categories.map((cat) {
              final isActive = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isActive,
                  onSelected: (val) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  backgroundColor: AppColors.surfaceContainer,
                  selectedColor: AppColors.inverseSurface,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Section 3: Popular Recipe Showcase (Tri-Card Row)
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: showcase.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = showcase[index];
              return _buildShowcaseCard(item);
            },
          ),
        ),
        const SizedBox(height: 24),

        // Interactive AI Fridge Matching Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bingung mau masak apa?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kocok bahan di kulkasmu sekarang!',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => AiFridgeSheet.show(
                  context,
                  recipes: widget.recipes,
                  onSelectRecipe: widget.onSelectRecipe,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Coba AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecommendedCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => widget.onSelectRecipe(recipe),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Favorite Toggle
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => widget.onToggleFavorite(recipe.id),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: recipe.isFavorite ? const Color(0xFFFF4D6D) : Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Circular Food Plate
            Center(
              child: Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AppCachedImage(
                  imageUrl: recipe.image,
                  isCircle: true,
                ),
              ),
            ),

            // Meta Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up, color: AppColors.primaryFixedDim, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          recipe.likes,
                          style: const TextStyle(
                            color: AppColors.primaryFixedDim,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseCard(Recipe item) {
    return GestureDetector(
      onTap: () => widget.onSelectRecipe(item),
      child: Container(
        width: 154,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: AppColors.primaryFixedDim, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      item.likes,
                      style: const TextStyle(
                        color: AppColors.primaryFixedDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => widget.onToggleFavorite(item.id),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: item.isFavorite ? const Color(0xFFFF4D6D) : Colors.white60,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: AppCachedImage(
                imageUrl: item.image,
                width: 78,
                height: 78,
                isCircle: true,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
