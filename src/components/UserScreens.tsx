import React, { useState } from 'react';
import {
  CookingStep,
  IMAGES,
  Ingredient,
  Recipe,
  ScreenId,
} from '../data/mockData';

interface CommonScreenProps {
  recipes: Recipe[];
  onToggleFavorite: (id: string, e?: React.MouseEvent) => void;
  onSelectRecipe: (recipe: Recipe) => void;
  onNavigate: (screen: ScreenId) => void;
  showToast: (msg: string, icon?: string) => void;
}

// ============================================================================
// 1. BERANDA SCREEN (Image_3 / Image_4)
// ============================================================================
export const BerandaScreen: React.FC<
  CommonScreenProps & { onOpenAiModal: () => void; onOpenNotifications: () => void }
> = ({
  recipes,
  onToggleFavorite,
  onSelectRecipe,
  onNavigate,
  onOpenAiModal,
  onOpenNotifications,
}) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('Populer');

  const recommendedRecipes = recipes.slice(0, 3);
  const categories = ['Populer', 'Vegan', 'Pasta', 'Dessert', 'Seafood'];

  const showcaseRecipes = recipes.filter((r) => {
    if (selectedCategory === 'Populer') {
      return [
        'homemade-pepperoni-pizza',
        'dimsum-ayam-udang',
        'spaghetti-carbonara',
        'matcha-pancake',
      ].includes(r.id);
    }
    if (selectedCategory === 'Vegan') {
      return r.filterKey.includes('healthy') || r.category.toLowerCase().includes('asian');
    }
    if (selectedCategory === 'Pasta') {
      return r.filterKey.includes('pasta') || r.title.toLowerCase().includes('pasta') || r.title.toLowerCase().includes('spaghetti');
    }
    if (selectedCategory === 'Dessert') {
      return r.category.toLowerCase().includes('dessert') || r.id === 'matcha-pancake';
    }
    if (selectedCategory === 'Seafood') {
      return (
        r.title.toLowerCase().includes('salmon') ||
        r.title.toLowerCase().includes('udang') ||
        r.id === 'nasi-lemak'
      );
    }
    return true;
  });

  return (
    <div className="flex flex-col w-full px-margin pb-6 gap-space-lg">
      {/* Top Greeting & Search Header */}
      <div className="flex items-center justify-between pt-space-sm">
        <div className="flex flex-col">
          <span className="font-body-sm text-body-sm text-on-surface-variant">
            Halo &amp; Selamat Memasak!
          </span>
          <h2 className="font-headline-lg text-headline-lg text-on-surface tracking-tight">
            Welcome, Anna!
          </h2>
        </div>
        <div className="flex items-center gap-space-xs">
          <button
            type="button"
            onClick={() => onNavigate('eksplor')}
            aria-label="Search recipes"
            className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">search</span>
          </button>
          <button
            type="button"
            onClick={onOpenNotifications}
            aria-label="Notifications"
            className="relative w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface active:scale-95 transition-transform cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">notifications</span>
            <span className="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-primary ring-2 ring-surface"></span>
          </button>
        </div>
      </div>

      {/* Section 1: Recommended For You */}
      <div className="flex flex-col gap-space-md">
        <div className="flex items-baseline justify-between">
          <div className="flex items-center gap-space-xs">
            <h3 className="font-headline-md text-headline-md text-on-surface">
              Recommended for You
            </h3>
            <span className="w-1.5 h-1.5 rounded-full bg-primary-container"></span>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('eksplor')}
            className="font-label-md text-label-md text-primary font-bold hover:opacity-80 transition-opacity whitespace-nowrap cursor-pointer"
          >
            See All
          </button>
        </div>

        {/* Horizontal Carousel Container */}
        <div className="flex overflow-x-auto no-scrollbar gap-gutter -mx-margin px-margin pb-2 snap-x snap-mandatory">
          {recommendedRecipes.map((recipe) => (
            <div
              key={recipe.id}
              onClick={() => onSelectRecipe(recipe)}
              className="flex-none w-[220px] bg-inverse-surface rounded-[2rem] p-space-md text-on-tertiary flex flex-col justify-between relative shadow-xl snap-start cursor-pointer transition-transform active:scale-[0.98]"
            >
              {/* Card Floating Action Bar */}
              <div className="flex items-center justify-end w-full relative z-10">
                <button
                  type="button"
                  onClick={(e) => onToggleFavorite(recipe.id, e)}
                  aria-label="Simpan ke favorit"
                  className={`w-8 h-8 rounded-full bg-surface-container-highest/20 backdrop-blur-md flex items-center justify-center transition-colors active:scale-90 ${
                    recipe.isFavorite
                      ? 'text-primary-fixed-dim hover:text-primary'
                      : 'text-white/60 hover:text-primary'
                  }`}
                >
                  <span
                    className={`material-symbols-outlined text-[18px] ${
                      recipe.isFavorite ? 'material-symbols-filled text-[#ff4d6d]' : ''
                    }`}
                  >
                    favorite
                  </span>
                </button>
              </div>

              {/* Food Plate Isolation (Circular Frame) */}
              <div className="flex justify-center my-space-xs relative">
                <div className="w-36 h-36 rounded-full overflow-hidden shadow-2xl p-1 bg-gradient-to-b from-white/10 to-transparent">
                  <img
                    className="w-full h-full object-cover rounded-full"
                    alt={recipe.title}
                    src={recipe.image}
                    referrerPolicy="no-referrer"
                  />
                </div>
              </div>

              {/* Tags and Meta */}
              <div className="flex flex-col gap-space-xs mt-space-xs">
                <div className="flex items-center justify-between">
                  <span className="font-label-sm text-label-sm px-2.5 py-0.5 rounded-full bg-surface-container-highest/15 text-white/90 font-medium whitespace-nowrap">
                    {recipe.category}
                  </span>
                  <div className="flex items-center gap-0.5 text-primary-fixed-dim font-bold text-label-sm">
                    <span className="material-symbols-outlined material-symbols-filled text-[14px]">
                      thumb_up
                    </span>
                    <span>{recipe.likes}</span>
                  </div>
                </div>
                <div>
                  <h4 className="font-headline-sm text-headline-sm text-white leading-snug truncate">
                    {recipe.title}
                  </h4>
                  <p className="font-body-sm text-body-sm text-white/60 truncate">
                    {recipe.author}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Section 2: Categories Horizontal Filter */}
      <div className="flex flex-col gap-space-sm">
        <div className="flex items-baseline justify-between">
          <h3 className="font-headline-md text-headline-md text-on-surface">Categories</h3>
          <button
            type="button"
            onClick={() => onNavigate('eksplor')}
            className="font-label-md text-label-md text-primary font-bold hover:opacity-80 transition-opacity whitespace-nowrap cursor-pointer"
          >
            See All
          </button>
        </div>
        {/* Filter Pills List */}
        <div className="flex items-center gap-space-xs overflow-x-auto no-scrollbar -mx-margin px-margin py-1">
          {categories.map((cat) => {
            const isActive = selectedCategory === cat;
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(cat)}
                className={`flex-none px-5 py-2 rounded-full font-label-md text-label-md whitespace-nowrap transition-all active:scale-95 cursor-pointer ${
                  isActive
                    ? 'bg-inverse-surface text-on-tertiary shadow-md'
                    : 'bg-surface-container text-on-surface-variant hover:bg-surface-container-high'
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>
      </div>

      {/* Section 3: Popular Recipe Showcase (Tri-Card Row matching reference) */}
      <div className="flex overflow-x-auto no-scrollbar gap-space-sm -mx-margin px-margin pb-4 snap-x">
        {showcaseRecipes.map((item) => (
          <div
            key={item.id}
            onClick={() => onSelectRecipe(item)}
            className="flex-none w-[154px] bg-inverse-surface rounded-2xl p-3 text-on-tertiary flex flex-col justify-between shadow-lg snap-start cursor-pointer hover:shadow-xl transition-all active:scale-[0.98]"
          >
            <div className="flex items-center justify-between text-label-sm">
              <div className="flex items-center gap-0.5 text-primary-fixed-dim font-bold">
                <span className="material-symbols-outlined material-symbols-filled text-[12px]">
                  thumb_up
                </span>
                <span>{item.likes}</span>
              </div>
              <button
                type="button"
                onClick={(e) => onToggleFavorite(item.id, e)}
                aria-label="Favorit"
                className="w-6 h-6 rounded-full bg-surface-container-highest/20 flex items-center justify-center text-primary-fixed-dim active:scale-90"
              >
                <span
                  className={`material-symbols-outlined text-[14px] ${
                    item.isFavorite ? 'material-symbols-filled text-[#ff4d6d]' : 'text-white/60'
                  }`}
                >
                  favorite
                </span>
              </button>
            </div>
            <div className="flex justify-center my-2">
              <div className="w-24 h-24 rounded-full overflow-hidden shadow-md">
                <img
                  className="w-full h-full object-cover"
                  alt={item.title}
                  src={item.image}
                  referrerPolicy="no-referrer"
                />
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <span className="font-label-sm text-[9px] px-2 py-0.5 rounded-full bg-surface-container-highest/15 text-white/80 w-max whitespace-nowrap">
                {item.category}
              </span>
              <h5 className="font-headline-sm text-[13px] leading-tight text-white truncate">
                {item.title === 'Homemade Pepperoni Pizza'
                  ? 'Homemade Pizza'
                  : item.title === 'Dimsum Ayam Udang'
                  ? 'Dimsum'
                  : item.title}
              </h5>
              <p className="font-body-sm text-[11px] text-white/60 truncate">{item.author}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Interactive Quick Recipe Generator Pill / Prompt */}
      <div className="w-full rounded-2xl bg-surface-container-low p-space-md flex items-center justify-between gap-space-sm">
        <div className="flex items-center gap-space-sm">
          <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-on-primary shrink-0">
            <span className="material-symbols-outlined text-[20px]">auto_awesome</span>
          </div>
          <div className="flex flex-col">
            <span className="font-headline-sm text-headline-sm text-on-surface">
              Bingung mau masak apa?
            </span>
            <span className="font-body-sm text-body-sm text-on-surface-variant">
              Kocok bahan di kulkasmu sekarang!
            </span>
          </div>
        </div>
        <button
          type="button"
          onClick={onOpenAiModal}
          className="px-4 py-2 rounded-full bg-primary-container text-on-primary-container font-label-md text-label-md font-semibold shrink-0 whitespace-nowrap active:scale-95 transition-transform cursor-pointer"
        >
          Coba AI
        </button>
      </div>
    </div>
  );
};

// ============================================================================
// 2. EKSPLOR SCREEN (Image_5 / Image_6)
// ============================================================================
export const EksplorScreen: React.FC<CommonScreenProps> = ({
  recipes,
  onToggleFavorite,
  onSelectRecipe,
  showToast,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTrendTab, setActiveTrendTab] = useState<'populer' | 'terbaru' | 'recook'>('populer');
  const [selectedGridCategory, setSelectedGridCategory] = useState<string | null>(null);

  const trendingTags = ['#MentaiRice', '#PastaCarbonara', '#VeganDiet', '#DimsumRumahan'];

  const categoryGrid = [
    { name: 'Sarapan', count: '84 resep', icon: 'wb_twilight', color: 'text-primary', filter: 'Sarapan' },
    { name: 'Makan Siang', count: '152 resep', icon: 'sunny', color: 'text-primary', filter: 'Asian Food' },
    { name: 'Makan Malam', count: '110 resep', icon: 'dark_mode', color: 'text-primary', filter: 'Western' },
    { name: 'Minuman Segar', count: '67 resep', icon: 'local_bar', color: 'text-tertiary', filter: 'Minuman' },
    { name: 'Kue & Dessert', count: '95 resep', icon: 'cake', color: 'text-primary', filter: 'Dessert' },
    { name: 'Diet Sehat', count: '73 resep', icon: 'eco', color: 'text-secondary', filter: 'Japanese' },
  ];

  const baseExploreRecipes = recipes.filter((r) => {
    const matchesQuery =
      !searchQuery.trim() ||
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.author.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.ingredients.some((i) => i.name.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesCategory =
      !selectedGridCategory ||
      r.category.toLowerCase().includes(selectedGridCategory.toLowerCase()) ||
      r.title.toLowerCase().includes(selectedGridCategory.toLowerCase());

    return matchesQuery && matchesCategory;
  });

  const sortedExploreRecipes = [...baseExploreRecipes].sort((a, b) => {
    if (activeTrendTab === 'populer') return b.likesCount - a.likesCount;
    if (activeTrendTab === 'recook') return (b.recooks || '').localeCompare(a.recooks || '');
    return a.publishedAgo.localeCompare(b.publishedAgo);
  });

  // Prioritize the 3 featured explore cards when no filter is active
  const defaultThreeIds = ['japanese-beef-curry', 'creamy-truffle-pasta', 'ayam-bakar-madu-pedas'];
  const displayedRecipes =
    !searchQuery && !selectedGridCategory && activeTrendTab === 'populer'
      ? [
          ...recipes.filter((r) => defaultThreeIds.includes(r.id)),
          ...recipes.filter((r) => !defaultThreeIds.includes(r.id)),
        ]
      : sortedExploreRecipes;

  return (
    <div className="flex flex-col w-full">
      {/* Search & Filter Section */}
      <section className="px-margin pt-space-xs pb-space-sm flex flex-col gap-space-sm">
        <div className="flex items-center gap-space-sm w-full">
          <div className="flex-1 flex items-center gap-space-sm bg-surface-container-high rounded-full px-space-md py-2.5 text-on-surface-variant focus-within:bg-surface-container-highest transition-colors">
            <span className="material-symbols-outlined text-[20px] text-secondary">search</span>
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent border-none outline-none w-full font-body-md text-body-md text-on-surface placeholder:text-secondary focus:ring-0 p-0"
              placeholder="Cari resep, bahan, atau koki..."
              type="text"
            />
            {searchQuery ? (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                aria-label="Clear search"
                className="w-6 h-6 flex items-center justify-center text-secondary hover:text-on-surface"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={() => showToast('Pencarian suara siap mendengarkan...', 'mic')}
                aria-label="Voice search"
                className="w-6 h-6 flex items-center justify-center text-secondary hover:text-on-surface"
              >
                <span className="material-symbols-outlined text-[18px]">mic</span>
              </button>
            )}
          </div>
          <button
            type="button"
            onClick={() => {
              setSelectedGridCategory(null);
              setSearchQuery('');
              showToast('Filter eksplorasi direset', 'tune');
            }}
            aria-label="Filter Resep"
            className="w-11 h-11 flex-shrink-0 flex items-center justify-center rounded-full bg-inverse-surface text-surface-bright active:scale-95 transition-transform shadow-sm cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">tune</span>
          </button>
        </div>

        {/* Trending Tags */}
        <div className="flex items-center gap-space-xs overflow-x-auto no-scrollbar py-0.5">
          <div className="flex items-center gap-1 text-primary mr-1 flex-shrink-0 font-label-sm text-label-sm">
            <span className="material-symbols-outlined material-symbols-filled text-[15px]">
              trending_up
            </span>
            <span className="font-bold uppercase tracking-wider">Tren:</span>
          </div>
          {trendingTags.map((tag) => {
            const cleanKeyword = tag.replace('#', '').replace(/([A-Z])/g, ' $1').trim();
            return (
              <button
                key={tag}
                type="button"
                onClick={() =>
                  setSearchQuery((prev) =>
                    prev === cleanKeyword.split(' ')[0] ? '' : cleanKeyword.split(' ')[0]
                  )
                }
                className="px-3 py-1 rounded-full bg-surface-container text-on-surface-variant font-label-sm text-label-sm flex-shrink-0 whitespace-nowrap hover:bg-primary-fixed hover:text-on-primary-fixed active:bg-primary-fixed active:text-on-primary-fixed transition-colors cursor-pointer"
              >
                {tag}
              </button>
            );
          })}
        </div>
      </section>

      {/* Featured Collections Banner Slider */}
      <section className="mt-space-sm mb-space-md">
        <div className="px-margin flex items-center justify-between mb-space-xs">
          <span className="font-headline-sm text-headline-sm text-on-surface">Koleksi Spesial</span>
          <button
            type="button"
            onClick={() => {
              setSelectedGridCategory(null);
              setSearchQuery('');
            }}
            className="font-label-lg text-label-lg text-primary hover:text-primary-container font-semibold transition-colors cursor-pointer"
          >
            Lihat Semua
          </button>
        </div>
        <div className="flex gap-space-md overflow-x-auto px-margin py-space-xs no-scrollbar snap-x snap-mandatory">
          {/* Collection Banner 1 */}
          <div className="snap-start flex-shrink-0 w-[84vw] max-w-[340px] bg-inverse-surface rounded-[2rem] p-space-md relative overflow-hidden flex items-center justify-between shadow-[0_10px_24px_rgba(30,30,36,0.18)]">
            <div className="relative z-10 flex flex-col justify-between h-full max-w-[62%]">
              <span className="inline-flex items-center gap-1 w-fit bg-primary-container/90 text-on-primary-container px-2.5 py-0.5 rounded-full font-label-sm text-label-sm mb-2 whitespace-nowrap">
                <span className="material-symbols-outlined material-symbols-filled text-[13px]">
                  local_fire_department
                </span>
                Populer Minggu Ini
              </span>
              <h3 className="font-headline-sm text-headline-sm text-surface-bright leading-tight mb-2">
                Kreasi Western Food Otentik
              </h3>
              <p className="font-body-sm text-body-sm text-surface-variant/80 mb-3 line-clamp-1">
                18 menu gourmet resto bintang 5
              </p>
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('Western');
                  showToast('Menampilkan koleksi Western Food', 'restaurant');
                }}
                className="inline-flex items-center gap-1 font-label-md text-label-md bg-surface-container-lowest text-inverse-surface px-3 py-1.5 rounded-full w-fit active:scale-95 transition-transform font-bold whitespace-nowrap cursor-pointer"
              >
                Eksplor Koleksi
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </button>
            </div>
            <div className="relative w-28 h-28 flex-shrink-0 -mr-2">
              <div className="absolute inset-0 rounded-full bg-primary/20 blur-md"></div>
              <img
                className="w-full h-full object-cover rounded-full shadow-lg"
                alt="Kreasi Western Food Otentik"
                src={IMAGES.westernBanner}
                referrerPolicy="no-referrer"
              />
            </div>
          </div>

          {/* Collection Banner 2 */}
          <div className="snap-start flex-shrink-0 w-[84vw] max-w-[340px] bg-inverse-surface rounded-[2rem] p-space-md relative overflow-hidden flex items-center justify-between shadow-[0_10px_24px_rgba(30,30,36,0.18)]">
            <div className="relative z-10 flex flex-col justify-between h-full max-w-[62%]">
              <span className="inline-flex items-center gap-1 w-fit bg-tertiary-container text-on-tertiary-container px-2.5 py-0.5 rounded-full font-label-sm text-label-sm mb-2 whitespace-nowrap">
                <span className="material-symbols-outlined material-symbols-filled text-[13px]">
                  flare
                </span>
                Inspirasi Weekend
              </span>
              <h3 className="font-headline-sm text-headline-sm text-surface-bright leading-tight mb-2">
                Sajian Hangat Meja Keluarga
              </h3>
              <p className="font-body-sm text-body-sm text-surface-variant/80 mb-3 line-clamp-1">
                24 olahan hidangan nusantara
              </p>
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('Asian');
                  showToast('Menampilkan koleksi Hidangan Keluarga', 'soup_kitchen');
                }}
                className="inline-flex items-center gap-1 font-label-md text-label-md bg-surface-container-lowest text-inverse-surface px-3 py-1.5 rounded-full w-fit active:scale-95 transition-transform font-bold whitespace-nowrap cursor-pointer"
              >
                Eksplor Koleksi
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </button>
            </div>
            <div className="relative w-28 h-28 flex-shrink-0 -mr-2">
              <div className="absolute inset-0 rounded-full bg-tertiary-fixed/20 blur-md"></div>
              <img
                className="w-full h-full object-cover rounded-full shadow-lg"
                alt="Sajian Hangat Meja Keluarga"
                src={IMAGES.nusantaraBanner}
                referrerPolicy="no-referrer"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Category Filter Grid */}
      <section className="px-margin mb-space-lg">
        <div className="flex items-center justify-between mb-space-sm">
          <span className="font-headline-sm text-headline-sm text-on-surface">Kategori Resep</span>
          <span className="font-label-sm text-label-sm text-secondary">6 Kategori</span>
        </div>
        <div className="grid grid-cols-3 gap-space-sm">
          {categoryGrid.map((cat) => {
            const isSelected = selectedGridCategory === cat.filter;
            return (
              <button
                key={cat.name}
                type="button"
                onClick={() =>
                  setSelectedGridCategory((prev) => (prev === cat.filter ? null : cat.filter))
                }
                className={`flex flex-col items-center p-space-sm rounded-2xl active:scale-95 transition-all text-center group cursor-pointer ${
                  isSelected
                    ? 'bg-primary-fixed/50 ring-2 ring-primary'
                    : 'bg-surface-container-low hover:bg-surface-container'
                }`}
              >
                <div className="w-12 h-12 rounded-full bg-surface-container-highest flex items-center justify-center text-primary group-hover:bg-primary-fixed transition-colors mb-1.5">
                  <span className={`material-symbols-outlined text-[24px] ${cat.color}`}>
                    {cat.icon}
                  </span>
                </div>
                <span className="font-label-md text-label-md text-on-surface text-center leading-tight">
                  {cat.name}
                </span>
                <span className="font-body-sm text-body-sm text-secondary text-[11px] mt-0.5">
                  {cat.count}
                </span>
              </button>
            );
          })}
        </div>
      </section>

      {/* Trending Recipes List Section */}
      <section className="flex flex-col w-full mb-space-lg">
        <div className="px-margin flex items-center justify-between mb-space-sm">
          <div>
            <h2 className="font-headline-sm text-headline-sm text-on-surface tracking-tight">
              Katalog Resep Tren
            </h2>
            <p className="font-body-sm text-body-sm text-secondary">
              Dipilih khusus oleh komunitas koki rumahan
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setSelectedGridCategory(null);
            }}
            className="font-label-lg text-label-lg text-primary hover:text-primary-container font-semibold transition-colors cursor-pointer"
          >
            Semua
          </button>
        </div>

        {/* Filter Pills Tabs */}
        <div className="px-margin flex items-center gap-space-xs overflow-x-auto no-scrollbar mb-space-md">
          {[
            { id: 'populer', label: 'Terpopuler' },
            { id: 'terbaru', label: 'Terbaru' },
            { id: 'recook', label: 'Paling Banyak Di-recook' },
          ].map((tab) => {
            const isActive = activeTrendTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTrendTab(tab.id as 'populer' | 'terbaru' | 'recook')}
                className={`px-4 py-1.5 rounded-full font-label-md text-label-md whitespace-nowrap transition-all cursor-pointer ${
                  isActive
                    ? 'bg-inverse-surface text-surface-bright shadow-sm'
                    : 'bg-surface-container-high text-on-surface-variant hover:bg-surface-container-highest'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Recipe Dark Slate Cards Stack */}
        <div className="px-margin flex flex-col gap-space-md">
          {displayedRecipes.map((recipe) => (
            <article
              key={recipe.id}
              onClick={() => onSelectRecipe(recipe)}
              className="w-full bg-inverse-surface rounded-[2rem] p-space-md text-surface-bright relative overflow-hidden shadow-[0_12px_28px_rgba(30,30,36,0.16)] flex flex-col gap-space-sm transition-transform active:scale-[0.99] cursor-pointer"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-space-xs">
                  <span className="px-2.5 py-0.5 rounded-full bg-surface-variant/20 text-surface-bright font-label-sm text-label-sm whitespace-nowrap">
                    {recipe.category}
                  </span>
                  <span className="inline-flex items-center gap-1 text-primary-container font-label-md text-label-md">
                    <span className="material-symbols-outlined material-symbols-filled text-[14px]">
                      thumb_up
                    </span>
                    {recipe.likes}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={(e) => onToggleFavorite(recipe.id, e)}
                  aria-label="Simpan ke favorit"
                  className="w-9 h-9 rounded-full bg-surface-variant/20 backdrop-blur-md flex items-center justify-center text-primary-fixed-dim hover:text-primary active:scale-90 transition-all"
                >
                  <span
                    className={`material-symbols-outlined text-[19px] ${
                      recipe.isFavorite ? 'material-symbols-filled text-[#ff4d6d]' : ''
                    }`}
                  >
                    favorite
                  </span>
                </button>
              </div>

              <div className="flex items-center gap-space-md my-1">
                {/* Circular Framed Plate Photography */}
                <div className="relative w-28 h-28 flex-shrink-0">
                  <div className="w-full h-full rounded-full overflow-hidden p-1 bg-surface-container-highest/10 shadow-inner">
                    <img
                      className="w-full h-full object-cover rounded-full"
                      alt={recipe.title}
                      src={recipe.image}
                      referrerPolicy="no-referrer"
                    />
                  </div>
                </div>
                {/* Recipe Details & Metadata */}
                <div className="flex-1 flex flex-col justify-center min-w-0">
                  <h3 className="font-headline-sm text-headline-sm text-surface-bright font-bold leading-snug truncate">
                    {recipe.title}
                  </h3>
                  <div className="flex items-center gap-2 mt-1 mb-2">
                    <div className="w-5 h-5 rounded-full overflow-hidden bg-surface-variant/30 flex-shrink-0">
                      <img
                        className="w-full h-full object-cover"
                        alt={recipe.author}
                        src={recipe.authorAvatar || IMAGES.chefKenjiAvatar}
                        referrerPolicy="no-referrer"
                      />
                    </div>
                    <span className="font-body-sm text-body-sm text-surface-variant/80 truncate">
                      {recipe.author}
                    </span>
                  </div>
                  {/* Stats Chips */}
                  <div className="flex items-center gap-space-sm text-surface-variant/70 font-label-sm text-label-sm flex-wrap">
                    <span className="inline-flex items-center gap-1 whitespace-nowrap">
                      <span className="material-symbols-outlined text-[14px]">schedule</span>
                      {recipe.time}
                    </span>
                    <span className="inline-flex items-center gap-1 text-primary-fixed whitespace-nowrap">
                      <span className="material-symbols-outlined text-[14px]">repeat</span>
                      {recipe.recooks || '640 recook'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Recipe Micro Action Bar */}
              <div className="pt-2 border-none flex items-center justify-between text-surface-variant/70">
                <span className="font-label-sm text-label-sm">
                  Tingkat: <strong className="text-surface-bright">{recipe.difficulty}</strong>
                </span>
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    onSelectRecipe(recipe);
                  }}
                  className="inline-flex items-center gap-1 text-primary-fixed-dim hover:text-surface-bright font-label-md text-label-md whitespace-nowrap"
                >
                  Lihat Resep
                  <span className="material-symbols-outlined text-[16px]">chevron_right</span>
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
};

// ============================================================================
// 3. UNGGAH RESEP SCREEN (Image_1 / Image_2)
// ============================================================================
export const UnggahResepScreen: React.FC<{
  onPublishRecipe: (newRecipe: Recipe) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ onPublishRecipe, showToast }) => {
  const [title, setTitle] = useState('Salmon Mentai Rice Bowl Spesial');
  const [description, setDescription] = useState(
    'Perpaduan salmon panggang juicy dengan saus mentai gurih-creamy yang ditorch hingga wangi smoky menggugah selera.'
  );
  const [selectedCategory, setSelectedCategory] = useState('Asian Food');
  const [cookTime, setCookTime] = useState('30 Menit');
  const [servings, setServings] = useState('2-3 Porsi');
  const [difficulty, setDifficulty] = useState('Sedang');
  const [heroPhoto, setHeroPhoto] = useState(IMAGES.salmonMentaiHero);
  const [subPhotos, setSubPhotos] = useState<string[]>([
    IMAGES.salmonMentaiSub1,
    IMAGES.salmonMentaiSub2,
  ]);
  const [ingredients, setIngredients] = useState<Ingredient[]>([
    { id: '1', name: 'Beras Jepang / Japonica Rice', amount: '300 gram' },
    { id: '2', name: 'Fillet Ikan Salmon Segar', amount: '200 gram (potong dadu)' },
    { id: '3', name: 'Mayones Jepang (Kewpie) & Tobiko', amount: '4 sdm mayo + 2 sdm tobiko' },
  ]);
  const [newIngName, setNewIngName] = useState('');
  const [newIngAmount, setNewIngAmount] = useState('');
  const [showAddIngForm, setShowAddIngForm] = useState(false);

  const [steps, setSteps] = useState<CookingStep[]>([
    {
      id: '1',
      title: 'Menyiapkan Nasi & Racikan Salmon',
      description:
        'Masak nasi Jepang hingga pulen hangat, campurkan dengan taburan furikake dan minyak wijen. Marinasi potongan salmon dengan kecap asin Jepang & saus tiram selama 10 menit.',
    },
    {
      id: '2',
      title: 'Perakitan & Blow Torch Mentai',
      description:
        'Tata nasi dalam mangkuk tahan panas, susun salmon di atasnya, lapisi dengan saus mentai tebal. Gunakan kitchen blow torch hingga permukaan saus berkaramel kecokelatan dan wangi smoky.',
    },
  ]);
  const [newStepTitle, setNewStepTitle] = useState('');
  const [newStepDesc, setNewStepDesc] = useState('');
  const [showAddStepForm, setShowAddStepForm] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [publishedSuccess, setPublishedSuccess] = useState(false);

  const categories = ['Asian Food', 'Western', 'Healthy Diet', 'Dessert', 'Nusantara'];

  const cycleSamplePhoto = () => {
    const pool = [
      IMAGES.salmonMentaiHero,
      IMAGES.nasiLemakHome,
      IMAGES.trufflePastaExplore,
      IMAGES.ayamBakarExplore,
      IMAGES.matchaPancakeHome,
    ];
    const nextIdx = (pool.indexOf(heroPhoto) + 1) % pool.length;
    setHeroPhoto(pool[nextIdx]);
    showToast('Foto utama resep berhasil diganti', 'photo_camera');
  };

  const handleAddIngredient = () => {
    if (!newIngName.trim()) return;
    setIngredients((prev) => [
      ...prev,
      {
        id: String(Date.now()),
        name: newIngName.trim(),
        amount: newIngAmount.trim() || 'Secukupnya',
      },
    ]);
    setNewIngName('');
    setNewIngAmount('');
    setShowAddIngForm(false);
    showToast('Bahan masakan ditambahkan', 'kitchen');
  };

  const handleAddStep = () => {
    if (!newStepTitle.trim() && !newStepDesc.trim()) return;
    setSteps((prev) => [
      ...prev,
      {
        id: String(Date.now()),
        title: newStepTitle.trim() || `Tahap Memasak ${prev.length + 1}`,
        description: newStepDesc.trim() || 'Lanjutkan proses memasak sesuai takaran bumbu.',
      },
    ]);
    setNewStepTitle('');
    setNewStepDesc('');
    setShowAddStepForm(false);
    showToast('Langkah memasak baru ditambahkan', 'format_list_numbered');
  };

  const handlePublish = () => {
    if (!title.trim()) {
      showToast('Mohon isi Nama Resep terlebih dahulu', 'error');
      return;
    }
    setIsPublishing(true);
    setTimeout(() => {
      setIsPublishing(false);
      setPublishedSuccess(true);
      const created: Recipe = {
        id: `custom-${Date.now()}`,
        code: `#RSP-${Math.floor(3052 + Math.random() * 900)}`,
        title: title.trim(),
        description: description.trim(),
        category: selectedCategory,
        filterKey: selectedCategory.toLowerCase().includes('western')
          ? 'western'
          : selectedCategory.toLowerCase().includes('healthy')
          ? 'healthy'
          : selectedCategory.toLowerCase().includes('dessert')
          ? 'dessert'
          : 'asian',
        author: 'Anna Roberts',
        authorAvatar: IMAGES.annaRobertsAvatar,
        verified: true,
        likes: '128',
        likesCount: 128,
        recooks: '14 recook',
        time: cookTime,
        servings,
        difficulty,
        image: heroPhoto,
        secondaryImages: subPhotos,
        isFavorite: true,
        isMyRecipe: true,
        publishedAgo: 'Baru saja',
        ingredients,
        steps,
      };
      setTimeout(() => {
        setPublishedSuccess(false);
        onPublishRecipe(created);
      }, 1100);
    }, 900);
  };

  return (
    <div className="flex flex-col w-full pb-10">
      {/* Top Intro Section */}
      <section className="px-margin pt-space-md pb-space-sm">
        <div className="flex items-center justify-between">
          <div>
            <span className="inline-flex items-center gap-space-xs px-space-sm py-0.5 rounded-full bg-primary-fixed text-primary font-label-sm text-label-sm uppercase tracking-wider">
              <span className="material-symbols-outlined text-[14px]">local_fire_department</span>
              Kreasi Dapur
            </span>
            <h2 className="font-headline-lg text-headline-lg text-on-surface mt-1">Upload Resep</h2>
          </div>
          <div className="w-10 h-10 rounded-full bg-surface-container-high flex items-center justify-center text-on-surface-variant">
            <span className="material-symbols-outlined text-[22px]">restaurant</span>
          </div>
        </div>
        <p className="font-body-md text-body-md text-on-surface-variant mt-1">
          Bagikan kelezatan dan rahasia racikan bumbu spesialmu ke komunitas kuliner.
        </p>
      </section>

      {/* Photo Upload Stage / Gallery-Grade Card Preview */}
      <section className="px-margin mt-space-md">
        <div className="relative bg-inverse-surface text-surface-container-lowest rounded-[2rem] p-space-md shadow-xl overflow-hidden">
          <div className="absolute -right-10 -bottom-10 w-44 h-44 rounded-full bg-primary/20 blur-2xl pointer-events-none"></div>
          <div className="flex items-center justify-between mb-space-sm relative z-10">
            <span className="inline-flex items-center gap-space-xs font-label-sm text-label-sm uppercase tracking-wider text-primary-fixed-dim">
              <span className="material-symbols-outlined text-[16px] text-primary">add_a_photo</span>
              Foto Utama Resep
            </span>
            <span className="font-label-sm text-label-sm text-surface-dim bg-surface-container-highest/20 px-2 py-0.5 rounded-full">
              Maks. 3 Foto
            </span>
          </div>

          {/* Platter Photography Showcase & Drag-drop Slot */}
          <div className="relative flex flex-col items-center justify-center py-4 px-2">
            <div
              onClick={cycleSamplePhoto}
              className="relative w-40 h-40 sm:w-44 sm:h-44 rounded-full p-1 bg-gradient-to-tr from-primary to-surface-variant/20 shadow-2xl flex items-center justify-center group cursor-pointer"
            >
              <div className="w-full h-full rounded-full overflow-hidden bg-surface-container-highest/10 relative">
                <img
                  className="w-full h-full object-cover rounded-full"
                  alt="Foto Utama Resep"
                  src={heroPhoto}
                  referrerPolicy="no-referrer"
                />
                <div className="absolute inset-0 bg-inverse-surface/50 flex flex-col items-center justify-center backdrop-blur-xs opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                  <span className="material-symbols-outlined text-surface text-[28px]">
                    photo_camera
                  </span>
                  <span className="font-label-sm text-label-sm text-surface mt-1">Ganti Foto</span>
                </div>
              </div>
              <div className="absolute top-1 right-1 w-9 h-9 rounded-full bg-inverse-surface/85 backdrop-blur-md flex items-center justify-center text-primary shadow-lg border border-white/10">
                <span className="material-symbols-outlined material-symbols-filled text-[18px]">
                  favorite
                </span>
              </div>
              <div className="absolute -bottom-2 bg-primary text-on-primary font-label-sm text-label-sm px-2.5 py-1 rounded-full shadow-md flex items-center gap-1 whitespace-nowrap">
                <span className="material-symbols-outlined text-[13px]">verified</span>
                Resolusi Tinggi
              </div>
            </div>

            {/* Secondary upload preview pills */}
            <div className="flex items-center gap-space-sm mt-5">
              {subPhotos.map((photo, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => {
                    const prevHero = heroPhoto;
                    setHeroPhoto(photo);
                    setSubPhotos((curr) => curr.map((p, i) => (i === idx ? prevHero : p)));
                  }}
                  title="Jadikan foto utama"
                  className="w-12 h-12 rounded-full overflow-hidden shadow-sm bg-surface-container-high relative cursor-pointer ring-2 ring-transparent hover:ring-primary transition-all"
                >
                  <img
                    className="w-full h-full object-cover rounded-full"
                    alt={`Sub foto ${idx + 1}`}
                    src={photo}
                    referrerPolicy="no-referrer"
                  />
                  <div className="absolute inset-0 bg-on-surface/15"></div>
                </button>
              ))}
              <button
                type="button"
                onClick={cycleSamplePhoto}
                aria-label="Tambah Foto Tambahan"
                className="w-12 h-12 rounded-full bg-surface-container-highest/20 hover:bg-surface-container-highest/40 flex items-center justify-center text-surface transition-all active:scale-95 cursor-pointer"
              >
                <span className="material-symbols-outlined text-[20px]">add</span>
              </button>
            </div>

            <p className="font-body-sm text-body-sm text-surface-dim mt-3 text-center">
              Format JPG, PNG atau WebP (Disarankan rasio 1:1, maks. 5MB per foto)
            </p>
          </div>
        </div>
      </section>

      {/* Section 1: Basic Information */}
      <section className="px-margin mt-space-lg">
        <div className="bg-surface-container-lowest rounded-[2rem] p-space-md shadow-sm">
          <div className="flex items-center gap-space-xs mb-space-sm">
            <span className="material-symbols-outlined text-primary text-[20px]">edit_note</span>
            <h3 className="font-headline-sm text-headline-sm text-on-surface">Detail Resep</h3>
          </div>

          {/* Recipe Title */}
          <div className="space-y-1 mb-space-md">
            <label
              className="font-label-md text-label-md text-on-surface-variant flex items-center justify-between"
              htmlFor="recipe-title"
            >
              <span>
                Nama Resep <span className="text-primary">*</span>
              </span>
              <span className="font-body-sm text-body-sm text-outline tabular-nums">
                {title.length}/60
              </span>
            </label>
            <div className="bg-surface-container-low rounded-DEFAULT px-space-md py-space-sm flex items-center focus-within:bg-surface-container-lowest focus-within:shadow-md transition-all">
              <input
                id="recipe-title"
                maxLength={60}
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Misal: Nasi Lemak Sambal Sotong"
                type="text"
                className="w-full bg-transparent border-0 outline-none font-body-lg text-body-lg text-on-surface placeholder:text-outline/60"
              />
            </div>
          </div>

          {/* Recipe Description */}
          <div className="space-y-1 mb-space-md">
            <label
              className="font-label-md text-label-md text-on-surface-variant"
              htmlFor="recipe-desc"
            >
              Deskripsi Singkat
            </label>
            <div className="bg-surface-container-low rounded-DEFAULT p-space-md focus-within:bg-surface-container-lowest focus-within:shadow-md transition-all">
              <textarea
                id="recipe-desc"
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Ceritakan keistimewaan rasa, aroma, atau momen yang cocok untuk memasak hidangan ini..."
                className="w-full bg-transparent border-0 outline-none font-body-md text-body-md text-on-surface placeholder:text-outline/60 resize-none"
              />
            </div>
          </div>

          {/* Category Filter Pills */}
          <div className="space-y-2 mb-space-md">
            <span className="font-label-md text-label-md text-on-surface-variant">
              Kategori Masakan
            </span>
            <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
              {categories.map((cat) => {
                const isActive = selectedCategory === cat;
                return (
                  <button
                    key={cat}
                    type="button"
                    onClick={() => setSelectedCategory(cat)}
                    className={`whitespace-nowrap px-space-md py-2 rounded-full font-label-md text-label-md transition-all cursor-pointer ${
                      isActive
                        ? 'bg-inverse-surface text-surface-container-lowest shadow-sm'
                        : 'bg-surface-container-high text-on-surface-variant hover:bg-surface-variant'
                    }`}
                  >
                    {cat}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Quick Triple Metrics */}
          <div className="grid grid-cols-3 gap-space-xs">
            <div className="bg-surface-container-low rounded-DEFAULT p-space-sm flex flex-col items-center text-center">
              <span className="material-symbols-outlined text-primary text-[20px]">timer</span>
              <span className="font-label-sm text-label-sm text-on-surface-variant mt-0.5">
                Waktu
              </span>
              <input
                type="text"
                value={cookTime}
                onChange={(e) => setCookTime(e.target.value)}
                className="w-full text-center bg-transparent border-0 outline-none font-headline-sm text-headline-sm text-on-surface mt-0.5"
              />
            </div>
            <div className="bg-surface-container-low rounded-DEFAULT p-space-sm flex flex-col items-center text-center">
              <span className="material-symbols-outlined text-tertiary text-[20px]">group</span>
              <span className="font-label-sm text-label-sm text-on-surface-variant mt-0.5">
                Porsi
              </span>
              <input
                type="text"
                value={servings}
                onChange={(e) => setServings(e.target.value)}
                className="w-full text-center bg-transparent border-0 outline-none font-headline-sm text-headline-sm text-on-surface mt-0.5"
              />
            </div>
            <div className="bg-surface-container-low rounded-DEFAULT p-space-sm flex flex-col items-center text-center">
              <span className="material-symbols-outlined text-primary-container text-[20px]">
                equalizer
              </span>
              <span className="font-label-sm text-label-sm text-on-surface-variant mt-0.5">
                Tingkat
              </span>
              <input
                type="text"
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value)}
                className="w-full text-center bg-transparent border-0 outline-none font-headline-sm text-headline-sm text-on-surface mt-0.5"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Section 2: Interactive Ingredients Builder */}
      <section className="px-margin mt-space-lg">
        <div className="bg-surface-container-lowest rounded-[2rem] p-space-md shadow-sm">
          <div className="flex items-center justify-between mb-space-sm">
            <div className="flex items-center gap-space-xs">
              <span className="material-symbols-outlined text-primary text-[20px]">kitchen</span>
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Bahan-Bahan</h3>
            </div>
            <span className="font-label-sm text-label-sm text-primary font-bold bg-primary-fixed px-2.5 py-0.5 rounded-full whitespace-nowrap">
              {ingredients.length} Bahan
            </span>
          </div>

          <div className="space-y-space-xs">
            {ingredients.map((ing) => (
              <div
                key={ing.id}
                className="flex items-center justify-between bg-surface-container-low px-space-md py-space-sm rounded-DEFAULT group"
              >
                <div className="flex items-center gap-space-sm min-w-0">
                  <span className="material-symbols-outlined text-outline text-[18px]">
                    drag_indicator
                  </span>
                  <div className="min-w-0">
                    <p className="font-body-md text-body-md text-on-surface truncate">{ing.name}</p>
                    <span className="font-label-sm text-label-sm text-primary font-semibold">
                      {ing.amount}
                    </span>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    setIngredients((prev) => prev.filter((item) => item.id !== ing.id))
                  }
                  aria-label="Hapus bahan"
                  className="w-8 h-8 rounded-full flex items-center justify-center text-outline hover:text-error transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[18px]">close</span>
                </button>
              </div>
            ))}
          </div>

          {showAddIngForm ? (
            <div className="mt-space-sm p-3 rounded-DEFAULT bg-surface-container-low space-y-2">
              <input
                type="text"
                value={newIngName}
                onChange={(e) => setNewIngName(e.target.value)}
                placeholder="Nama bahan (mis. Nori Rumput Laut)"
                className="w-full px-3 py-2 rounded-xl bg-surface-container-lowest text-on-surface font-body-sm text-body-sm outline-none"
              />
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newIngAmount}
                  onChange={(e) => setNewIngAmount(e.target.value)}
                  placeholder="Takaran (mis. 2 lembar)"
                  className="flex-1 px-3 py-2 rounded-xl bg-surface-container-lowest text-on-surface font-body-sm text-body-sm outline-none"
                />
                <button
                  type="button"
                  onClick={handleAddIngredient}
                  className="px-4 py-2 rounded-xl bg-primary text-on-primary font-label-md text-label-md"
                >
                  Simpan
                </button>
                <button
                  type="button"
                  onClick={() => setShowAddIngForm(false)}
                  className="px-3 py-2 rounded-xl bg-surface-container-high text-on-surface-variant font-label-md text-label-md"
                >
                  Batal
                </button>
              </div>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setShowAddIngForm(true)}
              className="w-full mt-space-sm py-3 rounded-DEFAULT bg-primary-fixed/40 text-primary hover:bg-primary-fixed font-label-md text-label-md flex items-center justify-center gap-space-xs transition-all active:scale-[0.98] cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">add_circle</span>
              Tambah Bahan Masakan
            </button>
          )}
        </div>
      </section>

      {/* Section 3: Step-by-Step Instructions */}
      <section className="px-margin mt-space-lg">
        <div className="bg-surface-container-lowest rounded-[2rem] p-space-md shadow-sm">
          <div className="flex items-center justify-between mb-space-sm">
            <div className="flex items-center gap-space-xs">
              <span className="material-symbols-outlined text-primary text-[20px]">
                format_list_numbered
              </span>
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Langkah Memasak</h3>
            </div>
            <span className="font-label-sm text-label-sm text-on-surface-variant">
              {steps.length} Tahapan
            </span>
          </div>

          <div className="space-y-space-md">
            {steps.map((step, index) => (
              <div key={step.id} className="flex gap-space-sm items-start">
                <div
                  className={`w-7 h-7 rounded-full text-on-primary flex items-center justify-center font-label-md text-label-md shrink-0 shadow-sm ${
                    index === 0 ? 'bg-inverse-surface' : 'bg-primary'
                  }`}
                >
                  {index + 1}
                </div>
                <div className="flex-1 bg-surface-container-low rounded-DEFAULT p-space-md">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="font-headline-sm text-headline-sm text-on-surface text-[14px]">
                      {step.title}
                    </h4>
                    <button
                      type="button"
                      onClick={() =>
                        steps.length > 1 &&
                        setSteps((prev) => prev.filter((s) => s.id !== step.id))
                      }
                      aria-label="Hapus langkah"
                      className="text-outline hover:text-error cursor-pointer"
                    >
                      <span className="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <p className="font-body-md text-body-md text-on-surface-variant">
                    {step.description}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {showAddStepForm ? (
            <div className="mt-space-md p-3 rounded-DEFAULT bg-surface-container-low space-y-2">
              <input
                type="text"
                value={newStepTitle}
                onChange={(e) => setNewStepTitle(e.target.value)}
                placeholder="Judul langkah (mis. Penyajian & Garnish)"
                className="w-full px-3 py-2 rounded-xl bg-surface-container-lowest text-on-surface font-body-sm text-body-sm outline-none"
              />
              <textarea
                rows={2}
                value={newStepDesc}
                onChange={(e) => setNewStepDesc(e.target.value)}
                placeholder="Jelaskan instruksi langkah memasak..."
                className="w-full px-3 py-2 rounded-xl bg-surface-container-lowest text-on-surface font-body-sm text-body-sm outline-none resize-none"
              />
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddStepForm(false)}
                  className="px-3 py-1.5 rounded-xl bg-surface-container-high text-on-surface-variant font-label-md text-label-md"
                >
                  Batal
                </button>
                <button
                  type="button"
                  onClick={handleAddStep}
                  className="px-4 py-1.5 rounded-xl bg-primary text-on-primary font-label-md text-label-md"
                >
                  Tambah Langkah
                </button>
              </div>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setShowAddStepForm(true)}
              className="w-full mt-space-md py-3 rounded-DEFAULT bg-surface-container-high text-on-surface-variant hover:bg-surface-variant hover:text-on-surface font-label-md text-label-md flex items-center justify-center gap-space-xs transition-all active:scale-[0.98] cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">add_task</span>
              Tambah Langkah Baru
            </button>
          )}
        </div>
      </section>

      {/* Primary Action Button */}
      <section className="px-margin mt-space-xl flex flex-col gap-space-sm">
        <button
          type="button"
          disabled={isPublishing}
          onClick={handlePublish}
          className={`w-full py-4 rounded-full text-on-primary font-headline-sm text-headline-sm flex items-center justify-center gap-space-sm shadow-xl shadow-primary/20 transition-all active:scale-95 group cursor-pointer ${
            publishedSuccess ? 'bg-tertiary-container' : 'bg-primary hover:bg-primary-container'
          }`}
        >
          {isPublishing ? (
            <>
              <span className="inline-block animate-spin material-symbols-outlined text-[20px]">
                progress_activity
              </span>
              <span>Mengunggah Kreasi...</span>
            </>
          ) : publishedSuccess ? (
            <>
              <span className="material-symbols-outlined text-[20px]">done_all</span>
              <span>Resep Berhasil Terbit!</span>
            </>
          ) : (
            <>
              <span>Terbitkan Resep Sekarang</span>
              <span className="material-symbols-outlined text-[20px] group-hover:translate-x-1 transition-transform">
                arrow_forward
              </span>
            </>
          )}
        </button>
      </section>
    </div>
  );
};

// ============================================================================
// 4. FAVORIT SCREEN (Image_9 / Image_10)
// ============================================================================
export const FavoritScreen: React.FC<CommonScreenProps> = ({
  recipes,
  onToggleFavorite,
  onSelectRecipe,
  showToast,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState('all');
  const [sortOrder, setSortOrder] = useState<'newest' | 'popular'>('newest');

  const chips = [
    { id: 'all', label: 'Semua' },
    { id: 'asian', label: 'Asian Food' },
    { id: 'western', label: 'Western' },
    { id: 'pasta', label: 'Pasta' },
    { id: 'dessert', label: 'Camilan & Dessert' },
    { id: 'healthy', label: 'Diet Sehat' },
  ];

  const favoriteRecipes = recipes
    .filter((r) => r.isFavorite)
    .filter((r) => {
      const matchCat =
        activeCategory === 'all' ||
        r.filterKey.toLowerCase().includes(activeCategory) ||
        r.category.toLowerCase().includes(activeCategory);
      const matchSearch =
        !searchQuery.trim() ||
        r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        r.author.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    })
    .sort((a, b) => (sortOrder === 'popular' ? b.likesCount - a.likesCount : 0));

  return (
    <div className="flex flex-col w-full px-margin pb-space-xl">
      {/* Header Intro & Summary */}
      <section className="mt-space-sm mb-space-md">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="font-headline-lg text-headline-lg text-on-surface tracking-tight">
              Resep Favorit
            </h2>
            <p className="font-body-md text-body-md text-on-surface-variant mt-0.5">
              Kumpulan inspirasi masakan yang kamu simpan
            </p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary-fixed flex items-center justify-center text-primary shadow-sm shrink-0">
            <span className="material-symbols-outlined material-symbols-filled text-[22px]">
              bookmark
            </span>
          </div>
        </div>
      </section>

      {/* Search & Filter Bar */}
      <section className="mb-space-md">
        <div className="flex items-center gap-space-sm">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
              search
            </span>
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-surface-container-high text-on-surface placeholder:text-on-surface-variant font-body-md text-body-md rounded-xl pl-10 pr-4 py-3 focus:outline-none focus:bg-surface-container-lowest transition-all shadow-sm"
              placeholder="Cari di resep favorit..."
              type="text"
            />
          </div>
          <button
            type="button"
            onClick={() => {
              setSortOrder((prev) => (prev === 'newest' ? 'popular' : 'newest'));
              showToast(
                `Diurutkan berdasarkan ${
                  sortOrder === 'newest' ? 'Paling Disukai' : 'Terbaru Disimpan'
                }`,
                'sort'
              );
            }}
            aria-label="Filter Resep"
            className="w-12 h-12 rounded-xl bg-surface-container-high text-on-surface flex items-center justify-center hover:bg-surface-container-highest active:scale-95 transition-all shadow-sm cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">tune</span>
          </button>
        </div>
      </section>

      {/* Filter Category Chips */}
      <section className="mb-space-md -mx-margin px-margin overflow-x-auto no-scrollbar flex items-center gap-space-sm py-1">
        {chips.map((chip) => {
          const isActive = activeCategory === chip.id;
          return (
            <button
              key={chip.id}
              type="button"
              onClick={() => setActiveCategory(chip.id)}
              className={`flex-shrink-0 px-4 py-2 rounded-full font-label-md text-label-md whitespace-nowrap transition-transform active:scale-95 cursor-pointer ${
                isActive
                  ? 'bg-inverse-surface text-inverse-on-surface shadow-sm'
                  : 'bg-surface-container-high text-on-surface-variant hover:text-on-surface'
              }`}
            >
              {chip.label}
            </button>
          );
        })}
      </section>

      {/* Status & Sort Dropdown */}
      <section className="flex items-center justify-between mb-space-md text-on-surface-variant">
        <span className="font-label-md text-label-md tracking-wide">
          <strong className="text-on-surface font-semibold font-body-md text-body-md tabular-nums">
            {favoriteRecipes.length}
          </strong>{' '}
          Resep Ditampilkan
        </span>
        <button
          type="button"
          onClick={() => setSortOrder((prev) => (prev === 'newest' ? 'popular' : 'newest'))}
          className="relative inline-flex items-center gap-1 cursor-pointer bg-surface-container-low px-3 py-1.5 rounded-full shadow-sm"
        >
          <span className="font-label-md text-label-md text-on-surface whitespace-nowrap">
            {sortOrder === 'newest' ? 'Terbaru Disimpan' : 'Paling Disukai'}
          </span>
          <span className="material-symbols-outlined text-[16px] text-on-surface-variant">
            expand_more
          </span>
        </button>
      </section>

      {/* Recipe Cards Feed */}
      {favoriteRecipes.length > 0 ? (
        <section className="flex flex-col gap-space-md">
          {favoriteRecipes.map((recipe) => (
            <article
              key={recipe.id}
              onClick={() => onSelectRecipe(recipe)}
              className="relative bg-inverse-surface text-inverse-on-surface rounded-[2rem] p-space-md shadow-md overflow-hidden transition-all duration-300 cursor-pointer active:scale-[0.99]"
            >
              <div className="flex gap-space-md items-start">
                {/* Dish Thumbnail with Plated Vignette */}
                <div className="relative w-28 h-28 flex-shrink-0 rounded-full overflow-hidden bg-surface-container-highest/20 shadow-inner flex items-center justify-center">
                  <img
                    className="w-full h-full object-cover scale-105"
                    alt={recipe.title}
                    src={
                      recipe.id === 'japanese-beef-curry'
                        ? IMAGES.beefCurryFav
                        : recipe.id === 'creamy-truffle-pasta'
                        ? IMAGES.trufflePastaFav
                        : recipe.image
                    }
                    referrerPolicy="no-referrer"
                  />
                </div>
                {/* Recipe Content Info */}
                <div className="flex-1 min-w-0 pr-6">
                  <div className="flex items-center gap-space-xs mb-1">
                    <span className="px-2.5 py-0.5 rounded-full font-label-sm text-label-sm bg-surface-container-highest/20 text-inverse-on-surface whitespace-nowrap">
                      {recipe.category}
                    </span>
                  </div>
                  <h3 className="font-headline-sm text-headline-sm text-inverse-on-surface font-bold truncate">
                    {recipe.title}
                  </h3>
                  <p className="font-body-sm text-body-sm text-surface-variant/80 mt-0.5 truncate">
                    {recipe.author}
                  </p>
                  <div className="flex items-center gap-space-sm text-surface-variant/70 font-label-sm text-label-sm mt-2">
                    <span className="flex items-center gap-1 whitespace-nowrap">
                      <span className="material-symbols-outlined text-[14px]">schedule</span>
                      {recipe.time}
                    </span>
                    <span className="flex items-center gap-1 whitespace-nowrap">
                      <span className="material-symbols-outlined text-[14px]">equalizer</span>
                      {recipe.difficulty}
                    </span>
                  </div>
                </div>
              </div>

              {/* Action Footer */}
              <div className="flex items-center justify-between mt-space-md pt-space-xs">
                <div className="flex items-center gap-1.5 text-primary-fixed-dim font-label-sm text-label-sm">
                  <span className="material-symbols-outlined material-symbols-filled text-[16px]">
                    thumb_up
                  </span>
                  <span>{recipe.likes} Suka</span>
                </div>
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    onSelectRecipe(recipe);
                  }}
                  className="px-4 py-2 rounded-full bg-primary-container text-on-primary-container font-label-md text-label-md hover:opacity-90 active:scale-95 transition-all shadow-sm whitespace-nowrap cursor-pointer"
                >
                  Lihat Resep
                </button>
              </div>

              {/* Floating Unfavorite Heart Button */}
              <button
                type="button"
                onClick={(e) => onToggleFavorite(recipe.id, e)}
                aria-label="Hapus dari Favorit"
                className="absolute top-space-md right-space-md w-8 h-8 rounded-full bg-surface-container-lowest/15 backdrop-blur-md flex items-center justify-center text-primary-fixed-dim hover:text-white transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined material-symbols-filled text-[18px] text-[#ff4d6d]">
                  favorite
                </span>
              </button>
            </article>
          ))}
        </section>
      ) : (
        <div className="flex flex-col items-center justify-center text-center py-space-xl px-space-md my-space-md bg-surface-container-low rounded-2xl">
          <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center text-primary mb-3">
            <span className="material-symbols-outlined text-[32px]">ramen_dining</span>
          </div>
          <h4 className="font-headline-sm text-headline-sm text-on-surface font-semibold">
            Resep Tidak Ditemukan
          </h4>
          <p className="font-body-sm text-body-sm text-on-surface-variant max-w-[240px] mt-1">
            Coba kata kunci lain atau telusuri koleksi kategori resep lainnya.
          </p>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setActiveCategory('all');
            }}
            className="mt-4 px-4 py-2 rounded-full bg-inverse-surface text-inverse-on-surface font-label-md text-label-md active:scale-95 transition-all cursor-pointer"
          >
            Reset Pencarian
          </button>
        </div>
      )}

      {/* Bottom Tip Banner */}
      <aside
        onClick={() =>
          showToast('Jadwal masak mingguan tersinkronisasi dengan koleksi Favoritmu!', 'event_available')
        }
        className="mt-space-lg p-space-md rounded-2xl bg-surface-container flex items-center gap-space-sm cursor-pointer hover:bg-surface-container-high transition-colors"
      >
        <div className="w-10 h-10 rounded-full bg-primary-fixed flex items-center justify-center text-primary flex-shrink-0">
          <span className="material-symbols-outlined text-[20px]">lightbulb</span>
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-label-md text-label-md text-on-surface font-semibold">
            Mau masak apa minggu ini?
          </p>
          <p className="font-body-sm text-body-sm text-on-surface-variant truncate">
            Atur jadwal masak mingguan dari resep tersimpanmu.
          </p>
        </div>
        <span className="material-symbols-outlined text-[18px] text-on-surface-variant">
          arrow_forward
        </span>
      </aside>
    </div>
  );
};

// ============================================================================
// 5. PROFIL SCREEN (Image_7 / Image_8)
// ============================================================================
export const ProfilScreen: React.FC<
  CommonScreenProps & {
    onDeleteRecipe: (id: string) => void;
    userProfile: { name: string; email: string; handle: string };
    onUpdateProfile: (profile: { name: string; email: string; handle: string }) => void;
  }
> = ({
  recipes,
  onSelectRecipe,
  onNavigate,
  onDeleteRecipe,
  showToast,
  userProfile,
  onUpdateProfile,
}) => {
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [editName, setEditName] = useState(userProfile.name);
  const [editEmail, setEditEmail] = useState(userProfile.email);
  const [editHandle, setEditHandle] = useState(userProfile.handle);
  const [sortLatest, setSortLatest] = useState(true);

  const myRecipes = recipes.filter((r) => r.isMyRecipe);

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    onUpdateProfile({
      name: editName.trim() || 'Anna Roberts',
      email: editEmail.trim() || 'anna.roberts@email.com',
      handle: editHandle.trim() || '@annacooks',
    });
    setIsEditingProfile(false);
    showToast('Profil berhasil diperbarui!', 'check_circle');
  };

  return (
    <div className="flex flex-col w-full">
      {/* Profile Header Section */}
      <section className="flex flex-col px-margin pt-space-xs pb-space-md">
        <div className="flex items-center gap-space-md">
          <div className="relative shrink-0">
            <div className="w-20 h-20 rounded-full overflow-hidden shadow-sm bg-surface-container">
              <img
                className="w-full h-full object-cover"
                alt={userProfile.name}
                src={IMAGES.annaRobertsAvatar}
                referrerPolicy="no-referrer"
              />
            </div>
          </div>
          <div className="flex flex-col flex-1 min-w-0">
            <h2 className="font-headline-sm text-headline-sm text-on-surface truncate font-bold">
              {userProfile.name}
            </h2>
            <p className="font-body-sm text-body-sm text-on-surface-variant truncate">
              {userProfile.email}
            </p>
            <p className="font-label-sm text-label-sm text-on-surface-variant mt-0.5">
              {userProfile.handle}
            </p>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('admin-settings')}
            aria-label="Pengaturan Profil"
            className="w-10 h-10 rounded-full bg-surface-container hover:bg-surface-container-high active:scale-95 text-on-surface flex items-center justify-center transition-all shadow-sm shrink-0 cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">settings</span>
          </button>
        </div>

        <div className="flex items-center gap-space-sm mt-4">
          <button
            type="button"
            onClick={() => setIsEditingProfile((prev) => !prev)}
            className="flex-1 py-2.5 px-4 rounded-xl bg-surface-container-high hover:bg-surface-variant active:scale-98 text-on-surface font-label-md text-label-md transition-all flex items-center justify-center gap-2 cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">edit</span>
            <span>Edit Profil</span>
          </button>
        </div>

        {isEditingProfile && (
          <form
            onSubmit={handleSaveProfile}
            className="mt-3 p-4 rounded-2xl bg-surface-container-lowest shadow-sm space-y-3"
          >
            <div>
              <label className="font-label-sm text-label-sm text-on-surface-variant">
                Nama Lengkap
              </label>
              <input
                type="text"
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="w-full mt-1 px-3 py-2 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
            </div>
            <div>
              <label className="font-label-sm text-label-sm text-on-surface-variant">Email</label>
              <input
                type="email"
                value={editEmail}
                onChange={(e) => setEditEmail(e.target.value)}
                className="w-full mt-1 px-3 py-2 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
            </div>
            <div>
              <label className="font-label-sm text-label-sm text-on-surface-variant">
                Username
              </label>
              <input
                type="text"
                value={editHandle}
                onChange={(e) => setEditHandle(e.target.value)}
                className="w-full mt-1 px-3 py-2 rounded-xl bg-surface-container-low text-on-surface font-body-sm text-body-sm outline-none"
              />
            </div>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setIsEditingProfile(false)}
                className="px-3 py-1.5 rounded-xl bg-surface-container text-on-surface-variant font-label-md text-label-md"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-4 py-1.5 rounded-xl bg-primary text-on-primary font-label-md text-label-md"
              >
                Simpan Profil
              </button>
            </div>
          </form>
        )}

        <div className="grid gap-3 mt-4 p-3 rounded-2xl bg-surface-container-lowest shadow-sm">
          <div className="flex flex-col items-center justify-center py-1.5 rounded-xl bg-surface-container-low/50">
            <span className="font-headline-sm text-headline-sm text-on-surface font-bold tracking-tight tabular-nums">
              {11 + myRecipes.length}
            </span>
            <span className="font-label-sm text-label-sm text-on-surface-variant">Resep Saya</span>
          </div>
        </div>
      </section>

      {/* Interactive Quick Action Banner */}
      <div className="px-margin mb-space-md">
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-primary-container to-primary text-on-primary p-4 shadow-md flex items-center justify-between gap-2">
          <div className="flex items-center gap-3 z-10">
            <div className="w-10 h-10 rounded-xl bg-on-primary/20 backdrop-blur-md flex items-center justify-center text-on-primary shrink-0">
              <span className="material-symbols-outlined text-[24px]">soup_kitchen</span>
            </div>
            <div className="flex flex-col">
              <h3 className="font-label-lg text-label-lg font-bold text-on-primary leading-tight">
                Punya kreasi baru hari ini?
              </h3>
              <p className="font-body-sm text-body-sm text-on-primary/80">
                Unggah foto &amp; langkah memasakmu
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('unggah-resep')}
            className="z-10 px-3.5 py-2 rounded-full bg-surface-container-lowest text-primary font-label-md text-label-md shadow-sm active:scale-95 transition-all flex items-center gap-1 shrink-0 font-bold whitespace-nowrap cursor-pointer"
          >
            <span className="material-symbols-outlined text-[16px]">add</span>
            <span>Buat Resep</span>
          </button>
          <div className="absolute -right-6 -bottom-6 w-24 h-24 rounded-full bg-on-primary/10 pointer-events-none"></div>
        </div>
      </div>

      {/* Segmented Tab Switcher */}
      <section className="flex flex-col w-full">
        <div className="flex items-center justify-between px-margin border-none bg-surface-container-low/40">
          <div className="flex items-center gap-6 overflow-x-auto w-full">
            <button
              type="button"
              className="relative py-3 font-label-lg text-label-lg text-primary font-bold flex items-center gap-1.5 transition-colors"
            >
              <span>Resep Publik</span>
              <span className="px-2 py-0.5 rounded-full bg-primary-fixed text-on-primary-fixed font-label-sm text-label-sm tabular-nums">
                {11 + myRecipes.length}
              </span>
              <div className="absolute bottom-0 inset-x-0 h-0.5 bg-primary rounded-full"></div>
            </button>
          </div>
        </div>

        <div className="flex items-center justify-between px-margin py-3">
          <span className="font-label-sm text-label-sm text-on-surface-variant font-medium">
            Daftar Resep Aktif
          </span>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setSortLatest((prev) => !prev)}
              className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-surface-container text-on-surface font-label-sm text-label-sm cursor-pointer"
            >
              <span>{sortLatest ? 'Terbaru' : 'Terpopuler'}</span>
              <span className="material-symbols-outlined text-[14px]">expand_more</span>
            </button>
          </div>
        </div>

        <div className="flex flex-col gap-3 px-margin mb-6">
          {(sortLatest ? myRecipes : [...myRecipes].reverse()).map((recipe) => {
            const thumbImg =
              recipe.id === 'nasi-lemak'
                ? IMAGES.nasiLemakProfile
                : recipe.id === 'homemade-pepperoni-pizza'
                ? IMAGES.pizzaMargheritaProfile
                : recipe.id === 'chicken-mentai-rice'
                ? IMAGES.chickenMentaiProfile
                : recipe.image;
            const displayTitle =
              recipe.id === 'nasi-lemak'
                ? 'Nasi Lemak Istimewa'
                : recipe.id === 'homemade-pepperoni-pizza'
                ? 'Homemade Pizza Margherita'
                : recipe.title;

            return (
              <div
                key={recipe.id}
                onClick={() => onSelectRecipe(recipe)}
                className="flex items-center gap-3 p-3 rounded-2xl bg-surface-container-lowest shadow-sm cursor-pointer hover:bg-surface-container-low/40 transition-colors"
              >
                <div className="w-16 h-16 rounded-full overflow-hidden shrink-0 bg-surface-container">
                  <img
                    className="w-full h-full object-cover"
                    alt={displayTitle}
                    src={thumbImg}
                    referrerPolicy="no-referrer"
                  />
                </div>
                <div className="flex flex-col flex-1 min-w-0">
                  <div className="flex items-center gap-1.5 mb-0.5 flex-wrap">
                    <span className="px-2 py-0.5 rounded-md bg-surface-container-high text-on-surface-variant font-label-sm text-label-sm whitespace-nowrap">
                      {recipe.id === 'chicken-mentai-rice' ? 'Asian Fusion' : recipe.category}
                    </span>
                    <span className="text-on-surface-variant font-body-sm text-body-sm whitespace-nowrap">
                      • {recipe.publishedAgo}
                    </span>
                  </div>
                  <h4 className="font-headline-sm text-headline-sm text-on-surface font-semibold truncate">
                    {displayTitle}
                  </h4>
                  <p className="font-body-sm text-body-sm text-on-surface-variant line-clamp-1">
                    {recipe.description}
                  </p>
                </div>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onNavigate('unggah-resep');
                      showToast(`Membuka editor untuk "${displayTitle}"`, 'edit');
                    }}
                    aria-label="Edit Resep"
                    className="w-8 h-8 rounded-full hover:bg-surface-container text-on-surface-variant flex items-center justify-center transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">edit</span>
                  </button>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteRecipe(recipe.id);
                    }}
                    aria-label="Hapus Resep"
                    className="w-8 h-8 rounded-full hover:bg-error-container text-on-surface-variant hover:text-error flex items-center justify-center transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">delete</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Account Settings Section (matching Image_7_5ca1ce0e.jpeg) */}
      <section className="px-margin pb-8">
        <h3 className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant mb-2.5 px-1">
          PENGATURAN AKUN
        </h3>
        <div className="bg-surface-container-lowest rounded-2xl shadow-sm overflow-hidden divide-y divide-surface-container">
          <button
            type="button"
            onClick={() => onNavigate('unggah-resep')}
            className="w-full p-3.5 flex items-center justify-between hover:bg-surface-container-low transition-colors text-left cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant">
                <span className="material-symbols-outlined text-[19px]">menu_book</span>
              </div>
              <span className="font-body-md text-body-md text-on-surface font-medium">
                Resep Saya
              </span>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
              chevron_right
            </span>
          </button>

          <button
            type="button"
            onClick={() => onNavigate('favorit')}
            className="w-full p-3.5 flex items-center justify-between hover:bg-surface-container-low transition-colors text-left cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant">
                <span className="material-symbols-outlined text-[19px]">bookmark</span>
              </div>
              <span className="font-body-md text-body-md text-on-surface font-medium">
                Resep Favorit / Disimpan
              </span>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
              chevron_right
            </span>
          </button>

          <button
            type="button"
            onClick={() => onNavigate('admin-recipes')}
            className="w-full p-3.5 flex items-center justify-between hover:bg-surface-container-low transition-colors text-left cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant">
                <span className="material-symbols-outlined text-[19px]">manage_accounts</span>
              </div>
              <span className="font-body-md text-body-md text-on-surface font-medium">
                Pengaturan Akun &amp; Panel Admin
              </span>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
              chevron_right
            </span>
          </button>

          <button
            type="button"
            onClick={() =>
              showToast('Resep Oma v2.4 — Komunitas Kuliner Nusantara & Dunia', 'info')
            }
            className="w-full p-3.5 flex items-center justify-between hover:bg-surface-container-low transition-colors text-left cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant">
                <span className="material-symbols-outlined text-[19px]">help</span>
              </div>
              <span className="font-body-md text-body-md text-on-surface font-medium">
                Bantuan &amp; Tentang Aplikasi
              </span>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
              chevron_right
            </span>
          </button>

          <button
            type="button"
            onClick={() => {
              showToast('Keluar dari sesi pengguna', 'logout');
              onNavigate('login');
            }}
            className="w-full p-3.5 flex items-center justify-between hover:bg-error-container/20 transition-colors text-left cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-primary-fixed/50 flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[19px]">logout</span>
              </div>
              <span className="font-body-md text-body-md text-primary font-semibold">Keluar</span>
            </div>
            <span className="material-symbols-outlined text-primary text-[18px]">
              chevron_right
            </span>
          </button>
        </div>
      </section>
    </div>
  );
};
