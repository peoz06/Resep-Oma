import React, { useState } from 'react';
import { Recipe } from '../data/mockData';

export const RecipeDetailModal: React.FC<{
  recipe: Recipe | null;
  onClose: () => void;
  onToggleFavorite: (id: string, e?: React.MouseEvent) => void;
  showToast: (msg: string, icon?: string) => void;
}> = ({ recipe, onClose, onToggleFavorite, showToast }) => {
  const [checkedIngredients, setCheckedIngredients] = useState<Record<string, boolean>>({});

  if (!recipe) return null;

  const toggleCheck = (id: string) => {
    setCheckedIngredients((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[430px] max-h-[90vh] bg-surface text-on-surface rounded-t-[2rem] sm:rounded-[2rem] overflow-y-auto no-scrollbar shadow-2xl flex flex-col"
      >
        {/* Top Hero Slate Header */}
        <div className="bg-inverse-surface text-surface-bright p-space-md relative overflow-hidden">
          <div className="w-10 h-1.5 bg-white/20 rounded-full mx-auto mb-3 sm:hidden" />
          <div className="flex items-center justify-between">
            <button
              type="button"
              onClick={onClose}
              className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center text-white hover:bg-white/20 transition-colors cursor-pointer"
            >
              <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            </button>
            <span className="px-3 py-1 rounded-full bg-white/15 text-white font-label-sm text-label-sm">
              {recipe.category}
            </span>
            <button
              type="button"
              onClick={(e) => onToggleFavorite(recipe.id, e)}
              className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center text-primary-fixed-dim hover:bg-white/20 transition-colors cursor-pointer"
            >
              <span
                className={`material-symbols-outlined text-[20px] ${
                  recipe.isFavorite ? 'material-symbols-filled text-[#ff4d6d]' : 'text-white'
                }`}
              >
                favorite
              </span>
            </button>
          </div>

          <div className="flex flex-col items-center text-center my-4">
            <div className="w-36 h-36 rounded-full p-1 bg-gradient-to-tr from-primary to-white/20 shadow-2xl mb-3">
              <img
                src={recipe.image}
                alt={recipe.title}
                referrerPolicy="no-referrer"
                className="w-full h-full object-cover rounded-full"
              />
            </div>
            <h2 className="font-headline-md text-headline-md text-white">{recipe.title}</h2>
            <p className="font-body-sm text-body-sm text-white/70 mt-1">
              oleh <strong className="text-white">{recipe.author}</strong> • {recipe.publishedAgo}
            </p>
          </div>

          <div className="grid grid-cols-3 gap-2 pt-2">
            <div className="bg-white/10 rounded-xl p-2 text-center">
              <span className="font-label-sm text-label-sm text-white/70 block">Waktu</span>
              <span className="font-headline-sm text-headline-sm text-white">{recipe.time}</span>
            </div>
            <div className="bg-white/10 rounded-xl p-2 text-center">
              <span className="font-label-sm text-label-sm text-white/70 block">Porsi</span>
              <span className="font-headline-sm text-headline-sm text-white">
                {recipe.servings}
              </span>
            </div>
            <div className="bg-white/10 rounded-xl p-2 text-center">
              <span className="font-label-sm text-label-sm text-white/70 block">Tingkat</span>
              <span className="font-headline-sm text-headline-sm text-white">
                {recipe.difficulty}
              </span>
            </div>
          </div>
        </div>

        {/* Body Content */}
        <div className="p-space-md space-y-space-md">
          <p className="font-body-md text-body-md text-on-surface-variant leading-relaxed">
            {recipe.description}
          </p>

          {/* Ingredients */}
          <div className="bg-surface-container-lowest rounded-2xl p-space-md shadow-xs">
            <div className="flex items-center justify-between mb-2.5">
              <h3 className="font-headline-sm text-headline-sm text-on-surface flex items-center gap-1.5">
                <span className="material-symbols-outlined text-primary text-[20px]">kitchen</span>
                Bahan-Bahan
              </h3>
              <span className="font-label-sm text-label-sm text-primary bg-primary-fixed px-2.5 py-0.5 rounded-full">
                {recipe.ingredients.length} Bahan
              </span>
            </div>
            <div className="space-y-2">
              {recipe.ingredients.map((ing) => {
                const isChecked = !!checkedIngredients[ing.id];
                return (
                  <button
                    key={ing.id}
                    type="button"
                    onClick={() => toggleCheck(ing.id)}
                    className="w-full flex items-center justify-between p-2.5 rounded-xl bg-surface-container-low hover:bg-surface-container transition-colors text-left cursor-pointer"
                  >
                    <div className="flex items-center gap-2.5 min-w-0">
                      <span
                        className={`material-symbols-outlined text-[18px] ${
                          isChecked ? 'text-primary material-symbols-filled' : 'text-outline'
                        }`}
                      >
                        {isChecked ? 'check_circle' : 'radio_button_unchecked'}
                      </span>
                      <span
                        className={`font-body-md text-body-md truncate ${
                          isChecked ? 'line-through text-secondary' : 'text-on-surface'
                        }`}
                      >
                        {ing.name}
                      </span>
                    </div>
                    <span className="font-label-sm text-label-sm text-primary font-semibold shrink-0 ml-2">
                      {ing.amount}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Steps */}
          <div className="bg-surface-container-lowest rounded-2xl p-space-md shadow-xs">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-headline-sm text-headline-sm text-on-surface flex items-center gap-1.5">
                <span className="material-symbols-outlined text-primary text-[20px]">
                  format_list_numbered
                </span>
                Langkah Memasak
              </h3>
              <span className="font-label-sm text-label-sm text-secondary">
                {recipe.steps.length} Tahapan
              </span>
            </div>
            <div className="space-y-3">
              {recipe.steps.map((step, i) => (
                <div key={step.id} className="flex gap-3 items-start">
                  <div className="w-7 h-7 rounded-full bg-primary text-on-primary font-label-md text-label-md flex items-center justify-center shrink-0">
                    {i + 1}
                  </div>
                  <div className="flex-1 bg-surface-container-low rounded-xl p-3">
                    <h4 className="font-headline-sm text-[14px] text-on-surface mb-1">
                      {step.title}
                    </h4>
                    <p className="font-body-sm text-body-sm text-on-surface-variant leading-relaxed">
                      {step.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <button
            type="button"
            onClick={() => {
              showToast(`Selamat memasak ${recipe.title}! Recook tercatat.`, 'restaurant');
              onClose();
            }}
            className="w-full py-3.5 rounded-full bg-primary text-on-primary font-headline-sm text-headline-sm shadow-lg active:scale-95 transition-transform flex items-center justify-center gap-2 cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">skillet</span>
            <span>Mulai Masak &amp; Tandai Recook</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export const AiFridgeModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  recipes: Recipe[];
  onSelectRecipe: (recipe: Recipe) => void;
}> = ({ isOpen, onClose, recipes, onSelectRecipe }) => {
  const [selectedItems, setSelectedItems] = useState<string[]>(['Telur', 'Nasi', 'Ayam']);

  if (!isOpen) return null;

  const pantryOptions = [
    'Telur',
    'Nasi',
    'Ayam',
    'Salmon',
    'Pasta',
    'Keju',
    'Daging Sapi',
    'Matcha',
    'Udang',
    'Santan',
  ];

  const toggleItem = (item: string) => {
    setSelectedItems((prev) =>
      prev.includes(item) ? prev.filter((i) => i !== item) : [...prev, item]
    );
  };

  const matchedRecipes = recipes.filter((r) =>
    selectedItems.some(
      (kw) =>
        r.title.toLowerCase().includes(kw.toLowerCase()) ||
        r.ingredients.some((ing) => ing.name.toLowerCase().includes(kw.toLowerCase()))
    )
  );

  const results = matchedRecipes.length > 0 ? matchedRecipes.slice(0, 3) : recipes.slice(0, 2);

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[430px] bg-surface text-on-surface rounded-t-[2rem] sm:rounded-[2rem] p-space-md shadow-2xl space-y-4"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-primary text-on-primary flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">auto_awesome</span>
            </div>
            <div>
              <h3 className="font-headline-sm text-headline-sm text-on-surface">
                Kocok Bahan Kulkasmu
              </h3>
              <p className="font-body-sm text-body-sm text-secondary">
                Pilih bahan yang tersedia di dapurmu hari ini
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        <div className="flex flex-wrap gap-2">
          {pantryOptions.map((item) => {
            const active = selectedItems.includes(item);
            return (
              <button
                key={item}
                type="button"
                onClick={() => toggleItem(item)}
                className={`px-3.5 py-1.5 rounded-full font-label-md text-label-md transition-all cursor-pointer ${
                  active
                    ? 'bg-primary text-on-primary shadow-xs'
                    : 'bg-surface-container-high text-on-surface-variant'
                }`}
              >
                {item}
              </button>
            );
          })}
        </div>

        <div className="space-y-2 pt-1">
          <span className="font-label-sm text-label-sm uppercase tracking-wider text-secondary">
            Rekomendasi Resep Cocok ({results.length})
          </span>
          {results.map((r) => (
            <div
              key={r.id}
              onClick={() => {
                onClose();
                onSelectRecipe(r);
              }}
              className="flex items-center justify-between p-2.5 rounded-2xl bg-inverse-surface text-white cursor-pointer hover:opacity-95 transition-opacity"
            >
              <div className="flex items-center gap-3 min-w-0">
                <img
                  src={r.image}
                  alt={r.title}
                  referrerPolicy="no-referrer"
                  className="w-12 h-12 rounded-full object-cover shrink-0"
                />
                <div className="min-w-0">
                  <h4 className="font-headline-sm text-headline-sm text-white truncate">
                    {r.title}
                  </h4>
                  <p className="font-body-sm text-body-sm text-white/70">
                    {r.time} • {r.difficulty}
                  </p>
                </div>
              </div>
              <span className="px-3 py-1 rounded-full bg-primary-container text-white font-label-sm text-label-sm shrink-0">
                Masak
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export const NotificationsModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
}> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

  const items = [
    {
      id: '1',
      title: 'Chef Kenji menyukai resepmu',
      desc: 'Salmon Mentai Rice Bowl Spesial mendapat +24 suka baru.',
      time: '12 menit lalu',
      icon: 'favorite',
    },
    {
      id: '2',
      title: 'Tantangan Dapur Akhir Pekan!',
      desc: 'Unggah kreasi masakan Nusantara dan menangkan badge Koki Utama.',
      time: '2 jam lalu',
      icon: 'local_fire_department',
    },
    {
      id: '3',
      title: 'Sarah Michaels membagikan resep baru',
      desc: 'Creamy Truffle Pasta kini tersedia di katalog Eksplor.',
      time: 'Kemarin',
      icon: 'restaurant_menu',
    },
  ];

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-start justify-center pt-16 px-4"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[400px] bg-surface-container-lowest text-on-surface rounded-2xl p-4 shadow-2xl space-y-3"
      >
        <div className="flex items-center justify-between">
          <h3 className="font-headline-sm text-headline-sm text-on-surface">Notifikasi Terbaru</h3>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
        <div className="divide-y divide-surface-container">
          {items.map((n) => (
            <div key={n.id} className="py-2.5 flex items-start gap-3">
              <div className="w-9 h-9 rounded-full bg-primary-fixed text-primary flex items-center justify-center shrink-0 mt-0.5">
                <span className="material-symbols-outlined material-symbols-filled text-[18px]">
                  {n.icon}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-label-md text-label-md text-on-surface">{n.title}</p>
                <p className="font-body-sm text-body-sm text-on-surface-variant mt-0.5">{n.desc}</p>
                <span className="font-label-sm text-label-sm text-outline mt-1 block">
                  {n.time}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
