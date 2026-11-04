import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe_model.dart';
import '../services/firebase_service.dart';
import '../services/recipe_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class UnggahResepScreen extends StatefulWidget {
  final VoidCallback onPublishRecipe;
  final String? userId;
  final String userName;
  final String? userAvatar;
  final ValueChanged<String>? onShowToast;

  const UnggahResepScreen({
    super.key,
    required this.onPublishRecipe,
    this.userId,
    this.userName = 'Anonim',
    this.userAvatar,
    this.onShowToast,
  });

  @override
  State<UnggahResepScreen> createState() => _UnggahResepScreenState();
}

class _UnggahResepScreenState extends State<UnggahResepScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Salmon Mentai Rice Bowl Spesial');
  final TextEditingController _descController = TextEditingController(
      text:
          'Perpaduan salmon panggang juicy dengan saus mentai gurih-creamy yang ditorch hingga wangi smoky menggugah selera.');
  final TextEditingController _timeController = TextEditingController(text: '30 Menit');
  final TextEditingController _servingsController = TextEditingController(text: '2-3 Porsi');
  final TextEditingController _difficultyController = TextEditingController(text: 'Sedang');

  String _selectedCategory = 'Asian Food';
  final List<String> _categories = ['Asian Food', 'Western', 'Healthy Diet', 'Dessert', 'Nusantara'];

  String _heroPhoto = MockImages.salmonMentaiHero;
  List<String> _subPhotos = [MockImages.salmonMentaiSub1, MockImages.salmonMentaiSub2];

  final List<Ingredient> _ingredients = [
    Ingredient(id: '1', name: 'Beras Jepang / Japonica Rice', amount: '300 gram'),
    Ingredient(id: '2', name: 'Fillet Ikan Salmon Segar', amount: '200 gram (potong dadu)'),
    Ingredient(id: '3', name: 'Mayones Jepang (Kewpie) & Tobiko', amount: '4 sdm mayo + 2 sdm tobiko'),
  ];

  final List<CookingStep> _steps = [
    CookingStep(
      id: '1',
      title: 'Menyiapkan Nasi & Racikan Salmon',
      description:
          'Masak nasi Jepang hingga pulen hangat, campurkan dengan taburan furikake dan minyak wijen. Marinasi potongan salmon dengan kecap asin Jepang & saus tiram.',
    ),
    CookingStep(
      id: '2',
      title: 'Perakitan & Blow Torch Mentai',
      description:
          'Tata nasi dalam mangkuk tahan panas, susun salmon di atasnya, lapisi dengan saus mentai tebal. Gunakan kitchen blow torch hingga berkaramel wangi smoky.',
    ),
  ];

  bool _isPublishing = false;

  Future<void> _pickHeroPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final file = await StorageService.pickImage(source: source);
    if (file == null) return;
    setState(() => _heroPhoto = file.path);
    widget.onShowToast?.call('Foto utama resep berhasil diperbarui');
  }

  Future<void> _pickSubPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final file = await StorageService.pickImage(source: source);
    if (file == null) return;
    setState(() {
      if (_subPhotos.length >= 2) {
        _subPhotos[0] = file.path;
      } else {
        _subPhotos = [..._subPhotos, file.path];
      }
    });
    widget.onShowToast?.call('Foto pendamping resep diperbarui');
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Ambil dengan Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }

  /// Kembalikan URL siap pakai: foto http dibiarkan, foto lokal diunggah
  /// ke Firebase Storage. null = unggah gagal.
  Future<String?> _resolvePhoto(String photo, String folder) async {
    if (photo.isEmpty) return null;
    if (AppCachedImage.isNetworkSource(photo)) return photo;
    return StorageService.uploadFilePath(photo, folder: folder);
  }

  void _addIngredientDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Bahan Masakan', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Bahan (mis. Rumput Laut)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Takaran (mis. 2 lembar)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _ingredients.add(
                    Ingredient(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      amount: amountCtrl.text.trim().isEmpty ? 'Secukupnya' : amountCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(context);
                widget.onShowToast?.call('Bahan masakan ditambahkan');
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addStepDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Langkah Memasak', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul Langkah (mis. Penyajian)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Instruksi Langkah'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descCtrl.text.trim().isNotEmpty || titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _steps.add(
                    CookingStep(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim().isEmpty
                          ? 'Tahap Memasak ${_steps.length + 1}'
                          : titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? 'Lanjutkan proses memasak.'
                          : descCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(context);
                widget.onShowToast?.call('Langkah baru ditambahkan');
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    if (_titleController.text.trim().isEmpty) {
      widget.onShowToast?.call('Mohon isi nama resep terlebih dahulu');
      return;
    }
    if (widget.userId == null) {
      widget.onShowToast?.call('Masuk akun terlebih dahulu untuk menerbitkan resep.');
      return;
    }
    if (!RecipeService.isReady) {
      widget.onShowToast?.call(FirebaseService.humanError);
      return;
    }
    if (_isPublishing) return;

    setState(() => _isPublishing = true);

    // 1) Unggah foto lokal ke Firebase Storage.
    final heroUrl = await _resolvePhoto(_heroPhoto, 'recipes/hero');
    if (heroUrl == null) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      widget.onShowToast?.call('Gagal mengunggah foto utama. Periksa koneksi internet Anda.');
      return;
    }

    final galleryUrls = <String>[];
    for (final photo in _subPhotos) {
      final url = await _resolvePhoto(photo, 'recipes/gallery');
      if (url != null) galleryUrls.add(url);
    }

    // 2) Simpan dokumen resep ke Firestore.
    final res = await RecipeService.createRecipe(
      authorId: widget.userId!,
      authorName: widget.userName,
      authorAvatar: widget.userAvatar,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      cookTime: _timeController.text.trim(),
      servings: _servingsController.text.trim(),
      difficulty: _difficultyController.text.trim(),
      image: heroUrl,
      images: galleryUrls,
      ingredients: _ingredients
          .map((i) => {'name': i.name, 'amount': i.amount})
          .toList(),
      steps: _steps
          .map((s) => {'title': s.title, 'description': s.description})
          .toList(),
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (res.ok) {
      widget.onPublishRecipe();
      widget.onShowToast?.call(
        'Resep "${_titleController.text.trim()}" berhasil dipublikasikan ke database! (Kode: ${res.code ?? ''})',
      );
      // Bersihkan form
      _titleController.clear();
      _descController.clear();
      setState(() {
        _ingredients.clear();
        _steps.clear();
      });
    } else {
      widget.onShowToast?.call(
        res.message.isEmpty ? 'Gagal menerbitkan resep. Coba lagi.' : res.message,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    _difficultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Intro Banner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'KREASI DAPUR',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Upload Resep', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, color: AppColors.onSurfaceVariant, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Bagikan kelezatan dan rahasia racikan bumbu spesialmu ke komunitas kuliner.',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Hero Photo Upload Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.inverseSurface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_a_photo, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'FOTO UTAMA RESEP',
                        style: TextStyle(
                          color: AppColors.primaryFixedDim,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Maks. 3 Foto',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Platter Avatar
              GestureDetector(
                onTap: _pickHeroPhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Colors.white24],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: AppCachedImage(
                        imageUrl: _heroPhoto,
                        isCircle: true,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: AppColors.primary, size: 16),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Resolusi Tinggi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Thumbnail row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._subPhotos.map((photo) {
                    return GestureDetector(
                      onTap: () {
                        final prev = _heroPhoto;
                        setState(() {
                          _heroPhoto = photo;
                          _subPhotos = _subPhotos.map((p) => p == photo ? prev : p).toList();
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: AppCachedImage(
                          imageUrl: photo,
                          isCircle: true,
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _pickSubPhoto,
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Format JPG, PNG atau WebP (Rasio 1:1 direkomendasikan)',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Detail Resep Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
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
                children: [
                  const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Detail Resep', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nama Resep *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${_titleController.text.length}/60',
                    style: const TextStyle(color: AppColors.outline, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                maxLength: 60,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Misal: Nasi Lemak Sambal Sotong'),
              ),
              const SizedBox(height: 14),

              // Description Field
              const Text('Deskripsi Singkat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ceritakan keistimewaan rasa atau momen yang pas untuk resep ini...',
                ),
              ),
              const SizedBox(height: 16),

              // Category Pills
              const Text('Kategori Masakan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final active = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: active,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
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
              const SizedBox(height: 18),

              // Triple Metrics
              Row(
                children: [
                  _buildMetricInput('Waktu', Icons.timer, AppColors.primary, _timeController),
                  const SizedBox(width: 8),
                  _buildMetricInput('Porsi', Icons.group, AppColors.tertiary, _servingsController),
                  const SizedBox(width: 8),
                  _buildMetricInput(
                      'Tingkat', Icons.equalizer, AppColors.primaryContainer, _difficultyController),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bahan-Bahan Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
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
                      Text('Bahan-Bahan', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_ingredients.length} Bahan',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ..._ingredients.map((ing) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator, color: AppColors.outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              ing.amount,
                              style: const TextStyle(color: AppColors.primary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _ingredients.remove(ing));
                        },
                        icon: const Icon(Icons.close, color: AppColors.outline, size: 18),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _addIngredientDialog,
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 18),
                label: const Text(
                  'Tambah Bahan Masakan',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: AppColors.primaryFixed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Langkah Memasak Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
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
                      const Icon(Icons.format_list_numbered, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Langkah Memasak', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Text(
                    '${_steps.length} Tahapan',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ..._steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step.description,
                                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _addStepDialog,
                icon: const Icon(Icons.add_task, color: AppColors.onSurfaceVariant, size: 18),
                label: const Text(
                  'Tambah Langkah Baru',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: AppColors.surfaceContainerHighest),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Primary Publish CTA
        ElevatedButton(
          onPressed: _isPublishing ? null : _handlePublish,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 4,
          ),
          child: _isPublishing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Terbitkan Resep Sekarang',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetricInput(
      String label, IconData icon, Color color, TextEditingController ctrl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
            TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
