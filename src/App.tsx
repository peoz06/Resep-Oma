import React, { useEffect, useState } from 'react';
import {
  AdminRecipesScreen,
  AdminSettingsScreen,
  AdminUsersScreen,
  LoginScreen,
  RegisterScreen,
} from './components/AuthAndAdminScreens';
import { AiFridgeModal, NotificationsModal, RecipeDetailModal } from './components/Modals';
import {
  BerandaScreen,
  EksplorScreen,
  FavoritScreen,
  ProfilScreen,
  UnggahResepScreen,
} from './components/UserScreens';
import { INITIAL_RECIPES, Recipe, ScreenId } from './data/mockData';

const SCREEN_LABELS: { id: ScreenId; label: string; group: 'User' | 'Auth' | 'Admin' }[] = [
  { id: 'beranda', label: 'Beranda', group: 'User' },
  { id: 'eksplor', label: 'Eksplor', group: 'User' },
  { id: 'unggah-resep', label: 'Unggah Resep', group: 'User' },
  { id: 'favorit', label: 'Favorit', group: 'User' },
  { id: 'profil', label: 'Profil', group: 'User' },
  { id: 'login', label: 'Login', group: 'Auth' },
  { id: 'register', label: 'Register', group: 'Auth' },
  { id: 'admin-recipes', label: 'Kelola Resep', group: 'Admin' },
  { id: 'admin-users', label: 'Kelola Pengguna', group: 'Admin' },
  { id: 'admin-settings', label: 'Pengaturan Admin', group: 'Admin' },
];

export default function App() {
  const [activeScreen, setActiveScreen] = useState<ScreenId>('beranda');
  const [previousScreen, setPreviousScreen] = useState<ScreenId>('beranda');
  const [recipes, setRecipes] = useState<Recipe[]>(INITIAL_RECIPES);
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);
  const [aiModalOpen, setAiModalOpen] = useState(false);
  const [notifModalOpen, setNotifModalOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const [toast, setToast] = useState<{ message: string; icon: string } | null>(null);
  const [userProfile, setUserProfile] = useState({
    name: 'Anna Roberts',
    email: 'anna.roberts@email.com',
    handle: '@annacooks',
  });

  useEffect(() => {
    const root = document.documentElement;
    if (darkMode) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [darkMode]);

  const showToast = (message: string, icon = 'check_circle') => {
    setToast({ message, icon });
    setTimeout(() => {
      setToast((prev) => (prev?.message === message ? null : prev));
    }, 2400);
  };

  const handleNavigate = (next: ScreenId) => {
    setPreviousScreen(activeScreen);
    setActiveScreen(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleFavorite = (id: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setRecipes((prev) =>
      prev.map((r) => {
        if (r.id !== id) return r;
        const nextFav = !r.isFavorite;
        showToast(
          nextFav ? `"${r.title}" disimpan ke Favorit` : `"${r.title}" dihapus dari Favorit`,
          'favorite'
        );
        return { ...r, isFavorite: nextFav };
      })
    );
    setSelectedRecipe((curr) =>
      curr && curr.id === id ? { ...curr, isFavorite: !curr.isFavorite } : curr
    );
  };

  const handlePublishRecipe = (newRecipe: Recipe) => {
    setRecipes((prev) => [newRecipe, ...prev]);
    showToast(`Resep "${newRecipe.title}" berhasil diterbitkan!`, 'done_all');
    handleNavigate('beranda');
  };

  const handleDeleteRecipe = (id: string) => {
    const target = recipes.find((r) => r.id === id);
    setRecipes((prev) => prev.filter((r) => r.id !== id));
    if (target) {
      showToast(`Resep "${target.title}" telah dihapus`, 'delete');
    }
  };

  const isUserScreen = ['beranda', 'eksplor', 'unggah-resep', 'favorit', 'profil'].includes(
    activeScreen
  );
  const isAuthScreen = ['login', 'register'].includes(activeScreen);
  const isAdminScreen = ['admin-recipes', 'admin-users', 'admin-settings'].includes(activeScreen);

  const getHeaderTitle = () => {
    switch (activeScreen) {
      case 'beranda':
        return 'Beranda';
      case 'eksplor':
        return 'Eksplor';
      case 'unggah-resep':
        return 'Unggah Resep';
      case 'favorit':
        return 'Favorit';
      case 'profil':
        return 'Profil';
      case 'login':
        return 'Login';
      case 'register':
        return 'Register';
      case 'admin-recipes':
        return 'Kelola Resep';
      case 'admin-users':
        return 'Kelola Pengguna';
      case 'admin-settings':
        return 'Pengaturan Admin';
    }
  };

  return (
    <div className="min-h-screen bg-surface-container-low flex flex-col items-center justify-start">
      {/* Quick Screen Switcher Bar (Always accessible at the very top on desktop/mobile for inspecting all 10 screens) */}
      <div className="w-full max-w-[430px] bg-surface-container-high/90 backdrop-blur-md px-3 py-1.5 flex items-center gap-1.5 overflow-x-auto no-scrollbar border-b border-outline-variant/20 z-50">
        <span className="font-label-sm text-label-sm text-secondary uppercase tracking-wider shrink-0 mr-1">
          Layar:
        </span>
        {SCREEN_LABELS.map((item) => {
          const active = activeScreen === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => handleNavigate(item.id)}
              className={`px-2.5 py-1 rounded-full font-label-sm text-label-sm whitespace-nowrap transition-all shrink-0 cursor-pointer ${
                active
                  ? 'bg-primary text-on-primary font-bold shadow-xs'
                  : 'bg-surface-container-lowest text-on-surface-variant hover:text-on-surface'
              }`}
            >
              {item.label}
            </button>
          );
        })}
      </div>

      {/* Mobile App Viewport Shell */}
      <div className="w-full max-w-[430px] bg-surface text-on-surface min-h-screen flex flex-col relative shadow-2xl overflow-x-hidden">
        {/* TOP HEADER */}
        {isUserScreen && (
          <header className="sticky top-0 inset-x-0 z-40 bg-surface/90 backdrop-blur-xl pt-safe shadow-[0_1px_12px_rgba(0,0,0,0.03)]">
            <div className="flex items-center justify-between px-margin pt-space-xs text-on-surface-variant font-label-sm text-label-sm">
              <span className="font-label-md text-label-md text-on-surface font-semibold tabular-nums">
                12:34
              </span>
              <div className="flex items-center gap-space-xs">
                <span className="material-symbols-outlined text-[16px]">signal_cellular_alt</span>
                <span className="material-symbols-outlined text-[16px]">wifi</span>
                <span className="material-symbols-outlined text-[18px]">battery_full</span>
              </div>
            </div>
            <div className="h-14 px-margin flex items-center justify-between">
              <div className="flex items-center gap-space-sm">
                <h1 className="font-headline-md text-headline-md text-on-surface tracking-tight capitalize">
                  {getHeaderTitle()}
                </h1>
              </div>
              <div className="flex items-center gap-space-sm">
                <button
                  type="button"
                  onClick={() => setNotifModalOpen(true)}
                  aria-label="Notifications"
                  className="w-10 h-10 flex items-center justify-center rounded-full text-on-surface-variant hover:text-on-surface transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[24px]">notifications</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleNavigate('profil')}
                  aria-label="Profil"
                  className="w-8 h-8 rounded-full bg-primary flex items-center justify-center cursor-pointer active:scale-95 transition-transform"
                >
                  <span className="material-symbols-outlined text-on-primary text-[18px]">
                    person
                  </span>
                </button>
              </div>
            </div>
          </header>
        )}

        {isAuthScreen && (
          <header className="sticky top-0 inset-x-0 z-40 bg-surface/85 backdrop-blur-xl pt-safe shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
            <div className="h-16 px-margin flex items-center justify-between">
              <button
                type="button"
                onClick={() =>
                  handleNavigate(
                    previousScreen && !['login', 'register'].includes(previousScreen)
                      ? previousScreen
                      : 'beranda'
                  )
                }
                aria-label="Go back"
                className="w-11 h-11 -ml-2 rounded-full flex items-center justify-center text-on-surface hover:bg-surface-container active:scale-95 transition-all cursor-pointer"
              >
                <span className="material-symbols-outlined text-[24px]">arrow_back</span>
              </button>
              <span className="font-headline-sm text-headline-sm text-on-surface tracking-tight truncate max-w-[200px]">
                {getHeaderTitle()}
              </span>
              <button
                type="button"
                onClick={() => handleNavigate('profil')}
                aria-label="User Profile"
                className="w-9 h-9 rounded-full bg-primary flex items-center justify-center text-on-primary shadow-xs cursor-pointer"
              >
                <span className="material-symbols-outlined text-[18px]">person</span>
              </button>
            </div>
          </header>
        )}

        {isAdminScreen && (
          <header className="sticky top-0 inset-x-0 z-40 bg-surface/85 backdrop-blur-xl pt-safe shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
            <div className="h-16 px-margin flex items-center justify-between">
              <div className="flex flex-col justify-center gap-0.5">
                <div className="flex items-center gap-space-xs">
                  <span className="px-2 py-0.5 rounded-full bg-primary/10 text-primary font-label-sm text-label-sm uppercase tracking-wider font-bold">
                    ADMIN PANEL
                  </span>
                </div>
                <h1 className="font-headline-sm text-headline-sm text-on-surface font-bold tracking-tight">
                  {getHeaderTitle()}
                </h1>
              </div>
              <div className="flex items-center gap-space-sm">
                <button
                  type="button"
                  onClick={() => setNotifModalOpen(true)}
                  aria-label="Notifikasi"
                  className="relative w-11 h-11 rounded-full flex items-center justify-center text-on-surface-variant hover:text-on-surface active:scale-95 transition-transform cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[24px]">notifications</span>
                  <span className="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-primary ring-2 ring-surface"></span>
                </button>
                <button
                  type="button"
                  onClick={() => handleNavigate('beranda')}
                  title="Kembali ke Aplikasi Utama"
                  className="w-8 h-8 rounded-full bg-primary flex items-center justify-center shadow-sm cursor-pointer active:scale-95 transition-transform"
                >
                  <span className="material-symbols-outlined text-on-primary text-[18px]">
                    person
                  </span>
                </button>
              </div>
            </div>
          </header>
        )}

        {/* MAIN CONTENT AREA */}
        <main className="flex-1 flex flex-col relative w-full pb-24 bg-surface">
          {activeScreen === 'beranda' && (
            <BerandaScreen
              recipes={recipes}
              onToggleFavorite={handleToggleFavorite}
              onSelectRecipe={setSelectedRecipe}
              onNavigate={handleNavigate}
              showToast={showToast}
              onOpenAiModal={() => setAiModalOpen(true)}
              onOpenNotifications={() => setNotifModalOpen(true)}
            />
          )}

          {activeScreen === 'eksplor' && (
            <EksplorScreen
              recipes={recipes}
              onToggleFavorite={handleToggleFavorite}
              onSelectRecipe={setSelectedRecipe}
              onNavigate={handleNavigate}
              showToast={showToast}
            />
          )}

          {activeScreen === 'unggah-resep' && (
            <UnggahResepScreen onPublishRecipe={handlePublishRecipe} showToast={showToast} />
          )}

          {activeScreen === 'favorit' && (
            <FavoritScreen
              recipes={recipes}
              onToggleFavorite={handleToggleFavorite}
              onSelectRecipe={setSelectedRecipe}
              onNavigate={handleNavigate}
              showToast={showToast}
            />
          )}

          {activeScreen === 'profil' && (
            <ProfilScreen
              recipes={recipes}
              onToggleFavorite={handleToggleFavorite}
              onSelectRecipe={setSelectedRecipe}
              onNavigate={handleNavigate}
              onDeleteRecipe={handleDeleteRecipe}
              showToast={showToast}
              userProfile={userProfile}
              onUpdateProfile={setUserProfile}
            />
          )}

          {activeScreen === 'login' && (
            <LoginScreen onNavigate={handleNavigate} showToast={showToast} />
          )}

          {activeScreen === 'register' && (
            <RegisterScreen onNavigate={handleNavigate} showToast={showToast} />
          )}

          {activeScreen === 'admin-recipes' && (
            <AdminRecipesScreen
              recipes={recipes}
              onSelectRecipe={setSelectedRecipe}
              onNavigate={handleNavigate}
              showToast={showToast}
            />
          )}

          {activeScreen === 'admin-users' && <AdminUsersScreen showToast={showToast} />}

          {activeScreen === 'admin-settings' && (
            <AdminSettingsScreen
              darkMode={darkMode}
              onToggleDarkMode={() => {
                setDarkMode((d) => !d);
                showToast(
                  !darkMode ? 'Mode Gelap diaktifkan' : 'Mode Terang diaktifkan',
                  'dark_mode'
                );
              }}
              onNavigate={handleNavigate}
              showToast={showToast}
            />
          )}
        </main>

        {/* BOTTOM NAVIGATION BAR: USER MODE */}
        {isUserScreen && (
          <nav className="fixed bottom-0 w-full max-w-[430px] z-40 pb-safe bg-surface/95 backdrop-blur-xl shadow-[0_-6px_20px_rgba(0,0,0,0.05)]">
            <div className="flex items-center justify-between h-16 px-margin">
              <button
                type="button"
                onClick={() => handleNavigate('beranda')}
                className={`flex flex-col items-center justify-center w-14 h-12 transition-all duration-200 cursor-pointer ${
                  activeScreen === 'beranda'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-primary'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">home</span>
                <span className="font-label-sm text-label-sm mt-0.5">Beranda</span>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('eksplor')}
                className={`flex flex-col items-center justify-center w-14 h-12 transition-all duration-200 cursor-pointer ${
                  activeScreen === 'eksplor'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-primary'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">explore</span>
                <span className="font-label-sm text-label-sm mt-0.5">Eksplor</span>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('unggah-resep')}
                aria-label="Unggah Resep"
                className="flex flex-col items-center justify-center w-14 h-12 transition-all duration-200 cursor-pointer"
              >
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center transition-all shadow-[0_2px_8px_rgba(0,0,0,0.06)] ${
                    activeScreen === 'unggah-resep'
                      ? 'bg-primary text-on-primary'
                      : 'bg-surface-container-high text-on-surface hover:bg-primary hover:text-on-primary'
                  }`}
                >
                  <span className="material-symbols-outlined text-[22px]">add</span>
                </div>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('favorit')}
                className={`flex flex-col items-center justify-center w-14 h-12 transition-all duration-200 cursor-pointer ${
                  activeScreen === 'favorit'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-primary'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">favorite</span>
                <span className="font-label-sm text-label-sm mt-0.5">Favorit</span>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('profil')}
                className={`flex flex-col items-center justify-center w-14 h-12 transition-all duration-200 cursor-pointer ${
                  activeScreen === 'profil'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-primary'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">person</span>
                <span className="font-label-sm text-label-sm mt-0.5">Profil</span>
              </button>
            </div>
          </nav>
        )}

        {/* BOTTOM NAVIGATION BAR: ADMIN MODE */}
        {isAdminScreen && (
          <nav className="fixed bottom-0 w-full max-w-[430px] z-40 pb-safe bg-surface/95 backdrop-blur-xl shadow-[0_-4px_20px_rgba(0,0,0,0.04)]">
            <div className="flex justify-around items-center h-16 px-margin">
              <button
                type="button"
                onClick={() => handleNavigate('admin-users')}
                className={`flex flex-col items-center justify-center gap-1 min-w-[44px] min-h-[44px] px-space-sm transition-colors cursor-pointer ${
                  activeScreen === 'admin-users'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">group</span>
                <span className="font-label-md text-label-md">Users</span>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('admin-recipes')}
                className={`flex flex-col items-center justify-center gap-1 min-w-[44px] min-h-[44px] px-space-sm transition-colors cursor-pointer ${
                  activeScreen === 'admin-recipes'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">menu_book</span>
                <span className="font-label-md text-label-md">Recipes</span>
              </button>

              <button
                type="button"
                onClick={() => handleNavigate('admin-settings')}
                className={`flex flex-col items-center justify-center gap-1 min-w-[44px] min-h-[44px] px-space-sm transition-colors cursor-pointer ${
                  activeScreen === 'admin-settings'
                    ? 'text-primary font-bold'
                    : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <span className="material-symbols-outlined text-[24px]">tune</span>
                <span className="font-label-md text-label-md">Settings</span>
              </button>
            </div>
          </nav>
        )}

        {/* TOAST FEEDBACK PILL */}
        {toast && (
          <div className="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 bg-inverse-surface text-inverse-on-surface px-4 py-2.5 rounded-full shadow-xl flex items-center gap-2 transition-all duration-200">
            <span className="material-symbols-outlined text-[18px] text-primary-fixed-dim">
              {toast.icon}
            </span>
            <span className="font-label-md text-label-md whitespace-nowrap">{toast.message}</span>
          </div>
        )}
      </div>

      {/* MODALS */}
      <RecipeDetailModal
        recipe={selectedRecipe}
        onClose={() => setSelectedRecipe(null)}
        onToggleFavorite={handleToggleFavorite}
        showToast={showToast}
      />
      <AiFridgeModal
        isOpen={aiModalOpen}
        onClose={() => setAiModalOpen(false)}
        recipes={recipes}
        onSelectRecipe={setSelectedRecipe}
      />
      <NotificationsModal isOpen={notifModalOpen} onClose={() => setNotifModalOpen(false)} />
    </div>
  );
}
