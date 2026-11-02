import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class ProfilScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String> onDeleteRecipe;
  final VoidCallback onNavigateToUpload;
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToAdmin;
  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final bool isLoggedIn;
  final int? userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final ValueChanged<String>? onShowToast;
  final void Function(String newName, String newEmail)? onUpdateProfile;

  const ProfilScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onDeleteRecipe,
    required this.onNavigateToUpload,
    required this.onNavigateToFavorites,
    required this.onNavigateToAdmin,
    required this.onLogout,
    required this.onLogin,
    this.isLoggedIn = false,
    this.userId,
    this.userName = 'Tamu',
    this.userEmail = 'guest@resepoma.id',
    this.userAvatar,
    this.onUpdateProfile,
    this.onShowToast,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late String _name;
  late String _email;
  late String _handle;
  bool _sortLatest = true;

  @override
  void initState() {
    super.initState();
    _name = widget.isLoggedIn ? widget.userName : 'Pengguna Tamu';
    _email = widget.isLoggedIn ? widget.userEmail : 'Belum masuk akun';
    _handle = widget.isLoggedIn ? '@${widget.userName.toLowerCase().replaceAll(' ', '')}' : 'Mode Tamu';
  }

  @override
  void didUpdateWidget(covariant ProfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn ||
        widget.userName != oldWidget.userName ||
        widget.userEmail != oldWidget.userEmail) {
      _name = widget.isLoggedIn ? widget.userName : 'Pengguna Tamu';
      _email = widget.isLoggedIn ? widget.userEmail : 'Belum masuk akun';
      _handle = widget.isLoggedIn ? '@${widget.userName.toLowerCase().replaceAll(' ', '')}' : 'Mode Tamu';
    }
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final handleCtrl = TextEditingController(text: _handle);
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Profil', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: handleCtrl, decoration: const InputDecoration(labelText: 'Username')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    final newName = nameCtrl.text.trim().isEmpty ? _name : nameCtrl.text.trim();
                    final newEmail = emailCtrl.text.trim().isEmpty ? _email : emailCtrl.text.trim();
                    final newHandle = handleCtrl.text.trim().isEmpty ? _handle : handleCtrl.text.trim();

                    // Simpan ke database MySQL (jika user sudah login)
                    if (widget.isLoggedIn && widget.userId != null) {
                      setDialogState(() => saving = true);
                      final res = await ApiService.updateUserAction(
                        id: widget.userId!,
                        action: 'update_profile',
                        name: newName,
                        email: newEmail,
                      );
                      if (!context.mounted) return;
                      if (res['status'] != true) {
                        setDialogState(() => saving = false);
                        widget.onShowToast?.call(
                          res['message']?.toString() ?? 'Gagal menyimpan profil.',
                        );
                        return;
                      }
                    }

                    setState(() {
                      _name = newName;
                      _email = newEmail;
                      _handle = newHandle;
                    });
                    Navigator.pop(context);
                    widget.onUpdateProfile?.call(newName, newEmail);
                    widget.onShowToast?.call(
                      widget.isLoggedIn
                          ? 'Profil berhasil disimpan ke database!'
                          : 'Nama berhasil diubah menjadi "$newName" (mode tamu, tidak tersimpan).',
                    );
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan'),
          ),
        ],
        ),
      ),
    );
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
              AppCachedImage(
                imageUrl: (widget.userAvatar != null && widget.userAvatar!.isNotEmpty)
                    ? widget.userAvatar!
                    : MockImages.annaRobertsAvatar,
                width: 72,
                height: 72,
                isCircle: true,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 36, color: AppColors.secondary),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: Theme.of(context).textTheme.headlineMedium),
                  Text(_email, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  Text(_handle, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onNavigateToAdmin,
              icon: const Icon(Icons.settings, color: AppColors.onSurface),
              style: IconButton.styleFrom(backgroundColor: AppColors.surfaceContainer),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Action Button: Edit Profil (if logged in) or Masuk / Daftar Akun (if guest)
        if (widget.isLoggedIn)
          OutlinedButton.icon(
            onPressed: _editProfileDialog,
            icon: const Icon(Icons.edit, size: 16, color: AppColors.onSurface),
            label: const Text('Edit Profil', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onLogin,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _editProfileDialog,
                icon: const Icon(Icons.edit, size: 16, color: AppColors.onSurface),
                label: const Text('Ganti Nama', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),

        // Stats Box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
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
              const Text('Resep Saya', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
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
                child: const Icon(Icons.soup_kitchen, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Punya kreasi baru hari ini?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const Text('Resep Publik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${myRecipes.length}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (widget.isLoggedIn)
              InkWell(
                onTap: () => setState(() => _sortLatest = !_sortLatest),
                child: Row(
                  children: [
                    Text(_sortLatest ? 'Terbaru' : 'Terpopuler', style: const TextStyle(fontSize: 12)),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                recipe.category,
                                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${recipe.publishedAgo}',
                              style: const TextStyle(color: AppColors.secondary, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          recipe.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onNavigateToUpload,
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                  IconButton(
                    onPressed: () => widget.onDeleteRecipe(recipe.id),
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
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
                style: const TextStyle(color: AppColors.secondary, fontSize: 12),
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
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.menu_book,
                label: 'Resep Saya',
                onTap: widget.onNavigateToUpload,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingTile(
                icon: Icons.bookmark,
                label: 'Resep Favorit / Disimpan',
                onTap: widget.onNavigateToFavorites,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingTile(
                icon: Icons.manage_accounts,
                label: 'Pengaturan Akun & Panel Admin',
                onTap: widget.onNavigateToAdmin,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingTile(
                icon: Icons.help_outline,
                label: 'Bantuan & Tentang Aplikasi',
                onTap: () {
                  widget.onShowToast?.call('Resep Oma v2.4 — Komunitas Kuliner Nusantara & Dunia');
                },
              ),
              const Divider(height: 1, indent: 56),
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? AppColors.onSurfaceVariant).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
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
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.onSurfaceVariant),
    );
  }
}
