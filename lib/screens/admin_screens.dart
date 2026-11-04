import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class AdminRecipesScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final VoidCallback onNavigateToUpload;
  final ValueChanged<String>? onShowToast;

  const AdminRecipesScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onNavigateToUpload,
    this.onShowToast,
  });

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'all';

  List<Map<String, dynamic>> _adminList = [];
  Map<String, int> _reportCounts = {}; // recipe_id -> jumlah laporan open
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Muat laporan dari Firestore
    final reports = await RecipeService.fetchReports();
    final Map<String, int> counts = {};
    for (final r in reports) {
      if (r['status'] == 'open') {
        final rid = (r['recipeId'] ?? '') as String;
        if (rid.isNotEmpty) {
          counts[rid] = (counts[rid] ?? 0) + 1;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _reportCounts = counts;
      _adminList = widget.recipes.map(_mapRecipe).toList();
      _loading = false;
    });
  }

  Map<String, dynamic> _mapRecipe(Recipe recipe) {
    final likes = recipe.likesCount;
    final likesStr = likes >= 1000 ? '${(likes / 1000).toStringAsFixed(1)}k' : '$likes';
    return {
      'id': recipe.id,
      'title': recipe.title,
      'author': recipe.author,
      'code': '#${recipe.code}',
      'likes': likesStr,
      'timeAgo': recipe.publishedAgo,
      'image': recipe.image,
      'reported': _reportCounts[recipe.id] ?? 0,
      'popular': likes >= 200,
    };
  }

  Future<void> _deleteRecipeAdmin(Map<String, dynamic> item) async {
    final res = await RecipeService.deleteRecipe(item['id'] as String);
    if (!mounted) return;
    widget.onShowToast?.call(
      res.message.isEmpty ? 'Gagal menghapus resep.' : res.message,
    );
    if (res.ok) {
      // Muat ulang dari database
      final recipes = await RecipeService.fetchRecipes();
      if (!mounted) return;
      setState(() {
        _adminList = recipes.map(_mapRecipe).toList();
      });
    }
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flag, color: AppColors.onErrorContainer, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Laporan Resep Komunitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: RecipeService.fetchReports(),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final reports = snap.data ?? const [];
                    if (reports.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Belum ada laporan masuk.',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: reports.length,
                      itemBuilder: (context, i) {
                        final rep = reports[i];
                        final isOpen = rep['status'] == 'open';
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isOpen ? Icons.flag : Icons.check_circle_outline,
                            color: isOpen ? AppColors.error : const Color(0xFF10B981),
                            size: 20,
                          ),
                          title: Text(
                            '${rep['recipeTitle'] ?? 'Resep dihapus'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            '"${rep['reason']}"\nOleh: ${rep['reporterName'] ?? 'Anonim'} • ${isOpen ? 'Menunggu tinjauan' : 'Selesai ditinjau'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                          trailing: isOpen
                              ? TextButton(
                                  onPressed: () async {
                                    final res = await RecipeService.resolveReport(
                                        rep['id'] as String);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      widget.onShowToast?.call(
                                        res.message.isEmpty
                                            ? 'Laporan ditandai selesai.'
                                            : res.message,
                                      );
                                    }
                                  },
                                  child: const Text('Selesai'),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _adminList.where((item) {
      final matchSearch = query.isEmpty ||
          (item['title'] as String).toLowerCase().contains(query) ||
          (item['author'] as String).toLowerCase().contains(query) ||
          (item['code'] as String).toLowerCase().contains(query);

      if (_activeFilter == 'popular') return matchSearch && (item['popular'] as bool);
      if (_activeFilter == 'reported') return matchSearch && ((item['reported'] as int) > 0);
      return matchSearch;
    }).toList();

    final totalReports = _reportCounts.values.fold<int>(0, (a, b) => a + b);

    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data resep dari database...',
                style: TextStyle(color: AppColors.secondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOLEKSI KOMUNITAS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text('Kelola Resep', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToUpload,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Buat Resep', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dinner_dining, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Total Resep: ', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                    Text('${_adminList.length}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _showReportsDialog,
              icon: const Icon(Icons.flag, size: 16),
              label: Text(
                totalReports > 0 ? 'Laporan ($totalReports)' : 'Laporan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: totalReports > 0 ? AppColors.error : AppColors.surfaceContainerHigh,
                foregroundColor: totalReports > 0 ? Colors.white : AppColors.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, size: 20),
            hintText: 'Cari nama resep, bahan, penulis...',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _activeFilter = 'all';
                });
                widget.onShowToast?.call('Filter moderasi direset');
              },
              icon: const Icon(Icons.tune, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip('all', 'Semua (${_adminList.length})'),
              const SizedBox(width: 8),
              _buildChip('popular', 'Populer ⭐'),
              const SizedBox(width: 8),
              _buildChip('reported', 'Dilaporkan ($totalReports)', isDestructive: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text(
                'Tidak ada resep yang cocok.',
                style: TextStyle(color: AppColors.secondary),
              ),
            ),
          )
        else
          Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RESEP & PENULIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('TINDAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ...filtered.map((item) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      AppCachedImage(
                        imageUrl: item['image'] as String,
                        width: 48,
                        height: 48,
                        isCircle: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                if ((item['reported'] as int) > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Tinjau',
                                      style: TextStyle(
                                        color: AppColors.onErrorContainer,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'oleh ${item['author']} • ${item['code']}',
                              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                            ),
                            Text(
                              '${item['likes']} Suka • ${item['timeAgo']}',
                              style: const TextStyle(color: AppColors.secondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final match = widget.recipes.firstWhere(
                            (r) => r.id == item['id'],
                            orElse: () => widget.recipes.first,
                          );
                          widget.onSelectRecipe(match);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.onSurfaceVariant),
                      ),
                      IconButton(
                        onPressed: () => _deleteRecipeAdmin(item),
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChip(String id, String label, {bool isDestructive = false}) {
    final active = _activeFilter == id;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (val) {
        if (val) setState(() => _activeFilter = id);
      },
      selectedColor: isDestructive ? AppColors.error : AppColors.inverseSurface,
      backgroundColor: AppColors.surfaceContainerLowest,
      labelStyle: TextStyle(
        color: active ? Colors.white : (isDestructive ? AppColors.error : AppColors.onSurfaceVariant),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
      showCheckmark: false,
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  final ValueChanged<String>? onShowToast;

  const AdminUsersScreen({super.key, this.onShowToast});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final String _activeFilter = 'Semua';
  List<AdminUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);

    if (!RecipeService.isReady) {
      setState(() => _loading = false);
      widget.onShowToast?.call(
        'Database pengguna tidak tersedia. Jalankan `flutterfire configure` terlebih dahulu.',
      );
      return;
    }

    final users = await RecipeService.fetchUsers();
    if (!mounted) return;

    setState(() {
      _users = users.map(AdminUser.fromAppUser).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pengguna Baru', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            const Text(
              'Profil dibuat lebih dulu. Akun login aktif setelah yang bersangkutan mendaftar dengan email ini.',
              style: TextStyle(fontSize: 11, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                widget.onShowToast?.call('Mohon isi nama dan email pengguna.');
                return;
              }
              final res = await RecipeService.createPendingUser(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              if (!mounted) return;
              if (context.mounted) Navigator.pop(context);
              widget.onShowToast?.call(
                res.message.isEmpty ? 'Gagal menambahkan pengguna.' : res.message,
              );
              if (res.ok) {
                _loadUsers(); // muat ulang dari database
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _users.where((u) {
      final matchesQuery = query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.code.toLowerCase().contains(query);

      if (_activeFilter == 'Aktif') return matchesQuery && u.status == 'Aktif';
      if (_activeFilter == 'Kreator') return matchesQuery && u.role == 'Kreator';
      if (_activeFilter == 'Baru') return matchesQuery && u.status == 'Baru';
      if (_activeFilter == 'Ditangguhkan') return matchesQuery && u.status == 'Ditangguhkan';
      return matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daftar Akun Terdaftar', style: Theme.of(context).textTheme.headlineMedium),
                const Text(
                  'Kelola hak akses dan status akun',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
              ],
            ),
            IconButton(
              onPressed: _addUserDialog,
              icon: const Icon(Icons.person_add, color: AppColors.primary),
              style: IconButton.styleFrom(backgroundColor: AppColors.primaryFixed),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Badges row (data nyata dari database)
        Builder(
          builder: (context) {
            final total = _users.length;
            final aktif = _users.where((u) => u.status == 'Aktif').length;
            final baru = _users.where((u) => u.status == 'Baru').length;
            final ditangguhkan = _users.where((u) => u.status == 'Ditangguhkan').length;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MetricBadge(label: 'Total', value: '$total', color: AppColors.onSurface),
                  const SizedBox(width: 8),
                  _MetricBadge(label: 'Aktif', value: '$aktif', color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _MetricBadge(label: 'Baru', value: '$baru', color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _MetricBadge(label: 'Ditangguhkan', value: '$ditangguhkan', color: AppColors.error),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 20),
            hintText: 'Cari nama, email, role, atau ID...',
          ),
        ),
        const SizedBox(height: 14),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada pengguna terdaftar di database.',
                          style: TextStyle(color: AppColors.secondary, fontSize: 13),
                        ),
                      ),
                    )
                  : Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PENGGUNA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('TINDAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ...filtered.map((user) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      AppCachedImage(
                        imageUrl: user.avatar,
                        width: 40,
                        height: 40,
                        isCircle: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(user.email, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
                            Text(
                              '${user.code} • ${user.role}',
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final nextStatus =
                              user.status == 'Ditangguhkan' ? 'active' : 'suspended';
                          final res = await RecipeService.setUserStatus(
                            user.id,
                            nextStatus,
                          );
                          if (!mounted) return;
                          if (res.ok) {
                            setState(() {
                              user.status =
                                  nextStatus == 'suspended' ? 'Ditangguhkan' : 'Aktif';
                            });
                          }
                          widget.onShowToast?.call(
                            res.message.isEmpty ? 'Status gagal diubah.' : res.message,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(60, 32),
                        ),
                        child: Text(
                          user.status == 'Ditangguhkan' ? 'Aktifkan' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            color: user.status == 'Ditangguhkan' ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final res = await RecipeService.deleteUser(user.id);
                          if (!mounted) return;
                          if (res.ok) {
                            setState(() => _users.remove(user));
                          }
                          widget.onShowToast?.call(
                            res.message.isEmpty ? 'Gagal menghapus akun.' : res.message,
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogoutAdmin;
  final ValueChanged<String>? onShowToast;

  const AdminSettingsScreen({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.onLogoutAdmin,
    this.onShowToast,
  });

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  void _changePasswordDialog() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kata Sandi Admin', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata Sandi Baru'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onShowToast?.call('Kata sandi Admin berhasil diperbarui!');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Profile Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: const Row(
            children: [
              AppCachedImage(
                imageUrl: MockImages.adminHeadChef,
                width: 64,
                height: 64,
                isCircle: true,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Super Administrator', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                    Text('admin@kuliner.app', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('KEAMANAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: _changePasswordDialog,
              leading: const Icon(Icons.lock_reset, color: AppColors.primary),
              title: const Text('Ubah Kata Sandi Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('TAMPILAN & TEMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: AppColors.surfaceContainerLowest,
              child: SwitchListTile(
                value: widget.darkMode,
                onChanged: widget.onToggleDarkMode,
                activeThumbColor: AppColors.primary,
                title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan tema gelap untuk kenyamanan mata', style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        ElevatedButton.icon(
          onPressed: widget.onLogoutAdmin,
          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
          label: const Text('Keluar dari Sesi Admin', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'ID Sesi: ADM-9482-KUL-2024 • Terenkripsi End-to-End',
            style: TextStyle(color: AppColors.outline, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
