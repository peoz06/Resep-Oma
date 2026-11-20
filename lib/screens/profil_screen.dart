import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class ProfilScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String> onDeleteRecipe;
  final VoidCallback onNavigateToUpload;
  final ValueChanged<Recipe> onEditRecipe;
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToAdmin;
  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final bool isLoggedIn;
  final bool isAdmin;
  final String? userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final ValueChanged<String>? onShowToast;
  final bool darkMode;
  final ValueChanged<bool>? onToggleDarkMode;

  /// (nama, email, profil Firestore hasil penyimpanan — null bila tamu)
  final void Function(String name, String email, AppUser? updatedUser)?
      onUpdateProfile;

  const ProfilScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onDeleteRecipe,
    required this.onNavigateToUpload,
    required this.onEditRecipe,
    required this.onNavigateToFavorites,
    required this.onNavigateToAdmin,
    required this.onLogout,
    required this.onLogin,
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.userId,
    this.userName = 'Tamu',
    this.userEmail = 'guest@resepoma.id',
    this.userAvatar,
    this.onUpdateProfile,
    this.onShowToast,
    this.darkMode = false,
    this.onToggleDarkMode,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late String _name;
  late String _email;
  bool _sortLatest = true;

  @override
  void initState() {
    super.initState();
    _name = widget.isLoggedIn ? widget.userName : 'Pengguna Tamu';
    _email = widget.isLoggedIn ? widget.userEmail : 'Belum masuk akun';
  }

  @override
  void didUpdateWidget(covariant ProfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn ||
        widget.userName != oldWidget.userName ||
        widget.userEmail != oldWidget.userEmail) {
      _name = widget.isLoggedIn ? widget.userName : 'Pengguna Tamu';
      _email = widget.isLoggedIn ? widget.userEmail : 'Belum masuk akun';
    }
  }

  Future<void> _changeAvatar() async {
    if (!widget.isLoggedIn || widget.userId == null) {
      widget.onShowToast
          ?.call('Masuk akun terlebih dahulu untuk mengubah foto profil.');
      return;
    }
    final file = await StorageService.pickImage();
    if (file == null || !mounted) return;
    final uid = widget.userId!;

    widget.onShowToast?.call('Mengunggah foto profil...');
    late final String url;
    try {
      url = await StorageService.uploadImage(
        file,
        bucket: 'avatars',
        uid: uid,
      );
    } on ImageUploadException catch (e) {
      if (mounted) widget.onShowToast?.call(e.message);
      return;
    }

    if (!mounted) return;
    if (uid != widget.userId || uid != AuthService.firebaseUser?.uid) {
      widget.onShowToast?.call('Akun berubah saat upload. Foto tidak dipasang; hapus file lama secara manual.');
      return;
    }
    final res = await AuthService.updateProfile(avatar: url);
    if (!mounted || uid != widget.userId || uid != AuthService.firebaseUser?.uid) {
      return;
    }
    if (!res.ok || res.user == null) {
      widget.onShowToast?.call(
        'Foto sudah terunggah ke Supabase, tetapi profil gagal disimpan ke Firestore. '
        'File tetap tersimpan dan tidak dihapus. ${res.message}',
      );
      return;
    }
    widget.onUpdateProfile?.call(res.user!.name, res.user!.email, res.user);
    widget.onShowToast?.call(res.message.contains('resep lama')
        ? res.message : 'Foto profil berhasil diperbarui.');
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profil', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              const SizedBox(height: 10),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email')),
              if (widget.isLoggedIn)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changePasswordDialog();
                  },
                  child: const Text('Ubah Kata Sandi'),
                ),
            ],
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newName = nameCtrl.text.trim().isEmpty
                          ? _name
                          : nameCtrl.text.trim();
                      final newEmail = emailCtrl.text.trim().isEmpty
                          ? _email
                          : emailCtrl.text.trim();

                       AppUser? savedUser;
                       String? savedMessage;

                       // Simpan ke Firestore (jika user sudah login)
                       if (widget.isLoggedIn && widget.userId != null) {
                         final uid = widget.userId;
                         setDialogState(() => saving = true);
                         final res = await AuthService.updateProfile(
                           name: newName,
                           email: newEmail,
                         );
                         if (!mounted || !context.mounted ||
                             uid != widget.userId ||
                             uid != AuthService.firebaseUser?.uid) {
                           return;
                         }
                        if (!res.ok) {
                          setDialogState(() => saving = false);
                          widget.onShowToast?.call(
                            res.message.isEmpty
                                ? 'Gagal menyimpan profil.'
                                : res.message,
                          );
                          return;
                        }
                         savedUser = res.user;
                         savedMessage = res.message;
                      }

                       setState(() {
                         _name = savedUser?.name ?? newName;
                         _email = savedUser?.email ?? newEmail;
                       });
                       if (context.mounted) Navigator.pop(context);
                       widget.onUpdateProfile
                           ?.call(_name, _email, savedUser);
                       widget.onShowToast?.call(
                         widget.isLoggedIn
                             ? savedMessage ?? 'Profil berhasil disimpan ke database!'
                            : 'Nama berhasil diubah menjadi "$newName" (mode tamu, tidak tersimpan).',
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ubah Kata Sandi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: oldCtrl, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kata sandi lama')),
                TextField(controller: newCtrl, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kata sandi baru')),
                TextField(controller: confirmCtrl, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Konfirmasi kata sandi baru')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  widget.onShowToast?.call('Konfirmasi kata sandi baru tidak sesuai.');
                  return;
                }
                setDialogState(() => saving = true);
                final res = await AuthService.changePassword(
                  oldPassword: oldCtrl.text, newPassword: newCtrl.text,
                );
                if (!dialogContext.mounted) return;
                setDialogState(() => saving = false);
                widget.onShowToast?.call(res.message);
                if (res.ok) Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myRecipes = widget.isLoggedIn
        ? widget.recipes.where((r) => r.isMyRecipe).toList()
        : <Recipe>[];

    if (!_sortLatest) {
      myRecipes.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Profile Header
        Row(
          children: [
            if (widget.isLoggedIn)
              GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    widget.userAvatar?.isNotEmpty == true
                        ? AppCachedImage(
                            imageUrl: widget.userAvatar!, width: 72,
                            height: 72, isCircle: true)
                        : const CircleAvatar(radius: 36,
                            child: Icon(Icons.person_outline, size: 36)),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.surface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    size: 36, color: AppColors.secondary),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(_email,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            if (widget.isAdmin)
              IconButton(
                onPressed: widget.onNavigateToAdmin,
                icon: const Icon(Icons.settings, color: AppColors.onSurface),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Action Button: Edit Profil (if logged in) or Masuk / Daftar Akun (if guest)
        if (widget.isLoggedIn)
          OutlinedButton.icon(
            onPressed: _editProfileDialog,
            icon: const Icon(Icons.edit, size: 16, color: AppColors.onSurface),
            label: const Text('Edit Profil',
                style: TextStyle(
                    color: AppColors.onSurface, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: widget.onLogin,
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Masuk / Daftar'),
        ),
        if (widget.isLoggedIn && widget.userId != null &&
            AuthService.firebaseUser?.emailVerified == false) ...[
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Email belum terverifikasi'),
            subtitle: Text(widget.userEmail),
            trailing: TextButton(onPressed: () async {
              final result = await AuthService.sendVerificationEmail();
              widget.onShowToast?.call(result.message);
              if (mounted) setState(() {});
            }, child: const Text('Kirim tautan')),
          ),
        ],
        const SizedBox(height: 14),

        // Stats Box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.isLoggedIn ? '${myRecipes.length}' : '0',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const Text('Resep Saya',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12)),
              if (widget.isLoggedIn)
                Text('${myRecipes.fold<int>(0, (total, recipe) => total + recipe.likesCount)} suka',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
        if (widget.isLoggedIn && widget.userId != null && RecipeService.isReady)
          FutureBuilder<(int, int)>(
            future: RecipeService.followCounts(widget.userId!),
            builder: (context, snap) => snap.hasData
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('${snap.data!.$1} pengikut • ${snap.data!.$2} mengikuti',
                        textAlign: TextAlign.center))
                : const SizedBox.shrink(),
          ),
        if (widget.isLoggedIn && widget.userId != null && RecipeService.isReady)
          FutureBuilder<Map<String, dynamic>?>(
            future: RecipeService.fetchDraft(widget.userId!),
            builder: (context, snap) => snap.hasData && snap.data != null
                ? Card(child: ListTile(
                    title: Text('Draf: ${snap.data!['title']}'),
                    subtitle: const Text('Foto perlu dipilih ulang sebelum terbit.'),
                    onTap: widget.onNavigateToUpload,
                    trailing: IconButton(tooltip: 'Hapus draf',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(context: context,
                          builder: (dialog) => AlertDialog(
                            title: const Text('Hapus draf?'),
                            content: const Text('Teks draf yang tersimpan akan hilang permanen.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dialog, false),
                                  child: const Text('Batal')),
                              TextButton(onPressed: () => Navigator.pop(dialog, true),
                                  child: const Text('Hapus')),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        final result = await RecipeService.deleteDraft(widget.userId!);
                        if (!mounted) return;
                        widget.onShowToast?.call(result.message);
                        if (result.ok) setState(() {});
                      },
                    ),
                  ))
                : const SizedBox.shrink(),
          ),
        const SizedBox(height: 18),

        // Buat Resep Promo Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryContainer, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.soup_kitchen,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Punya kreasi baru hari ini?',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    Text(
                      'Unggah foto & langkah memasakmu',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToUpload,
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text(
                  'Buat Resep',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Active Recipes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Resep Publik',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${myRecipes.length}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (widget.isLoggedIn)
              InkWell(
                onTap: () => setState(() => _sortLatest = !_sortLatest),
                child: Row(
                  children: [
                    Text(_sortLatest ? 'Terbaru' : 'Terpopuler',
                        style: const TextStyle(fontSize: 12)),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (widget.isLoggedIn && myRecipes.isNotEmpty) ...[
          ...myRecipes.map((recipe) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  AppCachedImage(
                    imageUrl: recipe.image,
                    width: 60,
                    height: 60,
                    isCircle: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                recipe.category,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${recipe.publishedAgo}',
                              style: const TextStyle(
                                  color: AppColors.secondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          recipe.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEditRecipe(recipe),
                    tooltip: 'Edit resep',
                    icon: const Icon(Icons.edit,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ),
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(context: context,
                        builder: (dialog) => AlertDialog(
                          title: const Text('Hapus resep?'),
                          content: Text('"${recipe.title}" akan dihapus permanen. Foto yang sudah diunggah tetap tersimpan.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (confirmed == true) widget.onDeleteRecipe(recipe.id);
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                widget.isLoggedIn
                    ? 'Anda belum memiliki resep yang diunggah.'
                    : 'Masuk akun untuk melihat dan mengelola resep kreasi Anda.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.secondary, fontSize: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Account Settings List
        const Text(
          'PENGATURAN AKUN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: AppColors.surfaceContainerLowest,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.bookmark,
                    label: 'Resep Favorit / Disimpan',
                    onTap: widget.onNavigateToFavorites,
                  ),
                  if (widget.isAdmin) ...[
                    const Divider(height: 1, indent: 56),
                    _buildSettingTile(
                      icon: Icons.manage_accounts,
                      label: 'Pengaturan Akun & Panel Admin',
                      onTap: widget.onNavigateToAdmin,
                    ),
                  ],
                  const Divider(height: 1, indent: 56),
                   if (widget.onToggleDarkMode != null) ...[
                     SwitchListTile(
                       title: const Text('Mode Gelap'),
                       secondary: const Icon(Icons.dark_mode_outlined),
                       value: widget.darkMode,
                       onChanged: widget.onToggleDarkMode,
                     ),
                     const Divider(height: 1, indent: 56),
                   ],
                  if (widget.isLoggedIn)
                    _buildSettingTile(
                      icon: Icons.logout,
                      label: 'Keluar',
                      color: AppColors.primary,
                      onTap: widget.onLogout,
                    )
                  else
                    _buildSettingTile(
                      icon: Icons.login,
                      label: 'Masuk / Registrasi Akun',
                      color: AppColors.primary,
                      onTap: widget.onLogin,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final tileColor =
        (color ?? AppColors.onSurfaceVariant).withValues(alpha: 0.1);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: tileColor,
        child: Icon(icon, color: color ?? AppColors.onSurfaceVariant, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.onSurfaceVariant),
    );
  }
}
