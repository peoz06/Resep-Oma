import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
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
  int? _currentUserId;
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
    _loadRecipesFromApi();
  }

  /// Muat daftar resep dari MySQL lewat API PHP.
  /// Jika server tidak terjangkau, otomatis tampil data contoh (mode offline).
  Future<void> _loadRecipesFromApi() async {
    setState(() => _loadingRecipes = true);

    // Tentukan URL API yang bisa dijangkau (localhost / emulator / IP laptop).
    await ApiService.resolveBaseUrl();

    // Tidak ada server sama sekali: langsung mode offline tanpa menunggu timeout.
    if (!ApiService.isServerAvailable) {
      setState(() {
        _recipes = MockData.getInitialRecipes();
        _offlineMode = true;
        _loadingRecipes = false;
      });
      _showToast('Server API tidak ditemukan. Menampilkan resep contoh (mode offline).');
      return;
    }

    final res = await ApiService.fetchRecipes();
    final favIds = await _fetchFavoriteIds();

    if (!mounted) return;

    if (res['status'] == true) {
      final rows = (res['recipes'] as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) {
        // Database kosong: tampilkan data contoh agar aplikasi tetap terpakai.
        setState(() {
          _recipes = MockData.getInitialRecipes();
          _offlineMode = true;
          _loadingRecipes = false;
        });
        _showToast('Database masih kosong. Menampilkan resep contoh (mode demo).');
      } else {
        setState(() {
          _recipes = rows
              .map((row) => Recipe.fromDb(
                    row,
                    currentUserId: _currentUserId,
                    isFavorite: favIds.contains(row['id']),
                  ))
              .toList();
          if (_offlineMode) {
            _offlineMode = false;
          }
          _loadingRecipes = false;
        });
      }
    } else {
      // Server tidak terjangkau / error: fallback ke data contoh.
      setState(() {
        _recipes = MockData.getInitialRecipes();
        _offlineMode = true;
        _loadingRecipes = false;
      });
      _showToast(
        '${res['message']?.toString() ?? 'Server tidak terjangkau.'} Menampilkan resep contoh (mode offline).',
      );
    }
  }

  /// Ambil ID resep yang disukai user yang sedang login.
  Future<Set<int>> _fetchFavoriteIds() async {
    if (_currentUserId == null) return {};
    final res = await ApiService.fetchFavorites(_currentUserId!);
    if (res['status'] != true) return {};
    final rows = (res['favorites'] as List).cast<Map<String, dynamic>>();
    return rows.map((r) => (r['id'] as num).toInt()).toSet();
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

  void _handleRegisterSuccess(String name, String email) {
    setState(() {
      _currentUserName = name;
      _currentUserEmail = email;
      _prefilledLoginEmail = email;
      _authScreen = 'login'; // Dilempar ke halaman login!
    });
    _showToast('Registrasi berhasil! Silakan masukkan kata sandi untuk login.');
  }

  void _handleLoginSuccess(Map<String, dynamic> user) {
    setState(() {
      _isLoggedIn = true;
      _currentUserId = (user['id'] as num).toInt();
      _currentUserRole = (user['role'] ?? 'user') as String;
      _currentUserEmail = (user['email'] ?? '') as String;
      _currentUserName = (user['name'] ?? '') as String;
      _currentUserAvatar = user['avatar'] as String?;
      _prefilledLoginEmail = _currentUserEmail;
      _currentMode = AppMode.user;

      if (_pendingUploadAfterLogin) {
        _userNavIndex = 2; // Langsung diarahkan ke Unggah Resep!
        _pendingUploadAfterLogin = false;
        _showToast('Berhasil masuk! Silakan mulai membuat resep kreasi Anda.');
      } else {
        _showToast('Selamat datang kembali, $_currentUserName!');
      }
    });
    // Muat ulang resep agar flag favorit & "Resep Saya" sesuai user login.
    _loadRecipesFromApi();
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _currentUserId = null;
      _currentUserRole = 'user';
      _currentUserName = 'Tamu';
      _currentUserEmail = 'guest@resepoma.id';
      _currentUserAvatar = null;
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
    final idx = _recipes.indexWhere((r) => r.id == id);
    if (idx == -1) return;

    // Mode offline (data contoh): toggle lokal saja.
    final recipeId = int.tryParse(id);
    if (_currentUserId == null || recipeId == null || _offlineMode) {
      setState(() {
        final idx2 = _recipes.indexWhere((r) => r.id == id);
        if (idx2 != -1) {
          _recipes[idx2].isFavorite = !_recipes[idx2].isFavorite;
          final isFav = _recipes[idx2].isFavorite;
          _showToast(isFav
              ? '"${_recipes[idx2].title}" disimpan ke Favorit'
              : '"${_recipes[idx2].title}" dihapus dari Favorit');
        }
      });
      return;
    }

    final res = await ApiService.toggleFavorite(
      userId: _currentUserId!,
      recipeId: recipeId,
    );

    if (!mounted) return;

    if (res['status'] == true) {
      setState(() {
        final idx2 = _recipes.indexWhere((r) => r.id == id);
        if (idx2 != -1) {
          _recipes[idx2].isFavorite = (res['is_favorite'] ?? false) as bool;
        }
      });
      _showToast(res['message']?.toString() ?? 'Favorit diperbarui.');
    } else {
      _showToast(res['message']?.toString() ?? 'Gagal memperbarui favorit.');
    }
  }

  void _selectRecipe(Recipe recipe) {
    RecipeDetailSheet.show(
      context,
      recipe: recipe,
      onToggleFavorite: () => _toggleFavorite(recipe.id),
      onShowToast: _showToast,
      currentUserId: _currentUserId,
    );
  }

  void _publishRecipe() {
    // Muat ulang dari database agar data terbaru tampil (termasuk kode resep).
    _loadRecipesFromApi();
    setState(() => _userNavIndex = 0);
  }

  void _deleteRecipe(String id) async {
    final idx = _recipes.indexWhere((r) => r.id == id);
    final target = idx != -1 ? _recipes[idx] : null;

    final recipeId = int.tryParse(id);
    if (recipeId == null || _offlineMode) {
      // Mode offline: hapus lokal saja.
      setState(() => _recipes.removeWhere((r) => r.id == id));
      _showToast('Resep "${target?.title ?? ''}" dihapus (mode offline).');
      return;
    }

    final res = await ApiService.deleteRecipe(recipeId);

    if (!mounted) return;

    if (res['status'] == true) {
      _loadRecipesFromApi();
      _showToast(res['message']?.toString() ?? 'Resep "${target?.title ?? ''}" telah dihapus.');
    } else {
      _showToast(res['message']?.toString() ?? 'Gagal menghapus resep.');
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
              onRegisterSuccess: _handleRegisterSuccess,
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
            onUpdateProfile: (newName, newEmail) {
              setState(() {
                _currentUserName = newName;
                _currentUserEmail = newEmail;
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: widget.darkMode ? AppColors.darkSurface : AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickPill('Beranda', () => setState(() { _currentMode = AppMode.user; _userNavIndex = 0; }), _currentMode == AppMode.user && _userNavIndex == 0),
                  _buildQuickPill('Eksplor', () => setState(() { _currentMode = AppMode.user; _userNavIndex = 1; }), _currentMode == AppMode.user && _userNavIndex == 1),
                  _buildQuickPill('Unggah', _onTapUpload, _currentMode == AppMode.user && _userNavIndex == 2),
                  _buildQuickPill('Favorit', () => setState(() { _currentMode = AppMode.user; _userNavIndex = 3; }), _currentMode == AppMode.user && _userNavIndex == 3),
                  _buildQuickPill('Profil', () => setState(() { _currentMode = AppMode.user; _userNavIndex = 4; }), _currentMode == AppMode.user && _userNavIndex == 4),
                  _buildQuickPill('Login', () => setState(() { _currentMode = AppMode.auth; _authScreen = 'login'; }), _currentMode == AppMode.auth && _authScreen == 'login'),
                  _buildQuickPill('Register', () => setState(() { _currentMode = AppMode.auth; _authScreen = 'register'; }), _currentMode == AppMode.auth && _authScreen == 'register'),
                  _buildQuickPill('Admin Resep', () => setState(() { _currentMode = AppMode.admin; _adminNavIndex = 0; }), _currentMode == AppMode.admin && _adminNavIndex == 0),
                  _buildQuickPill('Admin Users', () => setState(() { _currentMode = AppMode.admin; _adminNavIndex = 1; }), _currentMode == AppMode.admin && _adminNavIndex == 1),
                  _buildQuickPill('Admin Settings', () => setState(() { _currentMode = AppMode.admin; _adminNavIndex = 2; }), _currentMode == AppMode.admin && _adminNavIndex == 2),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildQuickPill(String label, VoidCallback onTap, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
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
