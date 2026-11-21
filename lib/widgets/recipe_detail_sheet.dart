import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import 'app_cached_image.dart';

class RecipeDetailSheet extends StatefulWidget {
  final Recipe recipe;
  final Future<bool?> Function() onToggleFavorite;
  final ValueChanged<String>? onShowToast;
  final String? currentUserId;
  final String? currentUserName;
  final VoidCallback? onRecipeChanged;

  const RecipeDetailSheet({
    super.key,
    required this.recipe,
    required this.onToggleFavorite,
    this.onShowToast,
    this.currentUserId,
    this.currentUserName,
    this.onRecipeChanged,
  });

  static void show(
    BuildContext context, {
    required Recipe recipe,
    required Future<bool?> Function() onToggleFavorite,
    ValueChanged<String>? onShowToast,
    String? currentUserId,
    String? currentUserName,
    VoidCallback? onRecipeChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeDetailSheet(
        recipe: recipe,
        onToggleFavorite: onToggleFavorite,
        onShowToast: onShowToast,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        onRecipeChanged: onRecipeChanged,
      ),
    );
  }

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  final Set<String> _checkedIngredients = {};
  bool _submittingReport = false;
  bool _working = false;
  bool? _following;
  late Future<List<Map<String, dynamic>>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = RecipeService.fetchComments(widget.recipe.id);
    final uid = widget.currentUserId;
    if (uid != null && widget.recipe.authorId.isNotEmpty &&
        uid != widget.recipe.authorId) {
      RecipeService.isFollowing(uid, widget.recipe.authorId).then((value) {
        if (mounted) setState(() => _following = value);
      }).catchError((Object _) {});
    }
  }

  Future<void> _toggleLike() async {
    final uid = widget.currentUserId;
    if (uid == null) {
      widget.onShowToast?.call('Masuk akun untuk menyukai resep.');
      return;
    }
    if (_working) return;
    setState(() => _working = true);
    final liked = await RecipeService.toggleLike(uid, widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (liked != null) widget.recipe.isLiked = liked;
    });
    if (liked == null) {
      widget.onShowToast?.call('Gagal memperbarui suka. Periksa koneksi.');
    } else {
      widget.onRecipeChanged?.call();
    }
  }

  Future<void> _markRecook() async {
    final uid = widget.currentUserId;
    if (uid == null) {
      widget.onShowToast?.call('Masuk akun untuk menandai recook.');
      return;
    }
    if (_working) return;
    setState(() => _working = true);
    final result = await RecipeService.markRecook(uid, widget.recipe.id);
    if (!mounted) return;
    setState(() => _working = false);
    if (result.ok) {
      widget.onRecipeChanged?.call();
    }
    widget.onShowToast?.call(result.message);
  }

  Future<void> _toggleFollow() async {
    final uid = widget.currentUserId;
    if (uid == null) {
      widget.onShowToast?.call('Masuk akun untuk mengikuti koki.');
      return;
    }
    if (_working) return;
    setState(() => _working = true);
    final following = await RecipeService.toggleFollow(uid, widget.recipe.authorId);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (following != null) _following = following;
    });
    widget.onShowToast?.call(following == null
        ? 'Gagal memperbarui daftar koki yang diikuti.'
        : following ? 'Koki diikuti.' : 'Berhenti mengikuti koki.');
  }

  Future<void> _writeReview() async {
    if (widget.currentUserId == null) {
      widget.onShowToast?.call('Masuk akun untuk menulis ulasan.');
      return;
    }
    final text = TextEditingController();
    var rating = 5;
    final input = await showDialog<(String, int)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Tulis Ulasan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(children: [for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: '$star bintang',
                onPressed: () => update(() => rating = star),
                icon: Icon(star <= rating ? Icons.star : Icons.star_border,
                    color: AppColors.primary),
              )]),
            TextField(controller: text, maxLength: 500, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ulasan resep')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Batal')),
            TextButton(onPressed: () {
              if (text.text.trim().isNotEmpty) Navigator.pop(dialog, (text.text.trim(), rating));
            }, child: const Text('Kirim')),
          ],
        ),
      ),
    );
    text.dispose();
    if (input == null || !mounted) return;
    final result = await RecipeService.addComment(
      uid: widget.currentUserId!, recipeId: widget.recipe.id,
      text: input.$1, rating: input.$2,
    );
    if (!mounted) return;
    widget.onShowToast?.call(result.message);
    if (result.ok) setState(() => _comments = RecipeService.fetchComments(widget.recipe.id));
  }

  Future<void> _reportDialog() async {
    final reasonCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Resep', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resep: ${widget.recipe.title}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jelaskan masalah resep ini (bahan salah, foto tidak sesuai, dsb):',
              style: TextStyle(color: AppColors.secondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tuliskan alasan laporan Anda...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _submittingReport
                ? null
                : () async {
                    if (_submittingReport) return;
                    final reason = reasonCtrl.text.trim();
                    if (reason.isEmpty) {
                      widget.onShowToast?.call('Mohon isi alasan laporan.');
                      return;
                    }
                    if (widget.currentUserId == null) {
                      Navigator.pop(context);
                      widget.onShowToast?.call('Masuk akun terlebih dahulu untuk melaporkan resep.');
                      return;
                    }
                    setState(() => _submittingReport = true);

                    if (!RecipeService.isReady) {
                      setState(() => _submittingReport = false);
                      if (context.mounted) Navigator.pop(context);
                      widget.onShowToast?.call(
                        'Laporan hanya tersedia saat terhubung ke database. Silakan coba lagi.',
                      );
                      return;
                    }

                    final res = await RecipeService.submitReport(
                      reporterId: widget.currentUserId!,
                      recipeId: widget.recipe.id,
                      recipeTitle: widget.recipe.title,
                      reason: reason,
                    );

                    if (!mounted) return;
                    setState(() => _submittingReport = false);
                    if (context.mounted) Navigator.pop(context);
                    widget.onShowToast?.call(
                      res.message.isEmpty ? 'Gagal mengirim laporan.' : res.message,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _submittingReport
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kirim Laporan'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Dark Hero Platter Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.inverseSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Grab Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Top Action Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recipe.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final favorite = await widget.onToggleFavorite();
                            if (mounted && favorite != null) {
                              setState(() => recipe.isFavorite = favorite);
                            }
                          },
                          icon: Icon(
                            recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: recipe.isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
                          ),
                          tooltip: 'Simpan ke favorit',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        IconButton(
                          onPressed: _working ? null : _toggleLike,
                          icon: Icon(recipe.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: recipe.isLiked ? AppColors.primaryFixedDim : Colors.white),
                          tooltip: 'Suka',
                        ),
                        IconButton(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(
                              text: '${recipe.title} — oleh ${recipe.author}\n'
                                  'Bahan: ${recipe.ingredients.map((i) => '${i.name} ${i.amount}').join(', ')}\n'
                                  'Kode resep: ${recipe.code}',
                            ));
                            widget.onShowToast?.call('Ringkasan resep disalin. Siap dibagikan.');
                          },
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          tooltip: 'Salin untuk dibagikan',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Circular Platter Image
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Colors.white24],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AppCachedImage(
                          imageUrl: recipe.image,
                          isCircle: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Author
                    Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (recipe.verified)
                      const Text('✓ Terverifikasi oleh admin',
                          style: TextStyle(color: AppColors.primaryFixedDim,
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'oleh ${recipe.author} • ${recipe.publishedAgo}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (widget.currentUserId != recipe.authorId &&
                        recipe.authorId.isNotEmpty)
                      TextButton.icon(
                        onPressed: _working ? null : _toggleFollow,
                        icon: Icon(_following == true ? Icons.person_remove : Icons.person_add,
                            color: Colors.white),
                        label: Text(_following == true ? 'Mengikuti' : 'Ikuti koki',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    const SizedBox(height: 16),

                    // Quick Triple Metric Bar
                    Row(
                      children: [
                        _buildHeroMetric('Waktu', recipe.time),
                        const SizedBox(width: 8),
                        _buildHeroMetric('Porsi', recipe.servings),
                        const SizedBox(width: 8),
                        _buildHeroMetric('Tingkat', recipe.difficulty),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Body (Ingredients & Steps)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Description
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    if (recipe.secondaryImages?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      SizedBox(height: 100, child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipe.secondaryImages!.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => AppCachedImage(
                          imageUrl: recipe.secondaryImages![index],
                          width: 100, height: 100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )),
                    ],
                    const SizedBox(height: 20),

                    // Ingredients Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.kitchen, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bahan-Bahan',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${recipe.ingredients.length} Bahan',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...recipe.ingredients.map((ing) {
                            final isChecked = _checkedIngredients.contains(ing.id);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    _checkedIngredients.remove(ing.id);
                                  } else {
                                    _checkedIngredients.add(ing.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isChecked ? AppColors.primary : AppColors.outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ing.name,
                                        style: TextStyle(
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: isChecked
                                              ? AppColors.secondary
                                              : AppColors.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ing.amount,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cooking Steps Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_list_numbered,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Langkah Memasak',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                              Text(
                                '${recipe.steps.length} Tahapan',
                                style: const TextStyle(color: AppColors.secondary, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...recipe.steps.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final step = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            step.description,
                                            style: const TextStyle(
                                              color: AppColors.onSurfaceVariant,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cook & Recook Action CTA
                    ElevatedButton.icon(
                      onPressed: _working ? null : _markRecook,
                      icon: const Icon(Icons.soup_kitchen, color: Colors.white),
                      label: const Text(
                        'Tandai sudah memasak (Recook)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(children: [
                      Expanded(child: Text('Ulasan & Rating',
                          style: Theme.of(context).textTheme.headlineSmall)),
                      TextButton.icon(onPressed: _writeReview,
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Tulis ulasan')),
                    ]),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _comments,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(snapshot.hasError
                              ? 'Gagal memuat ulasan.' : 'Memuat ulasan...');
                        }
                        final comments = snapshot.data!;
                        if (comments.isEmpty) {
                          return const Text('Belum ada ulasan.');
                        }
                        final average = comments.fold<int>(0, (n, item) =>
                            n + (item['rating'] as num).toInt()) / comments.length;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('★ ${average.toStringAsFixed(1)} / 5 • ${comments.length} ulasan terbaru'),
                          const Text('Rata-rata dari maksimal 20 ulasan terbaru, bukan seluruh ulasan.'),
                          for (final item in comments) ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item['authorName']} • ${item['rating']} ★'),
                            subtitle: Text('${item['text']}'),
                            trailing: item['authorId'] == widget.currentUserId
                                ? IconButton(tooltip: 'Hapus ulasan',
                                    onPressed: () async {
                                      final result = await RecipeService.deleteComment(
                                          widget.recipe.id, item['id'] as String);
                                      if (!mounted) return;
                                      widget.onShowToast?.call(result.message);
                                      if (result.ok) {
                                        setState(() => _comments =
                                            RecipeService.fetchComments(widget.recipe.id));
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline))
                                : null,
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Report Recipe Link
                    TextButton.icon(
                      onPressed: _reportDialog,
                      icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                      label: const Text(
                        'Laporkan Resep ini',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
