import React, { useState } from 'react';
import {
  AdminUser,
  IMAGES,
  INITIAL_ADMIN_USERS,
  Recipe,
  ScreenId,
} from '../data/mockData';

// ============================================================================
// 6. LOGIN SCREEN (Image_11 / Image_12)
// ============================================================================
export const LoginScreen: React.FC<{
  onNavigate: (screen: ScreenId) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ onNavigate, showToast }) => {
  const [email, setEmail] = useState('anna.roberts@email.com');
  const [password, setPassword] = useState('kuliner123');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    showToast('Berhasil masuk! Selamat datang kembali, Anna.', 'check_circle');
    onNavigate('beranda');
  };

  return (
    <div className="flex flex-col w-full px-margin pb-space-xl">
      {/* Culinary Header & Accent Visual */}
      <div className="flex flex-col items-center text-center mt-space-md mb-space-lg">
        <div className="relative w-16 h-16 rounded-full bg-primary-fixed flex items-center justify-center mb-space-md shadow-sm">
          <span className="material-symbols-outlined text-primary text-[32px]">skillet</span>
          <div className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-primary flex items-center justify-center text-on-primary shadow-xs">
            <span className="material-symbols-outlined material-symbols-filled text-[12px]">
              local_fire_department
            </span>
          </div>
        </div>
        <h1 className="font-headline-lg text-headline-lg text-on-surface tracking-tight mb-space-xs">
          Selamat Datang Kembali!
        </h1>
        <p className="font-body-md text-body-md text-secondary max-w-[280px]">
          Masuk untuk mengakses koleksi resep dan mulai memasak hidangan favoritmu.
        </p>
      </div>

      {/* Main Card Container */}
      <div className="w-full bg-surface-container-lowest rounded-[2rem] p-space-md shadow-sm">
        <form className="flex flex-col gap-space-md" onSubmit={handleSubmit}>
          {/* Email Field */}
          <div className="flex flex-col gap-space-xs">
            <label className="font-label-lg text-label-lg text-on-surface" htmlFor="login-email">
              Email atau Nama Pengguna
            </label>
            <div className="relative flex items-center w-full">
              <span className="material-symbols-outlined absolute left-3.5 text-secondary text-[20px] pointer-events-none">
                mail
              </span>
              <input
                id="login-email"
                type="text"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@email.com"
                className="w-full h-12 pl-11 pr-4 bg-surface-container-low rounded-DEFAULT font-body-md text-body-md text-on-surface placeholder:text-secondary-fixed-dim focus:outline-none focus:bg-surface-container transition-colors"
              />
            </div>
          </div>

          {/* Password Field */}
          <div className="flex flex-col gap-space-xs">
            <label
              className="font-label-lg text-label-lg text-on-surface"
              htmlFor="login-password"
            >
              Kata Sandi
            </label>
            <div className="relative flex items-center w-full">
              <span className="material-symbols-outlined absolute left-3.5 text-secondary text-[20px] pointer-events-none">
                lock
              </span>
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Masukkan kata sandi"
                className="w-full h-12 pl-11 pr-12 bg-surface-container-low rounded-DEFAULT font-body-md text-body-md text-on-surface placeholder:text-secondary-fixed-dim focus:outline-none focus:bg-surface-container transition-colors"
              />
              <button
                type="button"
                onClick={() => setShowPassword((prev) => !prev)}
                aria-label="Tampilkan atau sembunyikan kata sandi"
                className="absolute right-3.5 w-8 h-8 rounded-full flex items-center justify-center text-secondary hover:text-on-surface active:scale-95 transition-all cursor-pointer"
              >
                <span className="material-symbols-outlined text-[20px]">
                  {showPassword ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
          </div>

          {/* Remember Me & Forgot Password */}
          <div className="flex items-center justify-between pt-space-xs">
            <label className="flex items-center gap-space-xs cursor-pointer select-none">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="w-4 h-4 rounded text-primary focus:ring-0 accent-primary cursor-pointer"
              />
              <span className="font-body-sm text-body-sm text-secondary">Ingat Saya</span>
            </label>
            <button
              type="button"
              onClick={() =>
                showToast('Tautan pemulihan kata sandi telah dikirim ke email Anda', 'mail')
              }
              className="font-label-md text-label-md text-primary hover:text-on-primary-fixed-variant transition-colors cursor-pointer"
            >
              Lupa Sandi?
            </button>
          </div>

          {/* Submit CTA Button */}
          <button
            type="submit"
            className="w-full h-12 mt-space-xs rounded-full bg-primary text-on-primary font-label-lg text-label-lg flex items-center justify-center gap-space-xs shadow-md active:scale-95 transition-all cursor-pointer"
          >
            <span>Masuk Sekarang</span>
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </form>

        {/* Visual Divider */}
        <div className="relative flex items-center justify-center my-space-lg">
          <div className="w-full h-px bg-surface-variant"></div>
          <span className="absolute px-space-sm bg-surface-container-lowest font-label-sm text-label-sm text-secondary uppercase tracking-wider whitespace-nowrap">
            atau masuk dengan
          </span>
        </div>

        {/* Social Authentication Options */}
        <div className="grid grid-cols-2 gap-space-sm">
          <button
            type="button"
            onClick={() => {
              showToast('Masuk dengan Google berhasil!', 'verified_user');
              onNavigate('beranda');
            }}
            className="h-11 px-space-md rounded-DEFAULT bg-surface-container-low flex items-center justify-center gap-space-sm font-label-md text-label-md text-on-surface hover:bg-surface-container active:scale-95 transition-all shadow-xs cursor-pointer"
          >
            <svg aria-hidden="true" className="w-4 h-4" viewBox="0 0 24 24">
              <path
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                fill="#4285F4"
              ></path>
              <path
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                fill="#34A853"
              ></path>
              <path
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                fill="#FBBC05"
              ></path>
              <path
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                fill="#EA4335"
              ></path>
            </svg>
            <span>Google</span>
          </button>
          <button
            type="button"
            onClick={() => {
              showToast('Masuk dengan Apple ID berhasil!', 'verified_user');
              onNavigate('beranda');
            }}
            className="h-11 px-space-md rounded-DEFAULT bg-surface-container-low flex items-center justify-center gap-space-sm font-label-md text-label-md text-on-surface hover:bg-surface-container active:scale-95 transition-all shadow-xs cursor-pointer"
          >
            <svg
              aria-hidden="true"
              className="w-4 h-4 fill-current text-on-surface"
              viewBox="0 0 24 24"
            >
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 0.93-2.85-.9.04-1.99.6-2.63 1.35-.57.65-.96 1.7-0.83 2.73 1.01.08 2.02-.53 2.53-1.23z"></path>
            </svg>
            <span>Apple</span>
          </button>
        </div>
      </div>

      {/* Sign Up Switcher Footer */}
      <div className="flex items-center justify-center gap-space-xs mt-space-lg text-center">
        <span className="font-body-md text-body-md text-secondary">Belum punya akun?</span>
        <button
          type="button"
          onClick={() => onNavigate('register')}
          className="font-label-lg text-label-lg text-primary hover:text-on-primary-fixed-variant active:scale-95 transition-all cursor-pointer"
        >
          Daftar Sekarang
        </button>
      </div>
    </div>
  );
};

// ============================================================================
// 7. REGISTER SCREEN (Image_19 / Image_20)
// ============================================================================
export const RegisterScreen: React.FC<{
  onNavigate: (screen: ScreenId) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ onNavigate, showToast }) => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [showConfirmPwd, setShowConfirmPwd] = useState(false);
  const [agreed, setAgreed] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (password && confirmPassword && password !== confirmPassword) {
      showToast('Konfirmasi kata sandi belum sesuai', 'error');
      return;
    }
    showToast('Akun baru berhasil dibuat! Selamat bergabung di Resep Oma.', 'celebration');
    onNavigate('beranda');
  };

  return (
    <div className="flex flex-col w-full px-margin pb-space-xl">
      <div className="flex flex-col items-center text-center mt-space-md mb-space-lg">
        <div className="relative w-16 h-16 rounded-full bg-primary-fixed flex items-center justify-center mb-space-md shadow-sm">
          <span className="material-symbols-outlined material-symbols-filled text-[32px] text-primary">
            skillet
          </span>
          <span className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-primary flex items-center justify-center shadow-md">
            <span className="material-symbols-outlined text-[14px] text-on-primary">star</span>
          </span>
        </div>
        <h1 className="font-headline-lg text-headline-lg text-on-surface tracking-tight mb-space-xs">
          Buat Akun Baru
        </h1>
        <p className="font-body-md text-body-md text-secondary max-w-[280px]">
          Bergabung bersama komunitas koki rumahan dan temukan ribuan inspirasi masakan lezat.
        </p>
      </div>

      <form className="flex flex-col gap-space-md" onSubmit={handleSubmit}>
        <div className="flex flex-col gap-1.5">
          <label className="font-label-md text-label-md text-on-surface" htmlFor="reg-name">
            Nama Lengkap
          </label>
          <div className="relative flex items-center">
            <span className="material-symbols-outlined absolute left-4 text-[20px] text-secondary pointer-events-none">
              person
            </span>
            <input
              id="reg-name"
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Misal: Anna Roberts"
              className="w-full bg-surface-container-low text-on-surface font-body-md text-body-md rounded-2xl pl-12 pr-4 py-3.5 focus:outline-none focus:bg-surface-container transition-colors placeholder:text-secondary-fixed-dim"
            />
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="font-label-md text-label-md text-on-surface" htmlFor="reg-email">
            Email
          </label>
          <div className="relative flex items-center">
            <span className="material-symbols-outlined absolute left-4 text-[20px] text-secondary pointer-events-none">
              mail
            </span>
            <input
              id="reg-email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="nama@email.com"
              className="w-full bg-surface-container-low text-on-surface font-body-md text-body-md rounded-2xl pl-12 pr-4 py-3.5 focus:outline-none focus:bg-surface-container transition-colors placeholder:text-secondary-fixed-dim"
            />
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="font-label-md text-label-md text-on-surface" htmlFor="reg-password">
            Kata Sandi
          </label>
          <div className="relative flex items-center">
            <span className="material-symbols-outlined absolute left-4 text-[20px] text-secondary pointer-events-none">
              lock
            </span>
            <input
              id="reg-password"
              type={showPwd ? 'text' : 'password'}
              minLength={8}
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Minimal 8 karakter"
              className="w-full bg-surface-container-low text-on-surface font-body-md text-body-md rounded-2xl pl-12 pr-12 py-3.5 focus:outline-none focus:bg-surface-container transition-colors placeholder:text-secondary-fixed-dim"
            />
            <button
              type="button"
              onClick={() => setShowPwd((prev) => !prev)}
              aria-label="Tampilkan sandi"
              className="absolute right-3.5 w-8 h-8 rounded-full flex items-center justify-center text-secondary active:scale-90 transition-transform cursor-pointer"
            >
              <span className="material-symbols-outlined text-[20px]">
                {showPwd ? 'visibility_off' : 'visibility'}
              </span>
            </button>
          </div>
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="font-label-md text-label-md text-on-surface" htmlFor="reg-confirm">
            Ulangi Kata Sandi
          </label>
          <div className="relative flex items-center">
            <span className="material-symbols-outlined absolute left-4 text-[20px] text-secondary pointer-events-none">
              lock
            </span>
            <input
              id="reg-confirm"
              type={showConfirmPwd ? 'text' : 'password'}
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Ketik ulang kata sandi"
              className="w-full bg-surface-container-low text-on-surface font-body-md text-body-md rounded-2xl pl-12 pr-12 py-3.5 focus:outline-none focus:bg-surface-container transition-colors placeholder:text-secondary-fixed-dim"
            />
            <button
              type="button"
              onClick={() => setShowConfirmPwd((prev) => !prev)}
              aria-label="Tampilkan konfirmasi sandi"
              className="absolute right-3.5 w-8 h-8 rounded-full flex items-center justify-center text-secondary active:scale-90 transition-transform cursor-pointer"
            >
              <span className="material-symbols-outlined text-[20px]">
                {showConfirmPwd ? 'visibility_off' : 'visibility'}
              </span>
            </button>
          </div>
        </div>

        <label className="flex items-start gap-3 mt-1 cursor-pointer select-none">
          <input
            type="checkbox"
            required
            checked={agreed}
            onChange={(e) => setAgreed(e.target.checked)}
            className="mt-1 w-5 h-5 rounded-lg accent-primary cursor-pointer shrink-0"
          />
          <span className="font-body-sm text-body-sm text-secondary leading-tight">
            Saya menyetujui{' '}
            <span className="font-label-md text-label-md text-primary">Syarat &amp; Ketentuan</span>{' '}
            serta <span className="font-label-md text-label-md text-primary">Kebijakan Privasi</span>
          </span>
        </label>

        <button
          type="submit"
          className="mt-2 w-full py-4 rounded-full bg-primary text-on-primary font-headline-sm text-headline-sm shadow-md active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
        >
          <span>Daftar Sekarang</span>
          <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
        </button>
      </form>

      <div className="relative flex items-center justify-center my-space-lg">
        <div className="w-full h-px bg-surface-container-high"></div>
        <span className="absolute bg-surface px-3 font-label-md text-label-md text-secondary">
          atau daftar dengan
        </span>
      </div>

      <div className="grid grid-cols-2 gap-space-md">
        <button
          type="button"
          onClick={() => {
            showToast('Pendaftaran via Google berhasil!', 'verified_user');
            onNavigate('beranda');
          }}
          className="flex items-center justify-center gap-2.5 py-3.5 px-4 rounded-2xl bg-surface-container-low active:bg-surface-container active:scale-95 transition-all cursor-pointer"
        >
          <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
            <path
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              fill="#4285F4"
            ></path>
            <path
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              fill="#34A853"
            ></path>
            <path
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              fill="#FBBC05"
            ></path>
            <path
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              fill="#EA4335"
            ></path>
          </svg>
          <span className="font-label-lg text-label-lg text-on-surface">Google</span>
        </button>

        <button
          type="button"
          onClick={() => {
            showToast('Pendaftaran via Apple ID berhasil!', 'verified_user');
            onNavigate('beranda');
          }}
          className="flex items-center justify-center gap-2.5 py-3.5 px-4 rounded-2xl bg-surface-container-low active:bg-surface-container active:scale-95 transition-all cursor-pointer"
        >
          <svg className="w-5 h-5 shrink-0 fill-on-surface" viewBox="0 0 24 24">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.36c.64-.78 1.08-1.86.96-2.94-1 .04-2.14.67-2.81 1.45-.58.67-1.1 1.76-.96 2.81 1.11.09 2.18-.54 2.81-1.32"></path>
          </svg>
          <span className="font-label-lg text-label-lg text-on-surface">Apple</span>
        </button>
      </div>

      <div className="mt-space-lg text-center">
        <p className="font-body-md text-body-md text-secondary">
          Sudah punya akun?{' '}
          <button
            type="button"
            onClick={() => onNavigate('login')}
            className="font-label-lg text-label-lg text-primary hover:underline ml-1 cursor-pointer"
          >
            Masuk di sini
          </button>
        </p>
      </div>
    </div>
  );
};

// ============================================================================
// 8. ADMIN PANEL: KELOLA RESEP (Image_13 / Image_14)
// ============================================================================
export const AdminRecipesScreen: React.FC<{
  recipes: Recipe[];
  onSelectRecipe: (recipe: Recipe) => void;
  onNavigate: (screen: ScreenId) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ onSelectRecipe, onNavigate, showToast }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);

  const [adminList, setAdminList] = useState([
    {
      id: 'RSP-3041',
      title: 'Nasi Lemak Sambal Sotong',
      author: 'Chef Kenji',
      verified: true,
      code: '#RSP-3041',
      likes: '2.8k',
      timeAgo: '2 jam lalu',
      image: IMAGES.adminNasiLemak,
      reported: 0,
      popular: true,
    },
    {
      id: 'RSP-3042',
      title: 'Spaghetti Carbonara Creamy',
      author: 'Sarah Michaels',
      verified: true,
      code: '#RSP-3042',
      likes: '1.4k',
      timeAgo: 'Kemarin',
      image: IMAGES.adminCarbonara,
      reported: 0,
      popular: true,
    },
    {
      id: 'RSP-3043',
      title: 'Dimsum Ayam Udang',
      author: 'Budi Santoso',
      verified: false,
      code: '#RSP-3043',
      likes: '942',
      timeAgo: '3 Laporan',
      image: IMAGES.adminDimsum,
      reported: 3,
      popular: false,
    },
    {
      id: 'RSP-3044',
      title: 'Ayam Bakar Madu Pedas',
      author: 'Dewi Lestari',
      verified: true,
      code: '#RSP-3044',
      likes: '3.1k',
      timeAgo: '3 hari lalu',
      image: IMAGES.adminAyamBakar,
      reported: 0,
      popular: true,
    },
    {
      id: 'RSP-3045',
      title: 'Matcha Mille Crepe',
      author: 'Maya Putri',
      verified: false,
      code: '#RSP-3045',
      likes: '875',
      timeAgo: '4 hari lalu',
      image: IMAGES.adminMatchaCrepe,
      reported: 0,
      popular: false,
    },
    {
      id: 'RSP-3046',
      title: 'Japanese Beef Curry',
      author: 'Chef Kenji',
      verified: true,
      code: '#RSP-3046',
      likes: '1.9k',
      timeAgo: '5 hari lalu',
      image: IMAGES.adminBeefCurry,
      reported: 0,
      popular: true,
    },
    {
      id: 'RSP-3047',
      title: 'Avocado Poached Egg Toast',
      author: 'Amanda Cole',
      verified: false,
      code: '#RSP-3047',
      likes: '650',
      timeAgo: '1 minggu lalu',
      image: IMAGES.adminAvocadoToast,
      reported: 0,
      popular: false,
    },
  ]);

  const filteredList = adminList.filter((item) => {
    const matchSearch =
      !searchQuery.trim() ||
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.author.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.code.toLowerCase().includes(searchQuery.toLowerCase());

    if (activeFilter === 'popular') return matchSearch && item.popular;
    if (activeFilter === 'reported') return matchSearch && item.reported > 0;
    return matchSearch;
  });

  const handleDeleteRow = (id: string, title: string) => {
    setAdminList((prev) => prev.filter((r) => r.id !== id));
    showToast(`"${title}" berhasil dihapus dari publikasi`, 'delete');
  };

  return (
    <div className="flex flex-col w-full px-margin pb-space-xl">
      {/* Sub Header & Overview */}
      <section className="flex flex-col gap-space-sm pt-space-md mb-space-lg">
        <div className="flex items-center justify-between">
          <div className="flex flex-col">
            <span className="font-label-sm text-label-sm uppercase tracking-wider text-primary font-bold">
              Koleksi Komunitas
            </span>
            <h2 className="font-headline-lg text-headline-lg text-on-surface">Kelola Resep</h2>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('unggah-resep')}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-primary text-on-primary font-label-md text-label-md shadow-sm active:scale-95 transition-transform whitespace-nowrap cursor-pointer"
          >
            <span className="material-symbols-outlined text-[16px]">add</span>
            <span>Buat Resep</span>
          </button>
        </div>
        <p className="font-body-sm text-body-sm text-on-surface-variant leading-relaxed">
          Kelola kurasi, tinjau kualitas hidangan kreator, dan moderasi resep yang dipublikasikan
          oleh komunitas pecinta kuliner.
        </p>
        {/* Stat Highlights */}
        <div className="grid gap-2 mt-2">
          <div className="flex flex-col p-3 rounded-2xl bg-surface-container-lowest shadow-sm">
            <div className="flex items-center gap-1 text-on-surface-variant mb-1">
              <span className="material-symbols-outlined text-[14px]">dinner_dining</span>
              <span className="font-label-sm text-label-sm">Total Resep</span>
            </div>
            <span className="font-headline-sm text-headline-sm text-on-surface font-extrabold tabular-nums">
              8.420
            </span>
          </div>
        </div>
      </section>

      {/* Search & Filter Controls */}
      <section className="flex flex-col gap-3 mb-space-lg">
        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
              search
            </span>
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-full bg-surface-container-lowest text-on-surface placeholder:text-on-surface-variant font-body-sm text-body-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
              placeholder="Cari nama resep, bahan, penulis..."
              type="text"
            />
          </div>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setActiveFilter('all');
              showToast('Filter moderasi direset', 'tune');
            }}
            aria-label="Filter Resep"
            className="w-10 h-10 rounded-full bg-surface-container-lowest flex items-center justify-center text-on-surface shadow-sm active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">tune</span>
          </button>
        </div>

        {/* Scrollable Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-0.5">
          {[
            { id: 'all', label: 'Semua (8.4k)' },
            { id: 'popular', label: 'Populer ⭐' },
            { id: 'new', label: 'Baru Ditambahkan' },
            { id: 'category', label: 'Kategori Makanan' },
          ].map((chip) => {
            const isActive = activeFilter === chip.id;
            return (
              <button
                key={chip.id}
                type="button"
                onClick={() => setActiveFilter(chip.id)}
                className={`px-3.5 py-1.5 rounded-full font-label-md text-label-md shrink-0 whitespace-nowrap transition-colors shadow-sm cursor-pointer ${
                  isActive
                    ? 'bg-inverse-surface text-inverse-on-surface'
                    : 'bg-surface-container-lowest text-on-surface-variant hover:text-on-surface'
                }`}
              >
                {chip.label}
              </button>
            );
          })}
          <button
            type="button"
            onClick={() => setActiveFilter('reported')}
            className={`px-3.5 py-1.5 rounded-full font-label-md text-label-md shrink-0 whitespace-nowrap transition-colors shadow-sm flex items-center gap-1 cursor-pointer ${
              activeFilter === 'reported'
                ? 'bg-error text-on-error'
                : 'bg-surface-container-lowest text-error'
            }`}
          >
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                activeFilter === 'reported' ? 'bg-on-error' : 'bg-error'
              }`}
            ></span>
            Dilaporkan (42)
          </button>
        </div>
      </section>

      {/* Recipe Table / List Section */}
      <section className="flex flex-col bg-surface-container-lowest rounded-2xl shadow-sm overflow-hidden mb-space-lg">
        <div className="flex items-center justify-between px-4 py-3 bg-surface-container-low text-on-surface-variant">
          <span className="font-label-sm text-label-sm uppercase tracking-wider font-bold">
            RESEP &amp; PENULIS
          </span>
          <span className="font-label-sm text-label-sm uppercase tracking-wider font-bold">
            TINDAKAN
          </span>
        </div>

        {filteredList.length > 0 ? (
          <div className="flex flex-col">
            {filteredList.map((item, idx) => (
              <article
                key={item.id}
                className={`flex items-center justify-between p-3.5 transition-colors hover:bg-surface-container-low/50 ${
                  idx % 2 === 1 ? 'bg-surface-container-low/20' : ''
                }`}
              >
                <div className="flex items-center gap-3 min-w-0 pr-2">
                  <div className="relative shrink-0 w-12 h-12 rounded-full overflow-hidden shadow-sm bg-surface-container-high">
                    <img
                      className="w-full h-full object-cover"
                      alt={item.title}
                      src={item.image}
                      referrerPolicy="no-referrer"
                    />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <div className="flex items-center gap-1.5">
                      <h3 className="font-headline-sm text-headline-sm text-on-surface truncate">
                        {item.title}
                      </h3>
                      {item.reported > 0 && (
                        <span className="px-1.5 py-0.5 rounded-full bg-error-container text-on-error-container font-label-sm text-label-sm font-bold flex items-center gap-0.5 shrink-0">
                          <span className="material-symbols-outlined text-[10px]">report</span>
                          Tinjau
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                      <span className="font-body-sm text-body-sm text-on-surface-variant truncate">
                        oleh <span className="font-semibold text-on-surface">{item.author}</span>
                      </span>
                      {item.verified && (
                        <span className="material-symbols-outlined material-symbols-filled text-primary text-[14px]">
                          verified
                        </span>
                      )}
                      <span className="text-on-surface-variant text-[10px]">•</span>
                      <span className="font-label-sm text-label-sm text-outline">{item.code}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="inline-flex items-center gap-0.5 font-label-sm text-label-sm text-tertiary font-bold">
                        <span className="material-symbols-outlined material-symbols-filled text-[13px]">
                          thumb_up
                        </span>
                        {item.likes}
                      </span>
                      <span className="text-on-surface-variant text-[10px]">•</span>
                      <span
                        className={`font-body-sm text-body-sm ${
                          item.reported > 0 ? 'text-error font-medium' : 'text-on-surface-variant'
                        }`}
                      >
                        {item.timeAgo}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    type="button"
                    onClick={() => {
                      showToast(`Membuka moderasi ${item.code}: ${item.title}`, 'visibility');
                      onSelectRecipe({
                        id: item.id,
                        code: item.code,
                        title: item.title,
                        description:
                          'Resep kurasi komunitas yang sedang ditinjau kualitas foto dan takaran bahan masakannya.',
                        category: 'Kurasi Komunitas',
                        filterKey: 'asian',
                        author: item.author,
                        likes: item.likes,
                        likesCount: 1500,
                        time: '35 Menit',
                        servings: '3 Porsi',
                        difficulty: 'Menengah',
                        image: item.image,
                        isFavorite: false,
                        publishedAgo: item.timeAgo,
                        ingredients: [
                          { id: '1', name: 'Bahan Utama Pilihan Segar', amount: '350 gram' },
                          { id: '2', name: 'Racikan Bumbu Rempah Komunitas', amount: '4 sdm' },
                        ],
                        steps: [
                          {
                            id: '1',
                            title: 'Persiapan Bahan & Marinasi',
                            description:
                              'Siapkan bahan segar sesuai takaran standar kurasi Resep Oma.',
                          },
                          {
                            id: '2',
                            title: 'Pemasakan & Penyajian',
                            description: 'Masak hingga matang merata dan sajikan hangat.',
                          },
                        ],
                      });
                    }}
                    aria-label="Tinjau Resep"
                    className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high active:scale-95 transition-all cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-[18px]">visibility</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeleteRow(item.id, item.title)}
                    aria-label="Hapus Resep"
                    className="w-9 h-9 rounded-full bg-primary-fixed/40 text-primary flex items-center justify-center hover:bg-primary hover:text-on-primary active:scale-95 transition-all cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-[18px]">delete</span>
                  </button>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center p-8 text-center">
            <div className="w-14 h-14 rounded-full bg-surface-container-high flex items-center justify-center text-on-surface-variant mb-3">
              <span className="material-symbols-outlined text-[28px]">search_off</span>
            </div>
            <h4 className="font-headline-sm text-headline-sm text-on-surface font-bold">
              Tidak ada resep ditemukan
            </h4>
            <p className="font-body-sm text-body-sm text-on-surface-variant mt-1 max-w-[240px]">
              Coba gunakan kata kunci pencarian lain atau ganti filter kategori.
            </p>
          </div>
        )}
      </section>

      {/* Interactive Pagination */}
      <section className="flex flex-col items-center gap-3">
        <div className="flex items-center justify-between w-full">
          <span className="font-body-sm text-body-sm text-on-surface-variant">
            Menampilkan{' '}
            <span className="font-semibold text-on-surface tabular-nums">
              1–{filteredList.length}
            </span>{' '}
            dari <span className="font-semibold text-on-surface tabular-nums">8.420</span> resep
          </span>
          <span className="font-label-sm text-label-sm text-primary font-bold uppercase tracking-wider">
            HALAMAN {currentPage} DARI 120
          </span>
        </div>
        <div className="flex items-center justify-center gap-1.5 w-full py-1">
          <button
            type="button"
            disabled={currentPage === 1}
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            aria-label="Halaman Sebelumnya"
            className="w-9 h-9 rounded-full bg-surface-container-lowest text-on-surface flex items-center justify-center shadow-sm disabled:opacity-40 active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">chevron_left</span>
          </button>
          {[1, 2, 3].map((page) => (
            <button
              key={page}
              type="button"
              onClick={() => {
                setCurrentPage(page);
                showToast(`Halaman ${page} dimuat`, 'menu_book');
              }}
              className={`w-9 h-9 rounded-full font-label-md text-label-md flex items-center justify-center shadow-sm active:scale-95 transition-all cursor-pointer ${
                currentPage === page
                  ? 'bg-primary text-on-primary font-bold'
                  : 'bg-surface-container-lowest text-on-surface font-medium hover:bg-surface-container'
              }`}
            >
              {page}
            </button>
          ))}
          <div className="w-7 h-9 flex items-center justify-center text-on-surface-variant">
            <span className="material-symbols-outlined text-[16px]">more_horiz</span>
          </div>
          <button
            type="button"
            onClick={() => setCurrentPage(120)}
            className={`w-9 h-9 rounded-full font-label-md text-label-md flex items-center justify-center shadow-sm active:scale-95 transition-all cursor-pointer ${
              currentPage === 120
                ? 'bg-primary text-on-primary font-bold'
                : 'bg-surface-container-lowest text-on-surface font-medium hover:bg-surface-container'
            }`}
          >
            120
          </button>
          <button
            type="button"
            onClick={() => setCurrentPage((p) => Math.min(120, p + 1))}
            aria-label="Halaman Berikutnya"
            className="w-9 h-9 rounded-full bg-surface-container-lowest text-on-surface flex items-center justify-center shadow-sm hover:bg-surface-container active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">chevron_right</span>
          </button>
        </div>
      </section>
    </div>
  );
};

// ============================================================================
// 9. ADMIN PANEL: KELOLA PENGGUNA (Image_15 / Image_16)
// ============================================================================
export const AdminUsersScreen: React.FC<{
  showToast: (msg: string, icon?: string) => void;
}> = ({ showToast }) => {
  const [users, setUsers] = useState<AdminUser[]>(INITIAL_ADMIN_USERS);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('Semua');
  const [showAddModal, setShowAddModal] = useState(false);
  const [newUserName, setNewUserName] = useState('');
  const [newUserEmail, setNewUserEmail] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  const filteredUsers = users.filter((u) => {
    const matchQuery =
      !searchQuery.trim() ||
      u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.code.toLowerCase().includes(searchQuery.toLowerCase());

    if (activeFilter === 'Aktif') return matchQuery && u.status === 'Aktif';
    if (activeFilter === 'Kreator') return matchQuery && u.role === 'Kreator';
    if (activeFilter === 'Baru') return matchQuery && u.status === 'Baru';
    if (activeFilter === 'Ditangguhkan') return matchQuery && u.status === 'Ditangguhkan';
    return matchQuery;
  });

  const toggleUserStatus = (id: string) => {
    setUsers((prev) =>
      prev.map((u) => {
        if (u.id !== id) return u;
        const nextStatus = u.status === 'Ditangguhkan' ? 'Aktif' : 'Ditangguhkan';
        showToast(`Status akun ${u.name} diubah menjadi ${nextStatus}`, 'manage_accounts');
        return { ...u, status: nextStatus };
      })
    );
  };

  const deleteUser = (id: string, name: string) => {
    setUsers((prev) => prev.filter((u) => u.id !== id));
    showToast(`Akun ${name} telah dihapus`, 'delete');
  };

  const handleAddUser = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUserName.trim() || !newUserEmail.trim()) return;
    const created: AdminUser = {
      id: String(Date.now()),
      code: `#USR-${Math.floor(1260 + Math.random() * 500)}`,
      name: newUserName.trim(),
      email: newUserEmail.trim(),
      avatar: IMAGES.userDewi,
      status: 'Baru',
      role: 'Kreator',
      registeredDate: 'Hari ini',
    };
    setUsers((prev) => [created, ...prev]);
    setNewUserName('');
    setNewUserEmail('');
    setShowAddModal(false);
    showToast(`Akun ${created.name} berhasil ditambahkan`, 'person_add');
  };

  return (
    <div className="flex flex-col w-full pb-8">
      {/* Top Intro Section */}
      <div className="px-margin pt-2 pb-4 flex flex-col gap-1">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="font-headline-md text-headline-md text-on-surface tracking-tight">
              Daftar Akun Terdaftar
            </h2>
            <p className="font-body-sm text-body-sm text-secondary mt-0.5">
              Kelola hak akses, peran, dan status seluruh akun dalam ekosistem
            </p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary-fixed flex items-center justify-center text-primary shadow-sm shrink-0">
            <span className="material-symbols-outlined text-[22px]">manage_accounts</span>
          </div>
        </div>
      </div>

      {/* Metric Badges Row */}
      <div className="px-margin mb-5">
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1 -my-1">
          <div className="flex items-center gap-2 px-3.5 py-2 rounded-full bg-surface-container-high shadow-sm shrink-0">
            <span className="w-2 h-2 rounded-full bg-on-surface"></span>
            <span className="font-label-sm text-label-sm text-secondary uppercase tracking-wider">
              Total
            </span>
            <span className="font-headline-sm text-headline-sm text-on-surface font-bold tabular-nums">
              12.450
            </span>
          </div>
          <div className="flex items-center gap-2 px-3.5 py-2 rounded-full bg-surface-container-lowest shadow-sm shrink-0">
            <span className="w-2 h-2 rounded-full bg-[#10b981]"></span>
            <span className="font-label-sm text-label-sm text-secondary uppercase tracking-wider">
              Aktif
            </span>
            <span className="font-headline-sm text-headline-sm text-on-surface font-bold tabular-nums">
              11.890
            </span>
          </div>
          <div className="flex items-center gap-2 px-3.5 py-2 rounded-full bg-surface-container-lowest shadow-sm shrink-0">
            <span className="w-2 h-2 rounded-full bg-[#f59e0b]"></span>
            <span className="font-label-sm text-label-sm text-secondary uppercase tracking-wider">
              Baru
            </span>
            <span className="font-headline-sm text-headline-sm text-on-surface font-bold tabular-nums">
              1.240
            </span>
          </div>
          <div className="flex items-center gap-2 px-3.5 py-2 rounded-full bg-error-container shadow-sm shrink-0">
            <span className="w-2 h-2 rounded-full bg-error"></span>
            <span className="font-label-sm text-label-sm text-on-error-container uppercase tracking-wider">
              Ditangguhkan
            </span>
            <span className="font-headline-sm text-headline-sm text-on-error-container font-bold tabular-nums">
              15
            </span>
          </div>
        </div>
      </div>

      {/* Action Bar & Search */}
      <div className="px-margin flex flex-col gap-3 mb-5">
        <div className="flex items-center justify-between gap-2">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary text-[20px]">
              search
            </span>
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full h-11 pl-10 pr-4 rounded-full bg-surface-container-lowest text-on-surface font-body-sm text-body-sm placeholder:text-secondary/70 shadow-sm outline-none focus:bg-surface-container-high transition-colors"
              placeholder="Cari nama, email, role, atau ID..."
              type="text"
            />
          </div>
          <button
            type="button"
            onClick={() => setShowAddModal((prev) => !prev)}
            className="h-11 px-4 rounded-full bg-primary-container text-on-primary-container font-label-md text-label-md flex items-center gap-1.5 shadow-sm active:scale-95 transition-transform shrink-0 whitespace-nowrap cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">person_add</span>
            <span>Tambah</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setActiveFilter('Semua');
              showToast('Filter pengguna direset', 'tune');
            }}
            className="w-11 h-11 rounded-full bg-surface-container-lowest text-on-surface font-label-md flex items-center justify-center shadow-sm active:scale-95 transition-transform shrink-0 cursor-pointer"
            title="Opsi Filter & Ekspor"
          >
            <span className="material-symbols-outlined text-[20px]">tune</span>
          </button>
        </div>

        {showAddModal && (
          <form
            onSubmit={handleAddUser}
            className="p-4 rounded-2xl bg-surface-container-lowest shadow-md space-y-3"
          >
            <h4 className="font-headline-sm text-headline-sm text-on-surface">
              Tambah Akun Pengguna Baru
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <input
                type="text"
                required
                value={newUserName}
                onChange={(e) => setNewUserName(e.target.value)}
                placeholder="Nama lengkap pengguna"
                className="px-3.5 py-2.5 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
              <input
                type="email"
                required
                value={newUserEmail}
                onChange={(e) => setNewUserEmail(e.target.value)}
                placeholder="Alamat email"
                className="px-3.5 py-2.5 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
            </div>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="px-3.5 py-1.5 rounded-full bg-surface-container text-on-surface-variant font-label-md text-label-md"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-4 py-1.5 rounded-full bg-primary text-on-primary font-label-md text-label-md"
              >
                Simpan Akun
              </button>
            </div>
          </form>
        )}

        {/* Filter Chips Row */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-0.5">
          {[
            { id: 'Semua', label: 'Semua (12.4k)' },
            { id: 'Aktif', label: 'Aktif (11.8k)' },
            { id: 'Kreator', label: 'Kreator (3.2k)' },
            { id: 'Baru', label: 'Baru (1.2k)' },
            { id: 'Ditangguhkan', label: 'Ditangguhkan (15)' },
          ].map((chip) => {
            const isActive = activeFilter === chip.id;
            return (
              <button
                key={chip.id}
                type="button"
                onClick={() => setActiveFilter(chip.id)}
                className={`px-3.5 py-1.5 rounded-full font-label-sm text-label-sm font-semibold shadow-sm shrink-0 whitespace-nowrap active:scale-95 transition-all cursor-pointer ${
                  isActive
                    ? 'bg-inverse-surface text-inverse-on-surface'
                    : 'bg-surface-container-lowest text-on-surface-variant hover:bg-surface-container-high'
                }`}
              >
                {chip.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* User List Container (matching Image_15 & Image_16) */}
      <div className="px-margin mb-4">
        <div className="bg-surface-container-lowest rounded-2xl shadow-sm overflow-hidden flex flex-col">
          <div className="flex items-center justify-between py-3 px-4 bg-surface-container-low text-secondary font-label-sm text-label-sm uppercase tracking-wider font-semibold">
            <span>PENGGUNA</span>
            <span>TINDAKAN</span>
          </div>

          <div className="divide-y divide-surface-container/60">
            {filteredUsers.map((user, idx) => (
              <div
                key={user.id}
                className={`flex items-center justify-between py-3.5 px-4 transition-colors hover:bg-surface-container-low/60 ${
                  idx % 2 === 1 ? 'bg-surface-container-low/20' : ''
                }`}
              >
                <div className="flex items-center gap-3 min-w-0 pr-2">
                  <div className="relative w-10 h-10 rounded-full overflow-hidden shrink-0 shadow-xs bg-surface-container">
                    <img
                      className="w-full h-full object-cover"
                      alt={user.name}
                      src={user.avatar}
                      referrerPolicy="no-referrer"
                    />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <span className="font-label-lg text-label-lg text-on-surface font-bold truncate">
                      {user.name}
                    </span>
                    <span className="font-body-sm text-body-sm text-secondary truncate">
                      {user.email}
                    </span>
                    <div className="flex items-center gap-2 mt-0.5">
                      <span className="font-label-sm text-label-sm text-primary font-semibold tracking-wide">
                        {user.code}
                      </span>
                      {user.status === 'Ditangguhkan' && (
                        <span className="px-1.5 py-0.5 rounded-full bg-error-container text-on-error-container font-label-sm text-[10px]">
                          Nonaktif
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    type="button"
                    onClick={() => toggleUserStatus(user.id)}
                    className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-label-sm text-label-sm font-semibold active:scale-95 transition-all whitespace-nowrap cursor-pointer ${
                      user.status === 'Ditangguhkan'
                        ? 'bg-primary-fixed text-primary'
                        : 'bg-secondary-container hover:bg-surface-container-high text-on-secondary-container'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[14px]">
                      {user.status === 'Ditangguhkan' ? 'check_circle' : 'block'}
                    </span>
                    <span>{user.status === 'Ditangguhkan' ? 'Aktifkan' : 'Nonaktifkan'}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => deleteUser(user.id, user.name)}
                    className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-error-container hover:bg-error text-on-error-container hover:text-on-error active:scale-95 transition-all cursor-pointer"
                    title="Hapus akun"
                  >
                    <span className="material-symbols-outlined text-[14px]">delete</span>
                  </button>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination & Footnote Footer */}
          <div className="p-3.5 bg-surface-container-low flex flex-col items-center justify-between gap-3">
            <div className="text-secondary font-label-sm text-label-sm text-center">
              Menampilkan{' '}
              <span className="font-semibold text-on-surface tabular-nums">
                1–{filteredUsers.length}
              </span>{' '}
              dari <span className="font-semibold text-on-surface tabular-nums">12.450</span> akun
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                className="w-8 h-8 rounded-full bg-surface-container-lowest text-secondary hover:text-on-surface flex items-center justify-center shadow-xs disabled:opacity-40 cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              {[1, 2, 3].map((page) => (
                <button
                  key={page}
                  type="button"
                  onClick={() => setCurrentPage(page)}
                  className={`w-8 h-8 rounded-full font-label-sm text-label-sm flex items-center justify-center shadow-xs cursor-pointer ${
                    currentPage === page
                      ? 'bg-primary-container text-on-primary-container font-bold'
                      : 'bg-surface-container-lowest text-on-surface font-semibold hover:bg-surface-container'
                  }`}
                >
                  {page}
                </button>
              ))}
              <span className="px-1 text-secondary font-label-sm">...</span>
              <button
                type="button"
                onClick={() => setCurrentPage(178)}
                className={`w-8 h-8 rounded-full font-label-sm text-label-sm flex items-center justify-center shadow-xs cursor-pointer ${
                  currentPage === 178
                    ? 'bg-primary-container text-on-primary-container font-bold'
                    : 'bg-surface-container-lowest text-on-surface font-semibold hover:bg-surface-container'
                }`}
              >
                178
              </button>
              <button
                type="button"
                onClick={() => setCurrentPage((p) => Math.min(178, p + 1))}
                className="w-8 h-8 rounded-full bg-surface-container-lowest text-on-surface flex items-center justify-center shadow-xs hover:bg-surface-container active:scale-95 cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// 10. ADMIN PANEL: PENGATURAN ADMIN (Image_17 / Image_18)
// ============================================================================
export const AdminSettingsScreen: React.FC<{
  darkMode: boolean;
  onToggleDarkMode: () => void;
  onNavigate: (screen: ScreenId) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ darkMode, onToggleDarkMode, onNavigate, showToast }) => {
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [newPass, setNewPass] = useState('');

  return (
    <div className="flex flex-col w-full px-margin pb-space-xl space-y-space-lg pt-space-sm">
      {/* Profile Summary Card */}
      <section className="bg-surface-container-lowest rounded-[2rem] p-space-md shadow-sm relative overflow-hidden">
        <div className="flex items-center gap-space-md">
          <div className="relative w-16 h-16 rounded-full overflow-hidden shrink-0 shadow-sm">
            <img
              className="w-full h-full object-cover"
              alt="Admin Utama"
              src={IMAGES.adminHeadChef}
              referrerPolicy="no-referrer"
            />
            <span
              className="absolute bottom-0 right-0 w-4 h-4 rounded-full bg-primary ring-2 ring-surface-container-lowest"
              title="Aktif Online"
            ></span>
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-space-xs mb-0.5">
              <h2 className="font-headline-sm text-headline-sm text-on-surface truncate">
                Admin Utama
              </h2>
              <span className="px-2 py-0.5 rounded-full bg-primary/10 text-primary font-label-sm text-label-sm uppercase font-bold tracking-wider">
                Aktif
              </span>
            </div>
            <p className="font-body-sm text-body-sm text-secondary truncate">Super Administrator</p>
            <p className="font-label-md text-label-md text-on-surface-variant truncate mt-0.5">
              admin@kuliner.app
            </p>
          </div>
          <button
            type="button"
            onClick={() => showToast('Profil Administrator Utama terverifikasi', 'verified')}
            aria-label="Edit Profil"
            className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">edit</span>
          </button>
        </div>
      </section>

      {/* Group 1: Keamanan & Autentikasi */}
      <section className="space-y-space-sm">
        <div className="flex items-center gap-space-xs px-space-xs">
          <span className="material-symbols-outlined text-primary text-[20px]">lock</span>
          <h3 className="font-label-lg text-label-lg text-on-surface uppercase tracking-wide">
            Keamanan
          </h3>
        </div>
        <div className="bg-surface-container-lowest rounded-[2rem] shadow-sm overflow-hidden">
          <button
            type="button"
            onClick={() => setShowPasswordModal((prev) => !prev)}
            className="w-full p-space-md flex items-center justify-between gap-space-sm bg-surface-container-lowest hover:bg-surface-container-low transition-colors active:scale-[0.99] text-left cursor-pointer"
          >
            <div className="flex items-center gap-space-sm flex-1 min-w-0">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-on-surface text-[20px]">
                  lock_reset
                </span>
              </div>
              <p className="font-body-lg text-body-lg text-on-surface truncate">
                Ubah Kata Sandi Admin
              </p>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant text-[20px] shrink-0">
              chevron_right
            </span>
          </button>

          {showPasswordModal && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                setShowPasswordModal(false);
                setNewPass('');
                showToast('Kata sandi Admin berhasil diperbarui!', 'lock');
              }}
              className="px-space-md pb-space-md pt-1 space-y-2 border-t border-surface-container"
            >
              <input
                type="password"
                required
                value={newPass}
                onChange={(e) => setNewPass(e.target.value)}
                placeholder="Masukkan kata sandi admin baru..."
                className="w-full px-3.5 py-2.5 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowPasswordModal(false)}
                  className="px-3 py-1.5 rounded-full bg-surface-container text-on-surface-variant font-label-md text-label-md"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 rounded-full bg-primary text-on-primary font-label-md text-label-md"
                >
                  Simpan Sandi
                </button>
              </div>
            </form>
          )}
        </div>
      </section>

      {/* Group 2: Tampilan & Tema */}
      <section className="space-y-space-sm">
        <div className="flex items-center gap-space-xs px-space-xs">
          <span className="material-symbols-outlined text-primary text-[20px]">palette</span>
          <h3 className="font-label-lg text-label-lg text-on-surface uppercase tracking-wide">
            Tampilan &amp; Tema
          </h3>
        </div>
        <div className="bg-surface-container-lowest rounded-[2rem] shadow-sm overflow-hidden">
          <div className="p-space-md flex items-center justify-between gap-space-sm bg-surface-container-lowest">
            <div className="flex items-start gap-space-sm flex-1 min-w-0">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center shrink-0 mt-0.5">
                <span className="material-symbols-outlined text-on-surface text-[20px]">
                  dark_mode
                </span>
              </div>
              <div className="min-w-0">
                <p className="font-headline-sm text-headline-sm text-on-surface">
                  Mode Gelap (Dark Mode)
                </p>
                <p className="font-body-sm text-body-sm text-on-surface-variant mt-0.5">
                  Gunakan tema gelap untuk kenyamanan mata
                </p>
              </div>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={darkMode}
              onClick={onToggleDarkMode}
              className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full transition-colors duration-200 ease-in-out focus:outline-none ${
                darkMode ? 'bg-primary' : 'bg-secondary-fixed'
              }`}
            >
              <span
                className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-surface-container-lowest shadow-sm ring-0 transition duration-200 ease-in-out mt-0.5 ml-0.5 ${
                  darkMode ? 'translate-x-5' : 'translate-x-0'
                }`}
              ></span>
            </button>
          </div>
        </div>
      </section>

      {/* Logout Action */}
      <div className="pt-space-xs">
        <button
          type="button"
          onClick={() => {
            showToast('Keluar dari sesi Admin Panel', 'logout');
            onNavigate('beranda');
          }}
          className="w-full flex items-center justify-center gap-space-sm py-3.5 px-space-md rounded-[2rem] bg-surface-container-lowest text-error shadow-sm hover:bg-error-container/20 active:scale-95 transition-all cursor-pointer"
        >
          <span className="material-symbols-outlined text-[20px]">logout</span>
          <span className="font-headline-sm text-headline-sm">Keluar dari Sesi Admin</span>
        </button>
        <p className="text-center font-label-sm text-label-sm text-on-surface-variant/70 mt-space-sm">
          ID Sesi: ADM-9482-KUL-2024 • Terenkripsi End-to-End
        </p>
      </div>
    </div>
  );
};
