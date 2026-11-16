import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_cached_image.dart';
import '../widgets/notifications_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED ADMIN HEADER (Matches Stitch Top Bar Across All Admin Screens)
// ─────────────────────────────────────────────────────────────────────────────

class AdminHeader extends StatelessWidget {
  final String title;

  const AdminHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN PANEL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => NotificationsSheet.show(context),
                    icon: const Icon(Icons.notifications_outlined, size: 24),
                    color: AppColors.onSurfaceVariant,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1: KELOLA PENGGUNA (ID: 5fbb43abef374d718a0b9ba109092260)
// ─────────────────────────────────────────────────────────────────────────────

class AdminUsersScreen extends StatefulWidget {
  final ValueChanged<String>? onShowToast;

  const AdminUsersScreen({super.key, this.onShowToast});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'Semua';
  List<AdminUser> _users = [];
  bool _loading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);

    if (!RecipeService.isReady) {
      if (!mounted) return;
      setState(() {
        _users = MockData.getInitialUsers();
        _loading = false;
      });
      return;
    }

    final users = await RecipeService.fetchUsers();
    if (!mounted) return;

    setState(() {
      _users = users.isNotEmpty
          ? users.map(AdminUser.fromAppUser).toList()
          : MockData.getInitialUsers();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Tambah Administrator Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Contoh: Sarah Michaels',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Alamat Email',
                hintText: 'admin@gmail.com',
                prefixIcon: const Icon(Icons.mail_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun akan dibuat dengan peran Admin (akses penuh Panel Admin).',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                widget.onShowToast?.call('Mohon isi nama dan email administrator.');
                return;
              }
              final res = await RecipeService.createPendingUser(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                role: 'admin',
              );
              if (!mounted) return;
              if (context.mounted) Navigator.pop(context);
              widget.onShowToast?.call(
                res.message.isEmpty ? 'Administrator berhasil ditambahkan.' : res.message,
              );
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Simpan Administrator'),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(AdminUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  AppCachedImage(imageUrl: user.avatar, width: 44, height: 44, isCircle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${user.email} • ${user.code}', style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              ListTile(
                leading: Icon(user.status == 'Ditangguhkan' ? Icons.check_circle_outline : Icons.block, color: AppColors.primary),
                title: Text(user.status == 'Ditangguhkan' ? 'Aktifkan Akun' : 'Tangguhkan / Nonaktifkan Akun'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleUserStatus(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Akun Pengguna', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    final nextStatus = user.status == 'Ditangguhkan' ? 'active' : 'suspended';
    final res = await RecipeService.setUserStatus(user.id, nextStatus);
    if (!mounted) return;
    if (res.ok || !RecipeService.isReady) {
      setState(() {
        user.status = nextStatus == 'suspended' ? 'Ditangguhkan' : 'Aktif';
      });
    }
    widget.onShowToast?.call(
      res.message.isEmpty
          ? (nextStatus == 'suspended' ? 'Akun dinonaktifkan.' : 'Akun diaktifkan kembali.')
          : res.message,
    );
  }

  Future<void> _confirmDeleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: Text('Apakah Anda yakin ingin menghapus akun "${user.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await RecipeService.deleteUser(user.id);
      if (!mounted) return;
      if (res.ok || !RecipeService.isReady) {
        setState(() => _users.remove(user));
      }
      widget.onShowToast?.call(res.message.isEmpty ? 'Akun berhasil dihapus.' : res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _users.where((u) {
      final matchesQuery = query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.code.toLowerCase().contains(query) ||
          u.role.toLowerCase().contains(query);

      if (_activeFilter == 'Aktif') return matchesQuery && u.status == 'Aktif';
      if (_activeFilter == 'Kreator') return matchesQuery && u.role == 'Kreator';
      if (_activeFilter == 'Baru') return matchesQuery && u.status == 'Baru';
      if (_activeFilter == 'Ditangguhkan') return matchesQuery && u.status == 'Ditangguhkan';
      return matchesQuery;
    }).toList();

    final totalCount = '${_users.length}';
    final aktifCount = '${_users.where((u) => u.status == 'Aktif').length}';
    final baruCount = '${_users.where((u) => u.status == 'Baru').length}';
    final ditangguhkanCount = '${_users.where((u) => u.status == 'Ditangguhkan').length}';

    return Column(
      children: [
        const AdminHeader(title: 'Kelola Pengguna'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Intro Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Akun Terdaftar',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kelola hak akses, peran, dan status seluruh akun dalam ekosistem',
                          style: TextStyle(color: AppColors.secondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts, color: AppColors.primary, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metric Badges Row (Horizontally Scrollable)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPillMetric(
                      dotColor: AppColors.onSurface,
                      label: 'TOTAL',
                      value: totalCount,
                      bgColor: AppColors.surfaceContainerHigh,
                    ),
                    const SizedBox(width: 8),
                    _buildPillMetric(
                      dotColor: const Color(0xFF10B981),
                      label: 'AKTIF',
                      value: aktifCount,
                      bgColor: AppColors.surfaceContainerLowest,
                    ),
                    const SizedBox(width: 8),
                    _buildPillMetric(
                      dotColor: const Color(0xFFF59E0B),
                      label: 'BARU',
                      value: baruCount,
                      bgColor: AppColors.surfaceContainerLowest,
                    ),
                    const SizedBox(width: 8),
                    _buildPillMetric(
                      dotColor: AppColors.error,
                      label: 'DITANGGUHKAN',
                      value: ditangguhkanCount,
                      bgColor: AppColors.errorContainer.withValues(alpha: 0.6),
                      textColor: AppColors.onErrorContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Bar & Search Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.secondary),
                          hintText: 'Cari nama, email, role, atau ID...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.secondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addUserDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _activeFilter = 'Semua';
                        });
                        widget.onShowToast?.call('Filter direset');
                      },
                      icon: const Icon(Icons.tune, size: 20, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

               // Filter Chips Row
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 physics: const BouncingScrollPhysics(),
                 child: Row(
                   children: [
                     _buildFilterChip('Semua', 'Semua ($totalCount)'),
                     const SizedBox(width: 8),
                     _buildFilterChip('Aktif', 'Aktif ($aktifCount)'),
                     const SizedBox(width: 8),
                     _buildFilterChip('Kreator', 'Kreator (${_users.where((u) => u.role == 'Kreator').length})'),
                     const SizedBox(width: 8),
                     _buildFilterChip('Baru', 'Baru ($baruCount)'),
                     const SizedBox(width: 8),
                     _buildFilterChip('Ditangguhkan', 'Ditangguhkan ($ditangguhkanCount)'),
                   ],
                 ),
               ),
              const SizedBox(height: 16),

              // Responsive Table Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off, size: 36, color: AppColors.secondary),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tidak ada pengguna ditemukan.',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coba sesuaikan kata kunci atau filter.',
                                    style: TextStyle(color: AppColors.secondary.withValues(alpha: 0.8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 620),
                                  child: Column(
                                    children: [
                                      // Table Header
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        color: AppColors.surfaceContainerLow,
                                        child: const Row(
                                          children: [
                                            SizedBox(width: 220, child: Text('PENGGUNA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                            SizedBox(width: 140, child: Text('TINDAKAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                            SizedBox(width: 110, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                            SizedBox(width: 90, child: Text('TERDAFTAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                            SizedBox(width: 48, child: Text('AKSI', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                          ],
                                        ),
                                      ),

                                      // Table Rows
                                      ...filtered.map((user) {
                                        final isSuspended = user.status == 'Ditangguhkan';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: AppColors.surfaceContainerLow, width: 1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Pengguna Info
                                              SizedBox(
                                                width: 220,
                                                child: Row(
                                                  children: [
                                                    AppCachedImage(
                                                      imageUrl: user.avatar,
                                                      width: 40,
                                                      height: 40,
                                                      isCircle: true,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            user.name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                          ),
                                                          Text(
                                                            user.email,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(color: AppColors.secondary, fontSize: 11),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            user.code,
                                                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Tindakan Buttons
                                              SizedBox(
                                                width: 140,
                                                child: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () => _toggleUserStatus(user),
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              isSuspended ? Icons.check_circle_outline : Icons.block,
                                                              size: 13,
                                                              color: isSuspended ? const Color(0xFF10B981) : AppColors.onSurfaceVariant,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              isSuspended ? 'Aktifkan' : 'Nonaktifkan',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: isSuspended ? const Color(0xFF10B981) : AppColors.onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () => _confirmDeleteUser(user),
                                                      borderRadius: BorderRadius.circular(14),
                                                      child: Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.errorContainer.withValues(alpha: 0.5),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Status Badge
                                              SizedBox(
                                                width: 110,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: _buildStatusPill(user.status),
                                                ),
                                              ),

                                              // Terdaftar Date
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  user.registeredDate,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                                ),
                                              ),

                                              // Aksi
                                              SizedBox(
                                                width: 48,
                                                child: IconButton(
                                                  onPressed: () => _showUserOptions(user),
                                                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.secondary),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),

                               // Pagination & Footnote Footer
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                 color: AppColors.surfaceContainerLow,
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(
                                       'Menampilkan 1-${filtered.length} dari ${_users.length} akun',
                                       style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                     ),
                                    Row(
                                      children: [
                                        _buildPageBtn(icon: Icons.chevron_left, disabled: _currentPage == 1, onTap: () {}),
                                        const SizedBox(width: 4),
                                        _buildPageNumber('1', active: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
                                        const SizedBox(width: 4),
                                        _buildPageNumber('2', active: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
                                        const SizedBox(width: 4),
                                        _buildPageNumber('3', active: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
                                        const SizedBox(width: 4),
                                        const Text('...', style: TextStyle(color: AppColors.secondary, fontSize: 11)),
                                        const SizedBox(width: 4),
                                        _buildPageNumber('178', active: false, onTap: () {}),
                                        const SizedBox(width: 4),
                                        _buildPageBtn(icon: Icons.chevron_right, onTap: () => setState(() => _currentPage = 2)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillMetric({
    required Color dotColor,
    required String label,
    required String value,
    required Color bgColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor ?? AppColors.secondary)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor ?? AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final active = _activeFilter == filterId;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (val) {
        if (val) setState(() => _activeFilter = filterId);
      },
      selectedColor: AppColors.inverseSurface,
      backgroundColor: AppColors.surfaceContainerLowest,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppColors.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    Color dot;

    if (status == 'Aktif') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF1B5E20);
      dot = const Color(0xFF10B981);
    } else if (status == 'Ditangguhkan') {
      bg = AppColors.errorContainer;
      fg = AppColors.onErrorContainer;
      dot = AppColors.error;
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      dot = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  Widget _buildPageBtn({required IconData icon, bool disabled = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: disabled ? AppColors.secondary.withValues(alpha: 0.4) : AppColors.onSurface),
      ),
    );
  }

  Widget _buildPageNumber(String number, {required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          number,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2: KELOLA RESEP (ID: 5d43f0b483074a4ca05fffc856917574)
// ─────────────────────────────────────────────────────────────────────────────

class AdminRecipesScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onSelectRecipe;
  final ValueChanged<String>? onShowToast;

  const AdminRecipesScreen({
    super.key,
    required this.recipes,
    required this.onSelectRecipe,
    this.onShowToast,
  });

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'all';

  List<Map<String, dynamic>> _adminList = [];
  Map<String, int> _reportCounts = {};
  bool _loading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

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
    final reportCount = _reportCounts[recipe.id] ?? 0;
    return {
      'id': recipe.id,
      'title': recipe.title,
      'author': recipe.author,
      'code': recipe.code.startsWith('#') ? recipe.code : '#${recipe.code}',
      'likes': likesStr,
      'timeAgo': recipe.publishedAgo,
      'image': recipe.image,
      'reported': reportCount,
      'popular': likes >= 200,
      'category': recipe.category,
      'verified': recipe.verified,
    };
  }

  Future<void> _deleteRecipeAdmin(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep?'),
        content: Text('Apakah Anda yakin ingin menghapus resep "${item['title']}" dari publikasi komunitas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus Resep'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await RecipeService.deleteRecipe(item['id'] as String);
    if (!mounted) return;
    widget.onShowToast?.call(res.message.isEmpty ? '"${item['title']}" berhasil dihapus' : res.message);
    if (res.ok || !RecipeService.isReady) {
      setState(() {
        _adminList.removeWhere((r) => r['id'] == item['id']);
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onErrorContainer),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            '"${rep['reason']}"\nOleh: ${rep['reporterName'] ?? 'Anonim'} • ${isOpen ? 'Menunggu tinjauan' : 'Selesai ditinjau'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                          trailing: isOpen
                              ? TextButton(
                                  onPressed: () async {
                                    final res = await RecipeService.resolveReport(rep['id'] as String);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      widget.onShowToast?.call(
                                        res.message.isEmpty ? 'Laporan ditandai selesai.' : res.message,
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
      if (_activeFilter == 'category') return matchSearch && ((item['category'] as String?)?.isNotEmpty ?? false);
      return matchSearch;
    }).toList();

    final totalReports = _reportCounts.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: [
        const AdminHeader(title: 'Kelola Resep'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Sub Header & Overview
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
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
                      Text(
                        'Kelola Resep',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Kelola kurasi, tinjau kualitas hidangan kreator, dan moderasi resep yang dipublikasikan oleh komunitas pecinta kuliner.',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Stat Highlights
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.dinner_dining, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Total Resep: ', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                          Text(
                            '${_adminList.length}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
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
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search & Filter Controls
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.secondary),
                          hintText: 'Cari nama resep, bahan, penulis...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.secondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _activeFilter = 'all';
                        });
                        widget.onShowToast?.call('Filter direset');
                      },
                      icon: const Icon(Icons.tune, size: 20, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scrollable Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChip('all', 'Semua (${_adminList.length})'),
                    const SizedBox(width: 8),
                    _buildChip('popular', 'Populer (${_adminList.where((r) => r['popular'] as bool).length}) ⭐'),
                    const SizedBox(width: 8),
                    _buildChip('recent', 'Baru Ditambahkan'),
                    const SizedBox(width: 8),
                    _buildChip('category', 'Kategori Makanan'),
                    const SizedBox(width: 8),
                    _buildChip(
                      'reported',
                      'Dilaporkan ($totalReports)',
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recipe Table / List Section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.search_off, size: 28, color: AppColors.secondary),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tidak ada resep ditemukan',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coba gunakan kata kunci pencarian lain atau ganti filter kategori.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.secondary.withValues(alpha: 0.8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: AppColors.surfaceContainerLow,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('RESEP & PENULIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                    Text('TINDAKAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                              ...filtered.map((item) {
                                final reportedCount = item['reported'] as int;
                                final isReported = reportedCount > 0;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.surfaceContainerLow, width: 1),
                                    ),
                                  ),
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
                                                if (isReported)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.errorContainer,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.report, size: 10, color: AppColors.onErrorContainer),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'Tinjau',
                                                          style: TextStyle(
                                                            color: AppColors.onErrorContainer,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'oleh ${item['author']}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                const Icon(Icons.verified, size: 13, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                const Text('•', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item['code'] as String,
                                                  style: const TextStyle(color: AppColors.outline, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.thumb_up, size: 11, color: AppColors.tertiary),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${item['likes']}',
                                                  style: const TextStyle(color: AppColors.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text('•', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isReported ? '$reportedCount Laporan' : '${item['timeAgo']}',
                                                  style: TextStyle(
                                                    color: isReported ? AppColors.error : AppColors.secondary,
                                                    fontSize: 10,
                                                    fontWeight: isReported ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Action Buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              final match = widget.recipes.firstWhere(
                                                (r) => r.id == item['id'],
                                                orElse: () => widget.recipes.first,
                                              );
                                              widget.onSelectRecipe(match);
                                            },
                                            borderRadius: BorderRadius.circular(18),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                color: AppColors.surfaceContainerLow,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.onSurfaceVariant),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _deleteRecipeAdmin(item),
                                            borderRadius: BorderRadius.circular(18),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryFixed.withValues(alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
              ),
              const SizedBox(height: 16),

              // Interactive Pagination
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan 1-${filtered.length} dari ${_adminList.length} resep',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                  ),
                  Text(
                    'HALAMAN 1 DARI ${_filteredPageCount(filtered) > 0 ? _filteredPageCount(filtered) : 1}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageSquare(icon: Icons.chevron_left, disabled: _currentPage == 1, onTap: () {}),
                  const SizedBox(width: 6),
                  _buildPageSquare(text: '1', active: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
                  const SizedBox(width: 6),
                  _buildPageSquare(text: '2', active: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
                  const SizedBox(width: 6),
                  _buildPageSquare(text: '3', active: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
                  const SizedBox(width: 6),
                  const Text('...', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  _buildPageSquare(text: '120', active: false, onTap: () {}),
                  const SizedBox(width: 6),
                  _buildPageSquare(icon: Icons.chevron_right, onTap: () => setState(() => _currentPage = 2)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  int _filteredPageCount(List<Map<String, dynamic>> items, {int itemsPerPage = 7}) {
    return (items.length / itemsPerPage).ceil();
  }

  Widget _buildPageSquare({IconData? icon, String? text, bool active = false, bool disabled = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: disabled ? AppColors.secondary.withValues(alpha: 0.4) : AppColors.onSurface)
            : Text(
                text!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : AppColors.onSurface,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3: PENGATURAN ADMIN (ID: b742db107c96426d9be7ce4f2764774c)
// ─────────────────────────────────────────────────────────────────────────────

class AdminSettingsScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogoutAdmin;
  final ValueChanged<String>? onShowToast;
  final AppUser? currentUser;

  const AdminSettingsScreen({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
    required this.onLogoutAdmin,
    this.onShowToast,
    this.currentUser,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Ubah Kata Sandi Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Kata Sandi Baru',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onShowToast?.call('Kata sandi Admin berhasil diperbarui!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: widget.currentUser?.name ?? 'Admin Utama');
    final emailCtrl = TextEditingController(text: widget.currentUser?.email ?? 'admin@kuliner.app');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Profil Administrator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Admin')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Kontak')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onShowToast?.call('Profil Admin berhasil diperbarui');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Pengaturan Admin'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Profile Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const AppCachedImage(
                          imageUrl: MockImages.adminHeadChef,
                          width: 64,
                          height: 64,
                          isCircle: true,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.currentUser?.name ?? 'Admin Utama',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'AKTIF',
                                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('Super Administrator', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(widget.currentUser?.email ?? 'admin@kuliner.app', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _editProfileDialog,
                        icon: const Icon(Icons.edit, size: 18, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group 1: Keamanan
              const Row(
                children: [
                  Icon(Icons.lock, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'KEAMANAN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    onTap: _changePasswordDialog,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset, color: AppColors.onSurface, size: 20),
                    ),
                    title: const Text('Ubah Kata Sandi Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.onSurfaceVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Group 2: Tampilan & Tema
              const Row(
                children: [
                  Icon(Icons.palette, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'TAMPILAN & TEMA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurface, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.dark_mode, color: AppColors.onSurface, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Gunakan tema gelap untuk kenyamanan mata', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Switch(
                            value: widget.darkMode,
                            onChanged: widget.onToggleDarkMode,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.primary,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: AppColors.secondaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Logout Action
              ElevatedButton.icon(
                onPressed: widget.onLogoutAdmin,
                icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                label: const Text(
                  'Keluar dari Sesi Admin',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'ID Sesi: ADM-9482-KUL-2024 • Terenkripsi End-to-End',
                  style: TextStyle(color: AppColors.outline, fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
