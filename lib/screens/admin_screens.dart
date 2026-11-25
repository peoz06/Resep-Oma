import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';

class AdminRecipesScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final VoidCallback onNavigateToUpload;
  final Future<void> Function(String) onDeleteRecipe;
  final ValueChanged<String>? onRecipeChanged;
  final VoidCallback? onLoadMore;
  final bool loadingMore;
  final ValueChanged<String>? onShowToast;

  const AdminRecipesScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    required this.onNavigateToUpload,
    required this.onDeleteRecipe,
    this.onRecipeChanged,
    this.onLoadMore,
    this.loadingMore = false,
    this.onShowToast,
  });

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'all';

  List<Map<String, dynamic>> get _adminList =>
      widget.recipes.map(_mapRecipe).toList();
  final _reports = <Map<String, dynamic>>[];
  final _reportedRecipeIds = <String>{};
  DocumentSnapshot<Map<String, dynamic>>? _nextReport;
  Future<int?>? _openReportCount;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool more = false}) async {
    if (!mounted || _loading || (more && _nextReport == null)) return;
    setState(() {
      _loading = true;
      _loadError = null;
      if (!more) _openReportCount = RecipeService.countOpenReports();
    });

    try {
      final page = await RecipeService.fetchReports(after: more ? _nextReport : null);
      if (!mounted) return;
      setState(() {
        if (!more) {
          _reports.clear();
          _reportedRecipeIds.clear();
        }
        _reports.addAll(page.items);
        _reportedRecipeIds.addAll([
          for (final report in page.items)
            if (report['status'] == 'open') report['recipeId'] as String,
        ]);
        _nextReport = page.next;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = RecipeService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _mapRecipe(Recipe recipe) {
    final likes = recipe.likesCount;
    final likesStr =
        likes >= 1000 ? '${(likes / 1000).toStringAsFixed(1)}k' : '$likes';
    return {
      'id': recipe.id,
      'title': recipe.title,
      'author': recipe.author,
      'code': '#${recipe.code}',
      'likes': likesStr,
      'timeAgo': recipe.publishedAgo,
      'image': recipe.image,
      'reported': _reportedRecipeIds.contains(recipe.id),
      'popular': likes >= 200,
      'verified': recipe.verified,
    };
  }

  Future<void> _deleteRecipeAdmin(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Hapus resep?'),
        content: Text('"${item['title']}" akan dihapus permanen. Foto yang sudah diunggah tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onDeleteRecipe(item['id'] as String);
  }

  void _showReportsDialog() {
    var resolving = false;
    Future<void> loadReports(BuildContext context, StateSetter redraw, {bool more = false}) async {
      final load = _loadData(more: more);
      redraw(() {});
      await load;
      if (context.mounted) redraw(() {});
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, redraw) => Dialog(
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
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: AppColors.onErrorContainer, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Laporan Resep Komunitas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loading || resolving ? null : () => loadReports(context, redraw),
                        tooltip: 'Muat ulang laporan',
                        icon: const Icon(Icons.refresh, color: AppColors.onErrorContainer),
                      ),
                    ],
                  ),
                ),
                if (_reports.isEmpty && _loadError == null && !_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Belum ada laporan masuk.'),
                  ),
                if (_reports.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _reports.length,
                      itemBuilder: (_, i) {
                        final rep = _reports[i];
                        final isOpen = rep['status'] == 'open';
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isOpen ? Icons.flag : Icons.check_circle_outline,
                            color: isOpen ? AppColors.error : const Color(0xFF10B981),
                            size: 20,
                          ),
                          title: Text('${rep['recipeTitle']}'),
                          subtitle: Text(
                            '"${rep['reason']}"\nOleh: ${rep['reporterName']} • ${isOpen ? 'Menunggu tinjauan' : 'Selesai ditinjau'}',
                          ),
                          isThreeLine: true,
                          trailing: isOpen
                              ? TextButton(
                                  onPressed: _loading || resolving ? null : () async {
                                    if (!mounted) return;
                                    redraw(() => resolving = true);
                                    final res = await RecipeService.resolveReport(rep['id'] as String);
                                    if (!mounted) return;
                                    if (context.mounted) Navigator.pop(context);
                                    widget.onShowToast?.call(res.message);
                                    if (res.ok) await _loadData();
                                  },
                                  child: const Text('Selesai'),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                if (_loadError case final error?)
                  Padding(padding: const EdgeInsets.all(12), child: Text(error)),
                if (_loading || _nextReport != null || _loadError != null)
                  OutlinedButton(
                    onPressed: _loading || resolving ? null :
                        () => loadReports(context, redraw, more: _nextReport != null),
                    child: Text(_loading ? 'Memuat...' : _loadError != null
                        ? 'Coba lagi' : 'Muat lebih banyak laporan'),
                  ),
              ],
            ),
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

    final adminList = _adminList;
    final filtered = adminList.where((item) {
      final matchSearch = query.isEmpty ||
          (item['title'] as String).toLowerCase().contains(query) ||
          (item['author'] as String).toLowerCase().contains(query) ||
          (item['code'] as String).toLowerCase().contains(query);

      if (_activeFilter == 'popular') {
        return matchSearch && (item['popular'] as bool);
      }
      // shortcut: hanya laporan dimuat; gunakan query khusus jika perlu filter global.
      if (_activeFilter == 'reported') {
        return matchSearch && (item['reported'] as bool);
      }
      return matchSearch;
    }).toList();

    if (_loading && _reports.isEmpty) {
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
        if (_loadError != null)
          Text(_loadError!, style: const TextStyle(color: AppColors.error)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
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
                  Text('Kelola Resep',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToUpload,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Buat Resep',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
                    const Icon(Icons.dinner_dining,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Resep dimuat:',
                          style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                    ),
                    Text('${adminList.length}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            FutureBuilder<int?>(
              future: _openReportCount,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return ElevatedButton.icon(
                  onPressed: _loading ? null : _showReportsDialog,
                  icon: const Icon(Icons.flag, size: 16),
                  label: Text(
                    total > 0 ? 'Laporan ($total)' : 'Laporan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: total > 0
                        ? AppColors.error : AppColors.surfaceContainerHigh,
                    foregroundColor: total > 0 ? Colors.white : AppColors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
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
              _buildChip('all', 'Semua (${adminList.length})'),
              const SizedBox(width: 8),
              _buildChip('popular', 'Populer ⭐'),
              const SizedBox(width: 8),
              _buildChip('reported', 'Dilaporkan', isDestructive: true),
            ],
          ),
        ),
        if (_activeFilter == 'reported')
          const Text('Filter memakai laporan yang sudah dimuat. Buka Laporan untuk memuat lebih banyak.'),
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RESEP & PENULIS',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('TINDAKAN',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                  if (item['reported'] as bool)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
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
                                style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 11),
                              ),
                              Text(
                                '${item['likes']} Suka • ${item['timeAgo']}',
                                style: const TextStyle(
                                    color: AppColors.secondary, fontSize: 10),
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
                          icon: const Icon(Icons.visibility_outlined,
                              size: 20, color: AppColors.onSurfaceVariant),
                        ),
                        IconButton(
                          tooltip: item['verified'] == true ? 'Cabut verifikasi' : 'Verifikasi resep',
                          onPressed: () async {
                            final result = await RecipeService.setRecipeVerified(
                                item['id'] as String, item['verified'] != true);
                            if (!mounted) return;
                            widget.onShowToast?.call(result.message);
                            if (result.ok) widget.onRecipeChanged?.call(item['id'] as String);
                          },
                          icon: Icon(item['verified'] == true
                              ? Icons.verified : Icons.verified_outlined,
                              color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () => _deleteRecipeAdmin(item),
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        if (widget.onLoadMore != null)
          OutlinedButton(
            onPressed: widget.loadingMore ? null : widget.onLoadMore,
            child: Text(widget.loadingMore ? 'Memuat...' : 'Muat lebih banyak resep'),
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
        color: active
            ? Colors.white
            : (isDestructive ? AppColors.error : AppColors.onSurfaceVariant),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide.none),
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
  final _users = <AdminUser>[];
  DocumentSnapshot<Map<String, dynamic>>? _nextUser;
  Future<int?>? _totalUsers;
  int _usersRequest = 0;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool more = false}) async {
    if (more && (_loading || _nextUser == null)) return;
    if (!RecipeService.isReady) {
      widget.onShowToast?.call(
        'Database pengguna tidak tersedia. Jalankan `flutterfire configure` terlebih dahulu.',
      );
      return;
    }

    final request = ++_usersRequest;
    bool isCurrent() => mounted && request == _usersRequest;
    setState(() {
      _loading = true;
      _loadError = null;
      if (!more) _totalUsers = RecipeService.countUsers();
    });
    try {
      final page = await RecipeService.fetchUsers(after: more ? _nextUser : null);
      if (!isCurrent()) return;
      setState(() {
        if (!more) _users.clear();
        _users.addAll(page.items.map(AdminUser.fromAppUser));
        _nextUser = page.next;
      });
    } catch (e) {
      if (isCurrent()) setState(() => _loadError = RecipeService.errorMessage(e));
    } finally {
      if (isCurrent()) setState(() => _loading = false);
    }
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
        title:
            const Text('Tambah Pengguna Baru', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 10),
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            const Text(
              'Ini hanya catatan profil pending, bukan akun login. Pengguna tetap harus registrasi; admin memoderasi akun UID hasil registrasi.',
              style: TextStyle(fontSize: 11, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty) {
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
                res.message.isEmpty
                    ? 'Gagal menambahkan pengguna.'
                    : res.message,
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

  Future<void> _banUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Blokir ${user.name}?'),
        content: const Text(
            'Pengguna tidak bisa masuk atau mengunggah resep. Dokumen profil tetap disimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Blokir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await RecipeService.banUser(user.id);
    if (!mounted) return;
    if (res.ok) setState(() => user.status = 'Diblokir');
    widget.onShowToast?.call(
        res.ok ? 'Pengguna diblokir. Profil tetap disimpan.' : res.message);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    // shortcut: cari pada halaman dimuat; tambah pencarian server jika perlu lintas halaman.
    final filtered = _users.where((user) =>
        query.isEmpty ||
        user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        user.role.toLowerCase().contains(query) ||
        user.id.toLowerCase().contains(query) ||
        user.code.toLowerCase().contains(query)).toList();

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Akun Terdaftar',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Text(
                    'Kelola hak akses dan status akun',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addUserDialog,
              icon: const Icon(Icons.person_add, color: AppColors.primary),
              style:
                  IconButton.styleFrom(backgroundColor: AppColors.primaryFixed),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Badges row (data nyata dari database)
        Builder(
          builder: (context) {
            final aktif = _users.where((u) => u.status == 'Aktif').length;
            final baru = _users.where((u) => u.status == 'Baru').length;
            final ditangguhkan =
                _users.where((u) => u.status == 'Ditangguhkan').length;
            final diblokir = _users.where((u) => u.status == 'Diblokir').length;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FutureBuilder<int?>(
                    future: _totalUsers,
                    builder: (_, snapshot) => _MetricBadge(
                        label: 'Total',
                        value: snapshot.data?.toString() ?? '—',
                        color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 8),
                  _MetricBadge(
                      label: 'Aktif',
                      value: '$aktif',
                      color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _MetricBadge(
                      label: 'Baru',
                      value: '$baru',
                      color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _MetricBadge(
                      label: 'Ditangguhkan',
                      value: '$ditangguhkan',
                      color: AppColors.error),
                  const SizedBox(width: 8),
                  _MetricBadge(
                      label: 'Diblokir',
                      value: '$diblokir',
                      color: AppColors.error),
                ],
              ),
            );
          },
        ),
        const Text('Rincian status hanya dari pengguna yang sudah dimuat.'),
        const SizedBox(height: 14),

        TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 20),
            hintText: 'Cari nama, email, role, atau ID...',
            helperText: 'Pencarian hanya pada pengguna yang sudah dimuat.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('PENGGUNA'), Text('TINDAKAN')],
            ),
          ),
      ],
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: filtered.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return header;
        if (index <= filtered.length) return _buildUserRow(filtered[index - 1]);
        return Column(
          children: [
            if (_loading && filtered.isEmpty)
              const CircularProgressIndicator()
            else if (_loadError case final error?)
              Text(error, style: const TextStyle(color: AppColors.error))
            else if (filtered.isEmpty)
              Text(query.isEmpty ? 'Belum ada pengguna terdaftar di database.'
                  : 'Tidak ada pengguna yang cocok dalam hasil yang dimuat.'),
            if (_nextUser != null || _loadError != null)
              OutlinedButton(
                onPressed: _loading ? null : () => _loadUsers(more: _nextUser != null),
                child: Text(_loading ? 'Memuat...' : _loadError != null
                    ? 'Coba lagi' : 'Muat lebih banyak pengguna'),
              ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildUserRow(AdminUser user) {
    return Container(
      key: ValueKey(user.id),
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AppCachedImage(imageUrl: user.avatar, width: 40, height: 40, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(user.email, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
                Text('${user.code} • ${user.role}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: user.status == 'Baru' ? null : () async {
              final nextStatus = user.status == 'Aktif' ? 'suspended' : 'active';
              final result = await RecipeService.setUserStatus(user.id, nextStatus);
              if (!mounted) return;
              if (result.ok) {
                setState(() => user.status = nextStatus == 'suspended' ? 'Ditangguhkan' : 'Aktif');
              }
              widget.onShowToast?.call(result.message);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 48),
            ),
            child: Text(
              user.status == 'Aktif' ? 'Tangguhkan' : 'Aktifkan',
              style: TextStyle(fontSize: 10,
                  color: user.status == 'Ditangguhkan' ? AppColors.primary : AppColors.secondary),
            ),
          ),
          PopupMenuButton<String>(
            enabled: user.status != 'Baru',
            tooltip: 'Ubah role pengguna',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onSelected: (role) async {
              if (role == 'admin') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialog) => AlertDialog(
                    title: const Text('Berikan akses admin?'),
                    content: Text('${user.name} akan bisa mengelola semua akun dan resep.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Jadikan admin')),
                    ],
                  ),
                );
                if (confirmed != true || !mounted) return;
              }
              final result = await RecipeService.setUserRole(user.id, role);
              if (!mounted) return;
              widget.onShowToast?.call(result.message);
              if (result.ok) await _loadUsers();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'user', child: Text('Pengguna')),
              PopupMenuItem(value: 'creator', child: Text('Kreator')),
              PopupMenuItem(value: 'admin', child: Text('Admin')),
            ],
          ),
          IconButton(
            onPressed: user.status == 'Diblokir' || user.status == 'Baru' ? null : () => _banUser(user),
            tooltip: 'Blokir pengguna',
            icon: const Icon(Icons.block, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge(
      {required this.label, required this.value, required this.color});

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
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
          const SizedBox(width: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final VoidCallback onEditProfile;
  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogoutAdmin;
  final ValueChanged<String>? onShowToast;

  const AdminSettingsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.onEditProfile,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.onLogoutAdmin,
    this.onShowToast,
  });

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Tooltip(
                message: 'Ubah foto profil',
                child: InkWell(
                  onTap: widget.onEditProfile,
                  child: AppCachedImage(
                    imageUrl: widget.userAvatar ?? '',
                    width: 64,
                    height: 64,
                    isCircle: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Administrator',
                        style: TextStyle(
                            color: AppColors.secondary, fontSize: 12)),
                    Text(widget.userEmail,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('KEAMANAN',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: widget.onEditProfile,
              leading: const Icon(Icons.lock_reset, color: AppColors.primary),
              title: const Text('Ubah Kata Sandi di Profil',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('TAMPILAN & TEMA',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary)),
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
                title: const Text('Mode Gelap (Dark Mode)',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan tema gelap untuk kenyamanan mata',
                    style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.dark_mode_outlined,
                    color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        ElevatedButton.icon(
          onPressed: widget.onLogoutAdmin,
          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
          label: const Text('Keluar dari Sesi Admin',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ],
    );
  }
}
