import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/recipe_detail_sheet.dart';
import 'admin_screens.dart';
import 'auth_screens.dart';
import 'beranda_screen.dart';
import 'eksplor_screen.dart';
import 'favorit_screen.dart';
import 'profil_screen.dart';
import 'unggah_resep_screen.dart';

enum AppMode {
  user,
  auth,
  admin,
}

class MainNavigationScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const MainNavigationScreen({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  AppMode _currentMode = AppMode.user;

  // Guest State by default!
  bool _isLoggedIn = false;
  String? _currentUserId;
  String _currentUserRole = 'user';
  String _currentUserName = 'Tamu';
  String _currentUserEmail = 'guest@resepoma.id';
  String? _currentUserAvatar;
  String? _prefilledLoginEmail;
  bool _pendingUploadAfterLogin = false;

  bool _loadingRecipes = true;

  // User Mode Index: 0: Beranda, 1: Eksplor, 2: Unggah, 3: Favorit, 4: Profil
  int _userNavIndex = 0;

  // Auth Mode: 'login' or 'register'
  String _authScreen = 'login';

  // Admin Mode Index: 0: Recipes, 1: Users, 2: Settings
  int _adminNavIndex = 0;

  late List<Recipe> _recipes;
  String? _toastMessage;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _recipes = [];
    _bootstrap();
  }

  /// Urutan awal aplikasi:
  /// 1. siapkan Firebase (bila sudah dikonfigurasi)
  /// 2. pulihkan sesi tersimpan, atau buat sesi tamu (anonim)
  /// 3. muat daftar resep
  Future<void> _bootstrap() async {
    await FirebaseService.init();

    if (FirebaseService.isReady) {
      final restored = await AuthService.restoreSession();
      if (restored.ok && restored.user != null) {
        _applyUser(restored.user!);
      } else {
        // Mode tamu: beri identitas anonim agar aturan keamanan Firestore
        // tetap bisa diterapkan. Gagal pun aplikasi tetap jalan sebagai tamu.
        try {
          await AuthService.signInAnonymously()
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // diabaikan — tamu tanpa sesi Firebase tetap sah
        }
      }
    }

    if (!mounted) return;
    await _loadRecipes();
  }

  void _applyUser(AppUser user) {
    _isLoggedIn = true;
    _currentUserId = user.uid;
    _currentUserRole = user.role;
    _currentUserEmail = user.email;
    _currentUserName = user.name.trim().isEmpty ? 'Pengguna' : user.name.trim();
    _currentUserAvatar = user.avatar;
    _prefilledLoginEmail = user.email;
  }

  void _resetGuestState() {
    _isLoggedIn = false;
    _currentUserId = null;
    _currentUserRole = 'user';
    _currentUserName = 'Tamu';
    _currentUserEmail = 'guest@resepoma.id';
    _currentUserAvatar = null;
  }

  /// Muat daftar resep dari Firestore.
  /// Jika Firebase belum terkonfigurasi atau koleksi masih kosong,
  /// otomatis tampil data contoh (mode offline / demo).
  Future<void> _loadRecipes() async {
    setState(() => _loadingRecipes = true);

    final uid = _currentUserId;
    Set<String> favIds = const {};
    if (uid != null) {
      favIds = await RecipeService.fetchFavoriteIds(uid);
    }

    final recipes = await RecipeService.fetchRecipes(
      currentUid: uid,
      favoriteIds: favIds,
    );

    if (!mounted) return;

    if (recipes.isNotEmpty) {
      setState(() {
        _recipes = recipes;
        _offlineMode = false;
        _loadingRecipes = false;
      });
      return;
    }

    final notConfigured = !FirebaseService.isReady;
    setState(() {
      _recipes = MockData.getInitialRecipes();
      _offlineMode = true;
      _loadingRecipes = false;
    });
    _showToast(
      notConfigured
          ? '${FirebaseService.humanError} Menampilkan resep contoh (mode offline).'
          : 'Database masih kosong. Menampilkan resep contoh (mode demo).',
    );
  }

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted && _toastMessage == msg) {
        setState(() => _toastMessage = null);
      }
    });
  }

  void _onTapUpload() {
    if (!_isLoggedIn) {
      _showAuthRequiredSheet();
    } else {
      setState(() {
        _currentMode = AppMode.user;
        _userNavIndex = 2;
      });
    }
  }

  void _showAuthRequiredSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.darkMode ? AppColors.darkSurfaceContainer : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Masuk Akun Diperlukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saat ini Anda memakai akun Tamu (Guest). Untuk mengunggah kreasi resep ke komunitas Resep Oma, silakan registrasi akun terlebih dahulu atau login jika sudah terdaftar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _pendingUploadAfterLogin = true;
                  _currentMode = AppMode.auth;
                  _authScreen = 'register'; // Registrasi terlebih dahulu!
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Daftar Akun Baru (Registrasi)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _pendingUploadAfterLogin = true;
                  _currentMode = AppMode.auth;
                  _authScreen = 'login';
                });
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Sudah Punya Akun? Masuk', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti Saja (Lanjut sebagai Tamu)', style: TextStyle(color: AppColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLoginSuccess(AppUser user) {
    setState(() {
      _applyUser(user);
      _currentMode = AppMode.user;

      if (_pendingUploadAfterLogin) {
        _userNavIndex = 2; // Langsung diarahkan ke Unggah Resep!
        _pendingUploadAfterLogin = false;
        _showToast('Berhasil masuk! Silakan mulai membuat resep kreasi Anda.');
      } else {
        _showToast('Selamat datang, $_currentUserName!');
      }
    });
    // Muat ulang resep agar flag favorit & "Resep Saya" sesuai user login.
    _loadRecipes();
  }

  void _handleLogout() async {
    await AuthService.signOut();
    if (!mounted) return;
    setState(() {
      _resetGuestState();
      _userNavIndex = 0;
      _currentMode = AppMode.user;
    });
    // Reset favorit di daftar resep
    for (final r in _recipes) {
      r.isFavorite = false;
    }
    _showToast('Anda telah keluar. Sekarang menjelajah sebagai Tamu.');
  }

  void _toggleFavorite(String id) async {
    final uid = _currentUserId;

    // Tamu / mode offline (data contoh): toggle lokal saja.
    if (uid == null || _offlineMode || !FirebaseService.isReady) {
      setState(() {
        final idx = _recipes.indexWhere((r) => r.id == id);
        if (idx != -1) {
          _recipes[idx].isFavorite = !_recipes[idx].isFavorite;
          final isFav = _recipes[idx].isFavorite;
          _showToast(isFav
              ? '"${_recipes[idx].title}" disimpan ke Favorit'
              : '"${_recipes[idx].title}" dihapus dari Favorit');
        }
      });
      return;
    }

    final newState = await RecipeService.toggleFavorite(uid: uid, recipeId: id);

    if (!mounted) return;

    if (newState == null) {
      _showToast('Gagal memperbarui favorit. Periksa koneksi internet Anda.');
      return;
    }

    setState(() {
      final idx = _recipes.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _recipes[idx].isFavorite = newState;
      }
    });
    final idx = _recipes.indexWhere((r) => r.id == id);
    final title = idx != -1 ? _recipes[idx].title : '';
    _showToast(newState
        ? '"$title" disimpan ke Favorit'
        : '"$title" dihapus dari Favorit');
  }

  void _selectRecipe(Recipe recipe) {
    RecipeDetailSheet.show(
      context,
      recipe: recipe,
      onToggleFavorite: () => _toggleFavorite(recipe.id),
      onShowToast: _showToast,
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
    );
  }

  void _publishRecipe() {
    // Muat ulang dari database agar data terbaru tampil (termasuk kode resep).
    _loadRecipes();
    setState(() => _userNavIndex = 0);
  }

  void _deleteRecipe(String id) async {
    final idx = _recipes.indexWhere((r) => r.id == id);
    final target = idx != -1 ? _recipes[idx] : null;

    if (!RecipeService.isReady || _offlineMode) {
      // Mode offline: hapus lokal saja.
      setState(() => _recipes.removeWhere((r) => r.id == id));
      _showToast('Resep "${target?.title ?? ''}" dihapus (mode offline).');
      return;
    }

    final res = await RecipeService.deleteRecipe(id);

    if (!mounted) return;

    if (res.ok) {
      await _loadRecipes();
      _showToast(
        res.message.isNotEmpty
            ? res.message
            : 'Resep "${target?.title ?? ''}" telah dihapus.',
      );
    } else {
      _showToast(res.message.isNotEmpty ? res.message : 'Gagal menghapus resep.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopOrTablet = media.size.width > 600;

    Widget currentScreenWidget;
    if (_currentMode == AppMode.auth) {
      currentScreenWidget = _authScreen == 'login'
          ? LoginScreen(
              initialEmail: _prefilledLoginEmail,
              onLoginSuccess: _handleLoginSuccess,
              onNavigateToRegister: () => setState(() => _authScreen = 'register'),
              onBackToGuest: () => setState(() => _currentMode = AppMode.user),
              onShowToast: _showToast,
            )
          : RegisterScreen(
              onRegisterSuccess: _handleLoginSuccess,
              onNavigateToLogin: () => setState(() => _authScreen = 'login'),
              onBackToGuest: () => setState(() => _currentMode = AppMode.user),
              onShowToast: _showToast,
            );
    } else if (_currentMode == AppMode.admin) {
      if (_adminNavIndex == 0) {
        currentScreenWidget = AdminRecipesScreen(
          recipes: _recipes,
          onSelectRecipe: _selectRecipe,
          onNavigateToUpload: _onTapUpload,
          onShowToast: _showToast,
        );
      } else if (_adminNavIndex == 1) {
        currentScreenWidget = AdminUsersScreen(onShowToast: _showToast);
      } else {
        currentScreenWidget = AdminSettingsScreen(
          darkMode: widget.darkMode,
          onToggleDarkMode: widget.onToggleDarkMode,
          onLogoutAdmin: () => setState(() => _currentMode = AppMode.user),
          onShowToast: _showToast,
        );
      }
    } else {
      switch (_userNavIndex) {
        case 0:
          currentScreenWidget = BerandaScreen(
            recipes: _recipes,
            userName: _currentUserName,
            onSelectRecipe: _selectRecipe,
            onToggleFavorite: _toggleFavorite,
            onNavigateToExplore: () => setState(() => _userNavIndex = 1),
          );
          break;
        case 1:
          currentScreenWidget = EksplorScreen(
            recipes: _recipes,
            onSelectRecipe: _selectRecipe,
            onToggleFavorite: _toggleFavorite,
            onShowToast: _showToast,
          );
          break;
        case 2:
          currentScreenWidget = UnggahResepScreen(
            onPublishRecipe: _publishRecipe,
            userId: _currentUserId,
            userName: _currentUserName,
            userAvatar: _currentUserAvatar,
            onShowToast: _showToast,
          );
          break;
        case 3:
          currentScreenWidget = FavoritScreen(
            recipes: _recipes,
            onSelectRecipe: _selectRecipe,
            onToggleFavorite: _toggleFavorite,
            onShowToast: _showToast,
          );
          break;
        case 4:
        default:
          currentScreenWidget = ProfilScreen(
            recipes: _recipes,
            isLoggedIn: _isLoggedIn,
            userId: _currentUserId,
            userName: _currentUserName,
            userEmail: _currentUserEmail,
            userAvatar: _currentUserAvatar,
            onSelectRecipe: _selectRecipe,
            onDeleteRecipe: _deleteRecipe,
            onNavigateToUpload: _onTapUpload,
            onNavigateToFavorites: () => setState(() => _userNavIndex = 3),
            onNavigateToAdmin: () {
              if (_currentUserRole != 'admin') {
                _showToast('Halaman admin hanya untuk akun dengan role Admin.');
                return;
              }
              setState(() {
                _currentMode = AppMode.admin;
                _adminNavIndex = 0;
              });
            },
            onLogout: _handleLogout,
            onUpdateProfile: (name, email, updated) {
              setState(() {
                if (updated != null) _applyUser(updated);
                _currentUserName = name;
                _currentUserEmail = email;
                _prefilledLoginEmail = email;
              });
            },
            onLogin: () => setState(() {
              _pendingUploadAfterLogin = false;
              _currentMode = AppMode.auth;
              _authScreen = 'login';
            }),
            onShowToast: _showToast,
          );
          break;
      }
    }

    final mobileAppShell = Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: _loadingRecipes && _currentMode == AppMode.user
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Memuat resep dari database...',
                          style: TextStyle(color: AppColors.secondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : currentScreenWidget,
          ),

          // Floating Toast
          if (_toastMessage != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.primaryFixedDim, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _toastMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );

    if (!isDesktopOrTablet) {
      return mobileAppShell;
    }

    // Responsive Desktop / Tablet Wrapper: centers the mobile phone shell cleanly
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF0A0A0C) : const Color(0xFFE2DFE8),
      body: Center(
        child: Container(
          width: 430,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: mobileAppShell,
        ),
      ),
    );
  }

  Widget? _buildBottomNav() {
    if (_currentMode == AppMode.auth) return null;

    if (_currentMode == AppMode.admin) {
      return Container(
        decoration: BoxDecoration(
          color: widget.darkMode ? AppColors.darkSurfaceContainer : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _adminNavIndex,
            onTap: (index) => setState(() => _adminNavIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.secondary,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
              BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Settings'),
            ],
          ),
        ),
      );
    }

    // User Mode Navigation Bar
    return Container(
      decoration: BoxDecoration(
        color: widget.darkMode ? AppColors.darkSurfaceContainer : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Beranda', 0),
              _buildNavItem(Icons.explore, 'Eksplor', 1),
              // Center Add Recipe FAB with Auth Guard!
              GestureDetector(
                onTap: _onTapUpload,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _userNavIndex == 2 ? AppColors.primary : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: _userNavIndex == 2 ? Colors.white : AppColors.onSurface,
                    size: 24,
                  ),
                ),
              ),
              _buildNavItem(Icons.favorite, 'Favorit', 3),
              _buildNavItem(Icons.person, 'Profil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final active = _userNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _userNavIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
