import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<AppUser> onLoginSuccess;
  final VoidCallback onNavigateToRegister;
  final VoidCallback? onBackToGuest;
  final String? initialEmail;
  final ValueChanged<String>? onShowToast;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
    this.onBackToGuest,
    this.initialEmail,
    this.onShowToast,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController(text: 'kuliner123');
  bool _showPassword = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(
      text: widget.initialEmail ?? 'anna.roberts@email.com',
    );
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEmail != null && widget.initialEmail != oldWidget.initialEmail) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) {
      widget.onShowToast?.call('Silakan masukkan email atau nama pengguna Anda.');
      return;
    }
    if (_passCtrl.text.isEmpty) {
      widget.onShowToast?.call('Silakan masukkan kata sandi.');
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);

    final res = await AuthService.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.user != null) {
      widget.onLoginSuccess(res.user!);
    } else {
      widget.onShowToast?.call(
        res.message.isEmpty ? 'Login gagal. Coba lagi.' : res.message,
      );
    }
  }

  Future<void> _submitGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);

    final res = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.user != null) {
      widget.onLoginSuccess(res.user!);
    } else {
      widget.onShowToast?.call(
        res.message.isEmpty ? 'Login Google gagal. Coba lagi.' : res.message,
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      widget.onShowToast?.call('Masukkan email yang valid terlebih dahulu.');
      return;
    }
    final res = await AuthService.sendPasswordReset(email);
    widget.onShowToast?.call(
      res.message.isEmpty ? 'Gagal mengirim email pemulihan.' : res.message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          // Column di dalam scroll view: konten selalu mulai dari atas dan
          // bisa di-scroll, sehingga bagian atas (logo / tombol kembali)
          // tidak pernah terpotong walau tinggi jendela sempit.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Top Back to Guest option
            if (widget.onBackToGuest != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onBackToGuest,
                  icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.secondary),
                  label: const Text(
                    'Lanjut sebagai Tamu',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Logo Lockup
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.soup_kitchen, color: AppColors.primary, size: 32),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Selamat Datang Kembali!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Masuk untuk mengakses koleksi resep dan mulai memasak hidangan favoritmu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email atau Nama Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.secondary),
                      hintText: 'nama@email.com',
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.secondary),
                      hintText: 'Masukkan kata sandi',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                          ),
                          const Text('Ingat Saya', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Lupa Sandi?', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ATAU MASUK DENGAN',
                          style: TextStyle(color: AppColors.secondary, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _submitGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onShowToast?.call(
                              'Login Apple belum tersedia. Silakan masuk dengan email & kata sandi.',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Apple', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun?', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                TextButton(
                  onPressed: widget.onNavigateToRegister,
                  child: const Text(
                    'Daftar Sekarang',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final ValueChanged<AppUser> onRegisterSuccess;
  final VoidCallback onNavigateToLogin;
  final VoidCallback? onBackToGuest;
  final ValueChanged<String>? onShowToast;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onNavigateToLogin,
    this.onBackToGuest,
    this.onShowToast,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _agree = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      widget.onShowToast?.call('Mohon masukkan nama lengkap Anda.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      widget.onShowToast?.call('Mohon masukkan email yang valid.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      widget.onShowToast?.call('Kata sandi minimal 6 karakter.');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      widget.onShowToast?.call('Konfirmasi kata sandi belum sesuai.');
      return;
    }
    if (!_agree) {
      widget.onShowToast?.call('Silakan setujui syarat & ketentuan.');
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);

    final res = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok && res.user != null) {
      // Firebase Auth langsung memasukkan pengguna baru ke sesi,
      // jadi tidak perlu dilempar ke halaman login lagi.
      widget.onRegisterSuccess(res.user!);
    } else {
      widget.onShowToast?.call(
        res.message.isEmpty ? 'Registrasi gagal. Coba lagi.' : res.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          // Column di dalam scroll view: konten selalu mulai dari atas dan
          // bisa di-scroll, sehingga bagian atas (logo / tombol kembali)
          // tidak pernah terpotong walau tinggi jendela sempit.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Top Back to Guest option
            if (widget.onBackToGuest != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onBackToGuest,
                  icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.secondary),
                  label: const Text(
                    'Lanjut sebagai Tamu',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.soup_kitchen, color: AppColors.primary, size: 32),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Buat Akun Baru',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Daftar akun terlebih dahulu untuk mulai mengunggah resep kreasi Anda ke komunitas Resep Oma.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.secondary),
                      hintText: 'Misal: Budi Pratama',
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.secondary),
                      hintText: 'nama@email.com',
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.secondary),
                      hintText: 'Minimal 6 karakter',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Ulangi Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: !_showConfirm,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.secondary),
                      hintText: 'Ketik ulang kata sandi',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agree,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _agree = val ?? true),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi',
                            style: TextStyle(fontSize: 12, color: AppColors.secondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Daftar Sekarang & Lanjut Login', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun?', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                TextButton(
                  onPressed: widget.onNavigateToLogin,
                  child: const Text(
                    'Masuk di sini',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
