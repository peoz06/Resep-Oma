export type ScreenId =
  | 'beranda'
  | 'eksplor'
  | 'unggah-resep'
  | 'favorit'
  | 'profil'
  | 'login'
  | 'register'
  | 'admin-recipes'
  | 'admin-users'
  | 'admin-settings';

export interface Ingredient {
  id: string;
  name: string;
  amount: string;
}

export interface CookingStep {
  id: string;
  title: string;
  description: string;
}

export interface Recipe {
  id: string;
  code: string;
  title: string;
  description: string;
  category: string;
  filterKey: string;
  author: string;
  authorAvatar?: string;
  verified?: boolean;
  likes: string;
  likesCount: number;
  recooks?: string;
  time: string;
  servings: string;
  difficulty: string;
  image: string;
  secondaryImages?: string[];
  isFavorite: boolean;
  isMyRecipe?: boolean;
  publishedAgo: string;
  reportedCount?: number;
  ingredients: Ingredient[];
  steps: CookingStep[];
}

export interface AdminUser {
  id: string;
  code: string;
  name: string;
  email: string;
  avatar: string;
  status: 'Aktif' | 'Ditangguhkan' | 'Baru';
  role: 'Kreator' | 'Pengguna' | 'Admin';
  registeredDate: string;
}

export const IMAGES = {
  // Unggah Resep
  salmonMentaiHero:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCsyxX9au8BFpgZhR4rgWp4tHecw3sg5MTlCxbdehxw-PGh0rnyvPqCeA9E-kTvTO0SE_UX5tESBYd-lArrkYB-9AKmKvqVoyJxg0XyG-mYsR-y32BHiIZLcEI9KGDvpIlGH0PS9PGCdui_MJWnIjlsny4ZUUl5onE05347YNwQ-LkoVVRF99ElvPaQ-h-wR2JZW5wlaPACCKJehBXEk0VmTEhR-W-XVhV1A7qZ2rQJOYwFTJeoGy6u',
  salmonMentaiSub1:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCwOfjbamWJXhU5rlvki9dYHGYbukNUxeGta4X8qx0atIh1qieOeDNFJ5y3ytOl20e8dG-yNxgrylxMb1ijQgjQ5FgIXT702VROfoM5KUt-WOlDqICKd76ji2YFby9Yeg_zykAMKZOVUDQtUErdilsacLjQDQ_cgQqBxZmI_SnsLxoX2Gpz7DSkM0GH0nZd8--nsFGSexhjZnarGgqQyaiLb9wgGyrMrLOWTJ83nHpHcH6RBvmd7D3I',
  salmonMentaiSub2:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDfdWlk42e8zw6Cj56Px_OjJntwQw_zqv7TSfvG88_V8Dnqc3wvVvNza-C-SPR_KT71bQxP1wwMzvqPeBzbFhUrb8hiAGUpOtCP2DdYOyZHcRYAKsa6FaYWE5EQAY111RoisMunqMIqZgjVG9ViCQT7aETOi1NHRakQ_52lBFAiq7qt9gluGMm0cO4uvd4oCrEAjTcBG1kNml8YnPVDGC3dK0QwQXYvnV5ZpFXaCAi5KzyBLTisSxle',

  // Beranda
  nasiLemakHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAAgLPrG6tuPvLMVtDaOfodJIRf2CWNJb-VYdUnbZylAd_u37FZcDeJ0R2oDouJN_O2N51dzFcAQyFD6SXbLrFRItDRnydfU_giqnWNit0KCkwHbDkKbNOYLvFN-EM2L7geNivQDod_GeQZcnhcYY7oYwnyX2qzGYeyutC44rCidHXwFvmwVwSWmHu3A2iAlkDhPG4ukP2MmWBuoayIcJQcjYK3BRn4keWQiWY_n5fTZdxIMYd6rmF9',
  chickenMentaiHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCI_FVvtmJrchVMexVYO4ealDg7snrV91aRNH_EA42t4fA_DzWbeGIuDja_1_Oo-Pr6brC9ackfbu_LfSda_P4eUGaC94eXQv08Jc080YamOsYr0F1v6h_wnnGAlH-HQl-yl5ERmFkmV87hKToHPZLr0uulX1tLWK4yg5SeGSGUBYNYDzAq7fSf6X_R8pUyVV1ph13UssGg8canJYbkIxsutipDwLHMpjyC5TPIan0k83SfNxkq00nT',
  salmonPokeHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDly8qn7IdY5TIm6tHh9arAOtX11ljQUNioHfNwakWeGQnoHdDO9THEnZPNMLcAdFOzbmhhnIamEy6dgWu8pRYtTX8desUnI9Sy_Nt94aPoHeFEqfXqDfIgvc7ZvIQy42ETBI3_KDh3B8mN1egUAr1Zo-O0LWGau7j8B_8yzP6axsaQ95qq6y5f0Jlt8aYovS7uD5_El_yaUhS3Qs0uyIHlHImhrfXuXcYRjVsp1Asyr5OXaGGG-iX1',
  pizzaHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAElSWJHStzTTsurQl1KDcEVLAs-zZAEv3ZCzNxAO9HUHNlUHQ3j7BAD8YWH_46Ug3i_LLEv3Nox2FFqEUXefcV4jtNPvECbYFbkM-I022t2b8DNiPeBTo2rLTRF_5AhlQtPbzPoqbTFUFUvXnbLd8Gxpb2kLNrzxEJT3Ya0JnrgRQrrmIBhsNYQGfGedF7S3Y9gGvtyRqi1rvxadOq_a8GpreKOcEKp7gUnxGIkLEZEvzctYDTdjil',
  dimsumHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBsJb8LUnULuZHgMgQUuSam1HnQ-kbvkQuxuIiSvhEtcjevuC8jhw_JNFlL_wxcXybPNb7hbH6swFrCQVPBA_JdTZJpRNXduWJ8gZjj5Em4iPckXf-K5HT59JAi_YqX0LR8lw0sZjC-kN_ir5ZXLzvoMqvmH7T2y64QLxYSwu_RDbIEqx2OqmpwJ_23wE-1bUXvE7EHVDDE_pzEvyBgcqv8O2NpHWIzHWjp9AdBKN9aXlvG9bBvrNlx',
  carbonaraHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDO9EqGQdFzQLBU4LlDTacZnbKFgpDUyQB1BwKqCrPv1GM64owmcq1tF37-ZNNZXDXoBWuiVjMVY3QoonNRuU2iZL3J-zqLILZxJiYxv8SRSKqG5jdDeofGK62CeCuDJiiOzf0QXDQRuwOfTQErbSjIvJhHo1vYUdZU7b7FTTjC-9mADXthj1nETIQwK1TrRKhMVumx9DHlfrZFTHc21MdINyv-RkkJz1bsiCXDXQhMEcDOiiY5N-bn',
  matchaPancakeHome:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC00THvajHXixCim-fKKMmWMubuFbDv8uI6YmGgo4UdHXixplCsqraALZnJM9GDJIDjwEOAIkVaRT6GXPRHOCY_fNWYpZzCONzj6vKSwHMLCTD5yHkbOMp06wW6bEtXplru1N3cyMbF5hFORPm6ubtoVu_Mb28NNqk5lBAo_NGUa2sIGwce1gWBMe3K3_Pgvn0kqc5ycE3wPxns4nLuG_vgodbBt2GQHSUR53ufzjOtepTK74V_Eaqg',

  // Eksplor
  westernBanner:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCob_q4kXZhFg9S6elWZTi8p4n1QP2m1O2Frfc4XUIg0txOOimO-vw4omAwnKMRMtuUGZjP4THniNsZLNr-_NOTWm_u7bRmZk3rn00Q4S8Vqm-tkgNTGUiCFZZq7NVP_ss9zwTwNM7ebokOA5EwORIauOZanh1r2PB4U9ou646zA3P-PMapg43c3KXa_t0oUHoo0FbN9gjKXJFxZRtZfGKQ2rmxLzQbJiPP9M2Nxm4N9z43iPXDg8GB',
  nusantaraBanner:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuD_CipZITJviI1dXu2Mxw-uAzP7hCID-hlFqOEg51KFi9vHtK1ylzW2wAcyC_EbszXJwNGImZ064_BlzYPT3oLunmRCqXPHYav5Yf8PrehqKmNNYtrNE8OVfFtR4o0zkjk8NqltGV3P1zVHnunwVH2i0I2rBs47AK2TIbxYeMriyQFfZhCyId_PnAx9cObxd8rlHfJT_yQMT_efaBHEh_8wSdq1IsTQqRa0DK8ueH670n0rAtS7-YpS',
  beefCurryExplore:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBmZOR7RoMDyiwyzKWAau4Rgvg5MzKNoH9ceRPCcCnnwOBoZ7Z6Wr-gybl5-XjhuSHe6MkiGRwklpTzLq6uItpRrP4ZvxuUVIxekW5s4pjCdCoRRiMzKxApbmWlJLrLhCq1OGw1GSeY0xkq3GA-SvlXZgTaE7d5FMbGEngGJ4QDhFJsfBi7lg0LZqkDIanZFP5c4y1SPqVKAyjFm4xiRMhdiJJUX90WQazqpjsFrG0znIWUTcKIwWJ6',
  chefKenjiAvatar:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBhf5jD8VWCep9qYNPWI69bf0kF3PArbpXz10v2uIktMPTUF9hDIzShJ__vzlTURKooWJvsMeOHdVQc7UyzzbEKiUmOJETVVvnzi3wMD9iykNdmg2vZXkOKBJ6ylG_fYZM-TTmv7EhCLJ6LjZY9DYgnGzddhkl-bEqFTajDzGS9ETZecDllYxGhN5oaQMUTYbfSeyYcj2_0Tkv6OrzVZ8EuDFaAHe1L0XJtEv3O-lqMi-_EQFgHF8dJ',
  trufflePastaExplore:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCpgiCvEG6XyhTltGKI7Hd40vyYLOZ__SHdNh2k0qMKRT5udtl9o61r2yj1anlowbMWBJkc4PGkFeZc0nzQESMXBsblXs0L8wCWZwKyPvQLvcG_hxXRn-OEqTgy2VgG9PvAG6z5QMcMSnwulNXZgnOpuD9KjHSadO4BQm-V4QwTWmWgzd3ArszmYlLk-ZIjI_Ig1e4JEaJkkX966UKHQlMYzaxwCi9_hbi0zGyTUI4enDSk4nDbeCD9',
  sarahMichaelsAvatar:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB-WtPWGGbCHhQVTXhCgwqevoqJXM95oXwNDTElVg73dNTuMADvbpSSENw2_1KgfraYbeFI_ilqHZ7G1xNg1WwftM-fwEiMkGXCGCp2jFKmTaXSYWUCWcGZoAap5-nr-YO4aUEEYrEHypswDQp3MLH_IMPYGszmBb5zJXoQueP547SmEjuasAZu99xQlViTk1yXo1KY8cx-t0YSi0egjyr6AalWwqtz93GphvTRdsJE4ma4MMbtfhT0',
  ayamBakarExplore:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFfRt-lRVitfPfDiGbkfyhhmfpB2WIz0I7_fNzIhzUxzSunjkuZQ70K_yBRZZhJDcqCrsRyRvZ6A2zjb7r1a0_vWjRuvk4V5bjEVQ9dSWLwmt4Oulk_ngl20Y03sDxMHIXels4HniG5MDGalbay-wO2G-5RvEzz_CikICyc3FqZb1RAzgjr8eJqXbfF__c_GVIIJifBBtAH04EiWpbwUyXi527odzatx78DUs7B7ZIO8Oo7t3Pu0W',
  budiSantosoAvatar:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDJMUFEO5W4D9fa2yovcByIBKe9AR13VSzg4tEZbWNWge7XkycD9WCmwvM3bMW0tVP2xNDwubUYzYtYX_h3WoTCdO-C_DheBbNdXS4z_5JUNOGJE5agV-alqnMVVVxg5LkQiXjZA47txn_cZRHqCZzLftUjflsSet6tSoZz0DbCW-OnlPEdS7QhZkkmoSrykBOBY6L_NFFAAOSQeojG7NU2_4GtT6tE2xyC6wQS48sCemt2TEuCa2-I',

  // Profil
  annaRobertsAvatar:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB_Oin1mlZCrGQ5vqr5IAf1dMxVWDVngwtzggYh5Or0YTPqR4PEQ9WaMqjcB6eRW0XX2Vz8ycbpmRyEUMOU5nIYdepZ-RSaXCFL_r_q7Ivi6tPN_3SrFAPIOoiiA4EzllP2aRWoJEPZnbZ7Z4CN7bY9Chk3mVtkAL76X5vziO4jb0jmvAzDcF1IwzBj9IAAhrUh5nVUTK5bODN2G5diOCbX8946_IKQrBdsQhevIKSbQZqXvRTAF1eo',
  nasiLemakProfile:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAV0jQBTgU962m2-PgHpb1TgqPZJP-xpiKpxFPxT9lK0Ctf5ILs_aNCZCWxgq0Td18-mPx7_9koJxtQf5QwhAP8qGPsVgg7VagmLy1R6q76t4PaAp1L8Go0AgBlrxqeRPZH0FiIGFWLPZ1rF2zxxf-M8mmnpNzB-scBwJo-ELvMd7lgvRxgf6FBNPRpqMGvNvcOAbm-sYB_I5I-sADX_AkYvRQSMOAboADvRKE52iWnVnyIq-9Ca0VW',
  pizzaMargheritaProfile:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAZCvT3hL3bXvbqbHOAK3-8QFj8QUahAAg59Qk9GgmnmKp9TTeMqCJ31rPBe33U7W8GE9v0L5ZXYLBbUuzbg5piA0Z-N79l0rTHy7TneR_wKDNdOqF6pLL_J10yNfyuDMVzXON6Ervqv9F3hs02mSSSJ5c4qbbfs8oL-kJBQJRZw0E2JjUWVdfn22JTIiwbv1G5pvyN6pAUDj5evuFfdPDkIxF11NU6WOp203An7rwLJLGuHolUtA84',
  chickenMentaiProfile:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDN-LfERo7K6M-YYfo4un0LvYS2DybGoajzTGpzdIab9s2lmBWjGc_400cHPXPlo5rGWR24Ko5t3zmI6oj0Ood1mwNiRMzbMtMwpfLa7-_b-wSbR_GmuBUk37uYMiGLXnTJ5bzGwiduxOausm4JVGKHz-unJOrnhGOsDDeFU5lpYIhxPA6G_Zpre7B61m7UBHhmZ9fXeUN87Nc7Q3_bVPZHBaLiivvBMFIGztqeUt-sOHElUnXtAbV2',

  // Favorit
  beefCurryFav:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAk_68xafCTroGu-L0t1RMJXytLsuaE5jktkIPHsiDJfc1is_30i7REkilrhnjLiWlIlgvTqvHD-VNi3D5jfAIccsT3-6rVhgCxwJbt-CMfLI9Oc0aEwVjuNa3Uwz6Z9Gl3m4FntRomjZ51Mh7gTtSB3e83JdwgghXTuPRwyvOtZHdyeTkybT4cHWKmwgeMttB2QzqdSdKdhxuWC1evUbICo2s4A82j_1-0k_BiH6C_VQToiYeIPVGH',
  trufflePastaFav:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBmhdtolxCOwBvQmJ0sLsXVj7zw6uY3OA-yy8ngY9L7BNmdfWzJ4hfTMAkS7xVnd92kAgyPmfIWR0WBrTMyR5CjR_2q0REAJ_td86qC2tqlE-4NOCzmg7bWqf8NWvF242pkoqS0psc1oevPYwMy9uU2yraUbFDJXdt_qQxjqrZs1H-Y75jzNZuhiSZmhoRjaY48e_MWOcXUYFOw8n4MN2p3jZX0Bw6R4vxz4-G90ocS4U1l9si3LhSl',
  salmonMentaiFav:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDvnrWwTGjXUSaevWlUwBx6_Wswb2xGqZWPd7VFFG38cLAjG80XAhv6wFisOk6eN7awRGqt0gwBjdHSwlufNNySPPRuRLoL0Dj3-Erw_b2uHxX6-CI-2gVTTUX5ldnZkBPPBOXZkvL26LlsdnUpQWSG8n-u2yMDVyeQcSlk7nAFe2wemUdgydD0vGwiz0fXnVY7Z2Jwfn8XDgHdNZsy0V8YuTUaHbvMP5XEwuPRU67rG3iet-3kb1iY',
  pepperoniPizzaFav:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB1DIB55Z_nz-VyfG9KoLLMTb32SAwMIT0j_7F2sLGCDpJR1spvqWuikLIwzyMOAYpJc1e8-b_hGrilUOHbOca2a7Xko5j8EdYyI3Qbf5iYMvSuUp1iJhUvW5hjdl-An4ZWTnDt-VZ1Ojq8X2r6fZDA2lJwKXg7bq7Lq7rvZGtuM5F__v7AIYg9jzvHnJQ8KZqc0XfVEb4XeF6v-vl7RDuUjRaFnmb39evIaOg9lGOUnOL2uMSZXQVE',

  // Admin Recipes
  adminNasiLemak:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuB833l1UxlmJ9J8Wmy2FgtAnPz6G2GHET-Z8gjIYorRupw3u8AhdmYqOsU23QS75zDenW-xLOinnxFzm-kuCN6k_BSwjXFBsAO1qiPpKR_x6soP4Hq7wbj-XOhkfCdCK4ragXCJRmMPVv7S84AyYkuiye3k0KCr_ioVZNqy8xGntq1PRyx0XdO5-nm57w0PC5vRukqyTt3QyCLTfl9dWKiDZcg003Kzw6hg-V4xlwlDdmbvQciuDwZH',
  adminCarbonara:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDAK18XfXCd2gZctwMD1kOjEEQP1b6M-LI4aWGC2ktB5OBT4BGeqmYK4Wv4tT0op5D7_A4nLLE_1tRvxxXtinbMoNsfvu2ChxXWyCAqraWrtyOI1FPtyhsiK-fk35MmNAQ-nygMF3BFoHJhT0VTFll-J6o2Q6grtj609r4NTaqeeym_URa5UtBhjzjmp8-tk5B9syWiMcWGEXKSh_0XLpGW3hVvz4_gFKznCNCGLvhqJE0bGLiuvSgF',
  adminDimsum:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBhYF2as8EHX81EzgBrHTYejrNmWccbKMoMnbjmuFq56ufDcKzK_VYIdbmntYfeNBnwZJ-ERkm0BPASQGktYBQ0TTDPTzWS3olg2adGxIn2kqBN3T-CZPkFjVkLWa1jhYh1-LdFNrt6ucFDdJsXXdAJnvJjmo_IIwhFb3tuX8uI5YgIv1av-EW7EgKPYhX3AC014ICmpHQxA9NiCC6wQBurObpp2ZFDvvRM2E71vl31Cn37JvtEzLIm',
  adminAyamBakar:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC6k_S_5SDiQcJ7ZLd2AIbHe12YkIUmJbMNXw14tYB9MjcOi67fVzk3uBnVxC-HHhOd8dng4XAd-TAPLkHjuLhTAlSMVVF1dY2Ij68mj7w7p13JcTKk_xqv7r_yJxD4OHY1lbrPgyDKp1lPPJGKNfzutmZhTaWoPvdn8EWocZ9LhyrxSz8ItQzavR4w_lLea-Hz1XpeT7lRAgOBp7nZhzWlQb7hcfgf6cve_unZsubebiOoYRHnjvjX',
  adminMatchaCrepe:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBIRDzK822uaIzs_pZDkibtszB5PCspmiyCG_z4lhKK31yTbeZVbHrSm_KWjXe8TsIllhHWhIX1geJzavLWgUuGyO7v1wvvwBf1uZnZOwUMaZcLlgWciaTmBIitZr-FWx72pcE12e2ezy9ATjOh-bBAf4BelNIh_Gv52HDzgqBdEKZYILlWRUzgor82y99f_mQcqIR0OJLHhpMnXx9nUMZ0QtN1vYWfEK_G-SN0I1FNEui4hZOQtPbG',
  adminBeefCurry:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA9UoDA4tXXGCDabmpiCH5f5PYUCq2-HFTMScf_8Y9a19UDQBm4ju3SdJ6lqeUqukl_lxwZiN_aZghgvl_jQ82EV33E4TJeILxqUj4ufXn4uO_dP6R7tMNVj_UBPPbJGQdvqgHYKEa8e0ms1T4AQTFoiAzNyKrFt44ov_bSmntWzJYPqcOzlTieC3CxX-m-ZQan1bFsNXc08lpRi8kNZTRn3hGEjMowLpjU2FuejmJQXlLbphATqokV',
  adminAvocadoToast:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDNmOB_xwoJOxkhOQr5zc5ktPikgHZ13bVScN4oyBlRJqwoQ3Fq1Fd02KYNDSsBIarlmDe96VxjGNjkOOdV-znAZEeszclzH4K2etUhwei6qgyh58Zn84pibI7Htqi-VUkMZAK4e8fpfsNM_5SBsmG0ePYGE8m5qZC9TnrxrfCimN2gD7OUvjaePb4X_UmmjRHE-dP6rgCbDxv5ENdNMQnF2-Q-VYp1mgJ2IN9bmARlwHgbm1dcMF5W',

  // Admin Users
  userSarah:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDiMJQyto6iYoms-7Rd7m7Tv5gXuY2Aldr1v8QME-vJyK2I1QtjQQ87Uc8168izygyY09-0TVCDhs_bFEcmFc9s3t6JM0E5ARxzPacsAWYttR8bPHTZXeZRgoX46UgNPiYEjkbWvYKYe-TIx21HktrIs4-ZyCAGXYMyQejNduyyYOuHeoE0R_n9LJevkBdX4lgLxMKhHMZoeugONuuGHUrfq3YUwv1eF54ff2yXvIEYIPpNm_cES3i1',
  userBudi:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDys-ObtXe1Y6uUima1l4-OWdY-LXDU1gLRFFP26rIn-Vl5gRPqpaZJ6hSUGhX-0lO-f-AasFssdA4BCeiv1plxNk74tg2YH8shnRQbGjytjhyYIh_H2cXX9XtEvQ5KYRK2-yfai0xvqIJ-NVfkd0hKh2fv7dXwYOpJaA5-gpY9lnuXHmrcm5nV7M9Rpn8Ua82cHRw51LFTuHoHX39Aj9jTHRKmNM5p9LQFPZNSF3CSfhuh54bhJruX',
  userKenji:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCjrWKGFViS_Ns2IVhL1m_HZyseNIzBAjTPWmL2t9mFvCUTH_n-UMbSwFwmZduPe967-ZQK-0C9w15Q2_Ows1E_wElWoymBLvfKWC0UiOUKQjXmjzGLnZE6-AXjLd6vet-K0Fy3mxW0RzrOQQypmf49RTV2n9GdIaoyJevu9QXVmg1nZQrZDL4quxVnzdhY3JRIqRYK6ngPjwtbg49TMLzlMho2JXrJBLkjVI_VkjApVr8GV8KiQs-0',
  userRian:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBFyLyiVj7llzUtU2kxQtV9RXng8IRco6xN38Anu7l9V06brTLhrqe_6FUt6PrFRyuXE69Pql-Qd_5nhhU58gq_u_6TS1wfL94sSmxD3xaQ31jIdtTNhtfgSiuaiLvx9505o-4AEkUzUX8msno-pyit1hYpk1_xs9ls8e18AvarhblIp38A7MKVD6T7UnvqG09g4bl3sOP5_tEYlYrwYJW-2mPVyf24UceLX3NQrGnNfYnCbumqcYYE',
  userDewi:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDuUFZG4WiflYqgrPJ_TwPk18zO_F_jB3j6iGNZN4ySX4JrWMLe58xmTVOHvxmYdWd2ug7BBJvHtLd-CTPRRyKHw59erpABDYDduLV6xNm1hgrMwtn692oFMcplV9kPK3KnLal1haxbRM4-EJnYKWckiQ-hfRvQ7UGskyk9pMrceOPio0D9yCgY2WNVlmN_mlG4eS8CKvApVTMFUdqkAOhpdmhzzap0RB9B3o_OKIwHsN8t21WNMnt8',
  userAndi:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDhBwK1zdMfEws6qaMw2z-f7g7AQOZuSV5SufPZOpmI6yW4wCEo5PUztzzngaO6PfvqAIJSs_B542JSdd8zNDS04ZtVohXKpApCoWP4yg2MR-DKH_0JwFLtOYc7al915Iz8r-seOZKCaPBEDmGpG0UrmZ7NxitQOvwkvYi7khouAyTZ2HrIU3PH4_SueuO23ens-kl4EwK_GCllA_OnHaLSmg_bhTfYmAzGbG38cDXYHc998oK4IHPW',
  userMaya:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCrRhyCjDKDp3lsdgipyL9MlyCh22-L4_-njuSv9llyqzNfKK_OF9sInshf5nTCF8QrkdLWGu3oR7AQZCBlSLfyGDdVNukvIQmrmoojBMrQqJ4nMO3Opfqn3kS1lh8hUNxFBZCDkXbAbCiIxTjZALFaW5zfoRuVXKPpKEuqmeYv9yZHTEmDY9ivCea3itO6sTwcL2BBnhMBN5SVaHN13Gk1n2IrY395l_QTqHfi5UXwUCrmZptS6tVF',

  // Admin Settings
  adminHeadChef:
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDRy4p1WnJ-YSJrnjcGAQSDN-Mio_sNR6pNH_BC_5rkuC4Ha2Nr24QZp-XnSYafWrWUl23YgpisSffJnDC-1JKy0hOhb0V9XX36rK0nvgVcqTgaEFlR9ZoWIH46lGmrfNZFUe8P2Gygdff6H4wqsae8-e8sYKzn2o40Utws5xpz1V3tkymDs7aBE31Y_fTJqgh0Ls7qNKG8tA0rOBKr9ZXZbAdP7C4A_EDw3WXZizRS9RWf40zQkIZT',
};

export const INITIAL_RECIPES: Recipe[] = [
  {
    id: 'nasi-lemak',
    code: '#RSP-3041',
    title: 'Nasi Lemak',
    description: 'Nasi gurih santan pandan disajikan dengan sambal bilis merah pedas manis, kacang tanah sangrai, telur rebus, dan irisan timun segar.',
    category: 'Asian Food',
    filterKey: 'asian',
    author: 'Sarah Michaels',
    authorAvatar: IMAGES.sarahMichaelsAvatar,
    verified: true,
    likes: '1.5k',
    likesCount: 1500,
    recooks: '920 recook',
    time: '40 Menit',
    servings: '3-4 Porsi',
    difficulty: 'Sedang',
    image: IMAGES.nasiLemakHome,
    isFavorite: true,
    isMyRecipe: true,
    publishedAgo: '2 hari lalu',
    ingredients: [
      { id: '1', name: 'Beras Bulir Panjang & Santan Kental', amount: '350 gram beras + 200 ml santan' },
      { id: '2', name: 'Ikan Bilis / Teri Medan & Kacang Tanah', amount: '100 gram' },
      { id: '3', name: 'Daun Pandan, Serai & Jahe Geprek', amount: '3 lembar pandan + 2 batang serai' },
      { id: '4', name: 'Sambal Tumis Bawang & Cabai Kering', amount: '150 gram' },
    ],
    steps: [
      {
        id: '1',
        title: 'Menanak Nasi Santan Pandan',
        description: 'Cuci bersih beras, masukkan ke rice cooker bersama santan, air, daun pandan simpul, serai, dan sedikit garam hingga matang harum.',
      },
      {
        id: '2',
        title: 'Menumis Sambal & Pelengkap',
        description: 'Tumis bumbu halus cabai kering dan bawang merah hingga pecah minyak, bumbui gula aren dan asam jawa. Sajikan dengan ikan bilis goreng dan telur rebus.',
      },
    ],
  },
  {
    id: 'chicken-mentai-rice',
    code: '#RSP-3040',
    title: 'Chicken Mentai Rice',
    description: 'Saus mentai gurih manis smoky dengan taburan nori dan potongan ayam karage renyah di atas nasi hangat.',
    category: 'Asian Food',
    filterKey: 'asian',
    author: 'Teo Kim',
    authorAvatar: IMAGES.chefKenjiAvatar,
    verified: true,
    likes: '2.1k',
    likesCount: 2100,
    recooks: '1.4k recook',
    time: '30 Menit',
    servings: '2 Porsi',
    difficulty: 'Mudah',
    image: IMAGES.chickenMentaiHome,
    isFavorite: false,
    isMyRecipe: true,
    publishedAgo: '1 minggu lalu',
    ingredients: [
      { id: '1', name: 'Nasi Jepang Hangat & Nori Bubuk', amount: '300 gram' },
      { id: '2', name: 'Paha Ayam Fillet (Marinasi Soy Sauce)', amount: '250 gram' },
      { id: '3', name: 'Mayones Jepang, Tobiko & Saus Sambal', amount: '5 sdm mayo + 2 sdm tobiko' },
    ],
    steps: [
      {
        id: '1',
        title: 'Memasak Ayam & Nasi Nori',
        description: 'Panggang paha ayam marinasi hingga kecokelatan dan potong dadu. Aduk nasi hangat dengan minyak wijen dan furikake.',
      },
      {
        id: '2',
        title: 'Melapisi Saus Mentai & Torch',
        description: 'Tuang saus mentai di atas susunan nasi dan ayam, lalu bakar permukaannya menggunakan blow torch hingga wangi smoky.',
      },
    ],
  },
  {
    id: 'salmon-poke',
    code: '#RSP-3039',
    title: 'Salmon Poke',
    description: 'Semangkuk kesegaran salmon sashimi pilihan dengan saus ponzu wijen, alpukat matang, edamame, dan acar jahe.',
    category: 'Japanese',
    filterKey: 'asian healthy',
    author: 'Maya Lin',
    authorAvatar: IMAGES.userMaya,
    verified: false,
    likes: '1.8k',
    likesCount: 1800,
    recooks: '640 recook',
    time: '20 Menit',
    servings: '2 Porsi',
    difficulty: 'Mudah',
    image: IMAGES.salmonPokeHome,
    isFavorite: false,
    publishedAgo: '3 hari lalu',
    ingredients: [
      { id: '1', name: 'Salmon Sashimi Grade (Potong Dadu)', amount: '200 gram' },
      { id: '2', name: 'Alpukat Mentega, Edamame & Wakame', amount: '1 buah alpukat + 50g edamame' },
      { id: '3', name: 'Saus Shoyu, Minyak Wijen & Biji Wijen', amount: '3 sdm' },
    ],
    steps: [
      {
        id: '1',
        title: 'Marinasi Salmon Segar',
        description: 'Campurkan potongan salmon dengan shoyu, minyak wijen, dan sedikit perasan jeruk nipis. Diamkan di kulkas 10 menit.',
      },
      {
        id: '2',
        title: 'Penyusunan Poke Bowl',
        description: 'Tata sushi rice di mangkuk, susun salmon, irisan alpukat, edamame, dan taburi biji wijen sangrai.',
      },
    ],
  },
  {
    id: 'japanese-beef-curry',
    code: '#RSP-3046',
    title: 'Japanese Beef Curry',
    description: 'Kari daging sapi khas Jepang dengan kuah kental gurih manis dari karamelisasi bawang bombay, kentang, dan wortel lembut.',
    category: 'Asian Food',
    filterKey: 'asian',
    author: 'Chef Kenji',
    authorAvatar: IMAGES.chefKenjiAvatar,
    verified: true,
    likes: '1.2k',
    likesCount: 1200,
    recooks: '1.2k recook',
    time: '45 Menit',
    servings: '4 Porsi',
    difficulty: 'Menengah',
    image: IMAGES.beefCurryExplore,
    isFavorite: true,
    publishedAgo: '5 hari lalu',
    ingredients: [
      { id: '1', name: 'Daging Sapi Sengkel / Chuck (Potong Dadu)', amount: '400 gram' },
      { id: '2', name: 'Blok Roux Kari Jepang, Kentang & Wortel', amount: '100 gram roux + 2 kentang' },
      { id: '3', name: 'Bawang Bombay Karamel & Parutan Apel', amount: '2 buah bombay + 1/2 apel' },
    ],
    steps: [
      {
        id: '1',
        title: 'Menumis Bombay & Daging Sapi',
        description: 'Tumis bawang bombay hingga kecokelatan, masukkan potongan daging sapi hingga berubah warna, lalu tambahkan kaldu dan rebus hingga empuk.',
      },
      {
        id: '2',
        title: 'Memasukkan Sayuran & Blok Kari',
        description: 'Masukkan wortel dan kentang hingga lunak, matikan api sejenak untuk melarutkan blok kari Jepang, lalu masak kembali hingga kuah mengental.',
      },
    ],
  },
  {
    id: 'creamy-truffle-pasta',
    code: '#RSP-3048',
    title: 'Creamy Truffle Pasta',
    description: 'Tagliatelle al dente berbalut saus krim jamur truffle hitam harum dengan taburan keju Parmigiano-Reggiano asli.',
    category: 'Western Food',
    filterKey: 'western pasta',
    author: 'Sarah Michaels',
    authorAvatar: IMAGES.sarahMichaelsAvatar,
    verified: true,
    likes: '890',
    likesCount: 890,
    recooks: '890 recook',
    time: '25 Menit',
    servings: '2 Porsi',
    difficulty: 'Mudah',
    image: IMAGES.trufflePastaExplore,
    isFavorite: true,
    publishedAgo: '4 hari lalu',
    ingredients: [
      { id: '1', name: 'Pasta Tagliatelle / Fettuccine', amount: '220 gram' },
      { id: '2', name: 'Heavy Cream, Jamur Champignon & Truffle Paste', amount: '200 ml krim + 1 sdm truffle' },
      { id: '3', name: 'Keju Parmesan Parut & Bawang Putih', amount: '50 gram' },
    ],
    steps: [
      {
        id: '1',
        title: 'Merebus Pasta Al Dente',
        description: 'Rebus pasta dalam air mendidih bergaram hingga 1 menit sebelum waktu kemasan. Simpan 100 ml air rebusan pasta.',
      },
      {
        id: '2',
        title: 'Emulsi Saus Krim Truffle',
        description: 'Tumis jamur dan bawang putih dengan mentega, tuang heavy cream dan pasta truffle. Masukkan pasta, keju parmesan, dan air pasta hingga creamy.',
      },
    ],
  },
  {
    id: 'ayam-bakar-madu-pedas',
    code: '#RSP-3044',
    title: 'Ayam Bakar Madu Pedas',
    description: 'Ayam panggang bumbu rempah Nusantara dengan olesan madu hutan dan cabai merah yang terkaramelisasi sempurna.',
    category: 'Asian Food',
    filterKey: 'asian',
    author: 'Budi Santoso',
    authorAvatar: IMAGES.budiSantosoAvatar,
    verified: true,
    likes: '2.4k',
    likesCount: 2400,
    recooks: '2.4k recook',
    time: '40 Menit',
    servings: '4 Porsi',
    difficulty: 'Menengah',
    image: IMAGES.ayamBakarExplore,
    isFavorite: false,
    publishedAgo: '3 hari lalu',
    ingredients: [
      { id: '1', name: 'Paha & Dada Ayam Negeri Utuh', amount: '800 gram (4 potong)' },
      { id: '2', name: 'Madu Murni, Kecap Manis & Saus Cabai', amount: '4 sdm madu + 3 sdm kecap' },
      { id: '3', name: 'Bumbu Halus (Bawang, Kemiri, Ketumbar, Cabai)', amount: '150 gram' },
    ],
    steps: [
      {
        id: '1',
        title: 'Ungkep Ayam Bumbu Rempah',
        description: 'Tumis bumbu halus, daun salam, dan lengkuas. Masukkan ayam dan air kelapa, ungkep hingga bumbu meresap dan kuah menyusut.',
      },
      {
        id: '2',
        title: 'Bakar dengan Olesan Madu Pedas',
        description: 'Panggang ayam di atas grill pan sambil diolesi campuran sisa bumbu ungkep, madu, dan mentega hingga berkilau kecokelatan.',
      },
    ],
  },
  {
    id: 'salmon-mentai-rice-bowl',
    code: '#RSP-3050',
    title: 'Salmon Mentai Rice Bowl',
    description: 'Perpaduan salmon panggang juicy dengan saus mentai gurih-creamy yang ditorch hingga wangi smoky menggugah selera.',
    category: 'Asian Fusion',
    filterKey: 'asian',
    author: 'Chef Kenji',
    authorAvatar: IMAGES.chefKenjiAvatar,
    verified: true,
    likes: '3.1k',
    likesCount: 3100,
    recooks: '1.9k recook',
    time: '30 Menit',
    servings: '2-3 Porsi',
    difficulty: 'Sedang',
    image: IMAGES.salmonMentaiFav,
    secondaryImages: [IMAGES.salmonMentaiSub1, IMAGES.salmonMentaiSub2],
    isFavorite: true,
    publishedAgo: '1 hari lalu',
    ingredients: [
      { id: '1', name: 'Beras Jepang / Japonica Rice', amount: '300 gram' },
      { id: '2', name: 'Fillet Ikan Salmon Segar', amount: '200 gram (potong dadu)' },
      { id: '3', name: 'Mayones Jepang (Kewpie) & Tobiko', amount: '4 sdm mayo + 2 sdm tobiko' },
    ],
    steps: [
      {
        id: '1',
        title: 'Menyiapkan Nasi & Racikan Salmon',
        description: 'Masak nasi Jepang hingga pulen hangat, campurkan dengan taburan furikake dan minyak wijen. Marinasi potongan salmon dengan kecap asin Jepang & saus tiram selama 10 menit.',
      },
      {
        id: '2',
        title: 'Perakitan & Blow Torch Mentai',
        description: 'Tata nasi dalam mangkuk tahan panas, susun salmon di atasnya, lapisi dengan saus mentai tebal. Gunakan kitchen blow torch hingga permukaan saus berkaramel kecokelatan dan wangi smoky.',
      },
    ],
  },
  {
    id: 'homemade-pepperoni-pizza',
    code: '#RSP-3051',
    title: 'Homemade Pepperoni Pizza',
    description: 'Adonan tanpa ragi instan dengan fermentasi 24 jam, saus tomat San Marzano, lelehan mozzarella segar, dan pepperoni renyah.',
    category: 'Western',
    filterKey: 'western',
    author: 'Adam Malik',
    authorAvatar: IMAGES.userAndi,
    verified: false,
    likes: '950',
    likesCount: 950,
    recooks: '410 recook',
    time: '35 Menit',
    servings: '3-4 Porsi',
    difficulty: 'Mudah',
    image: IMAGES.pepperoniPizzaFav,
    isFavorite: true,
    isMyRecipe: true,
    publishedAgo: '5 hari lalu',
    ingredients: [
      { id: '1', name: 'Tepung Protein Tinggi & Air Hangat', amount: '300 gram tepung + 190 ml air' },
      { id: '2', name: 'Keju Mozzarella Segar & Beef Pepperoni', amount: '180 gram keju + 80g pepperoni' },
      { id: '3', name: 'Saus Tomat Pizza, Oregano & Daun Basil', amount: '5 sdm' },
    ],
    steps: [
      {
        id: '1',
        title: 'Membentuk Adonan Pizza',
        description: 'Pipihkan adonan yang sudah difermentasi menggunakan ujung jari dari tengah ke tepi agar pinggiran tetap berongga dan renyah.',
      },
      {
        id: '2',
        title: 'Topping & Panggang Suhu Tinggi',
        description: 'Oleskan saus tomat, taburi keju mozzarella, dan susun pepperoni. Panggang dalam oven suhu 250°C selama 10–12 menit hingga keju berbuih keemasan.',
      },
    ],
  },
  {
    id: 'dimsum-ayam-udang',
    code: '#RSP-3043',
    title: 'Dimsum Ayam Udang',
    description: 'Siomay dimsum ayam dan udang cincang kenyal dengan taburan wortel parut serta saus cabai bawang putih asam manis.',
    category: 'Asian Food',
    filterKey: 'asian',
    author: 'Jennie Lee',
    authorAvatar: IMAGES.userDewi,
    verified: false,
    likes: '950',
    likesCount: 950,
    recooks: '730 recook',
    time: '35 Menit',
    servings: '16 Buah',
    difficulty: 'Mudah',
    image: IMAGES.dimsumHome,
    isFavorite: false,
    publishedAgo: '4 hari lalu',
    reportedCount: 3,
    ingredients: [
      { id: '1', name: 'Daging Paha Ayam Giling & Udang Kupas Cincang', amount: '300g ayam + 150g udang' },
      { id: '2', name: 'Kulit Dimsum / Pangsit Bulat Tipis', amount: '16 lembar' },
      { id: '3', name: 'Tepung Tapioka, Minyak Wijen & Saus Tiram', amount: '3 sdm tapioka + 2 sdm saus' },
    ],
    steps: [
      {
        id: '1',
        title: 'Mencampur Adonan Isian Kenyal',
        description: 'Aduk rata ayam giling, udang cincang, bawang putih, putih telur, saus tiram, minyak wijen, dan tepung tapioka satu arah hingga lengket.',
      },
      {
        id: '2',
        title: 'Membungkus & Mengukus Dimsum',
        description: 'Isi tiap lembar kulit dimsum, lipat tepinya sambil dirapatkan, beri parutan wortel di atasnya. Kukus selama 20 menit di kukusan yang sudah dioles minyak.',
      },
    ],
  },
  {
    id: 'spaghetti-carbonara',
    code: '#RSP-3042',
    title: 'Spaghetti Carbonara',
    description: 'Resep otentik Romawi menggunakan emulsi kuning telur segar, keju Pecorino Romano, smoked beef crispy, dan lada hitam tumbuk.',
    category: 'Western Food',
    filterKey: 'western pasta',
    author: 'Hannah Brown',
    authorAvatar: IMAGES.sarahMichaelsAvatar,
    verified: true,
    likes: '1.4k',
    likesCount: 1400,
    recooks: '810 recook',
    time: '20 Menit',
    servings: '2 Porsi',
    difficulty: 'Mudah',
    image: IMAGES.carbonaraHome,
    isFavorite: false,
    publishedAgo: 'Kemarin',
    ingredients: [
      { id: '1', name: 'Spaghetti Bronze-Die', amount: '200 gram' },
      { id: '2', name: 'Kuning Telur Ayam Kampung & Keju Pecorino', amount: '3 kuning telur + 60g keju' },
      { id: '3', name: 'Smoked Beef / Guanciale & Lada Hitam Kasar', amount: '100 gram' },
    ],
    steps: [
      {
        id: '1',
        title: 'Menumis Daging Asap & Kocokan Telur',
        description: 'Masak potongan smoked beef tanpa minyak hingga garing. Di mangkuk terpisah, kocok kuning telur dengan keju Pecorino dan lada hitam.',
      },
      {
        id: '2',
        title: 'Mencampur Pasta Tanpa Api',
        description: 'Matikan api kompor, masukkan spaghetti hangat ke wajan, lalu tuang campuran telur keju sambil diaduk cepat dengan sedikit air rebusan pasta hingga membentuk saus silky.',
      },
    ],
  },
  {
    id: 'matcha-pancake',
    code: '#RSP-3045',
    title: 'Matcha Pancake',
    description: 'Souffle pancake Jepang super lembut dan mengembang tinggi dengan taburan bubuk matcha Uji organik serta krim segar.',
    category: 'Dessert',
    filterKey: 'dessert',
    author: 'Kenji Sato',
    authorAvatar: IMAGES.chefKenjiAvatar,
    verified: false,
    likes: '1.9k',
    likesCount: 1900,
    recooks: '520 recook',
    time: '30 Menit',
    servings: '2 Porsi',
    difficulty: 'Menengah',
    image: IMAGES.matchaPancakeHome,
    isFavorite: false,
    publishedAgo: '4 hari lalu',
    ingredients: [
      { id: '1', name: 'Telur Ayam Segar (Pisahkan Kuning & Putih)', amount: '2 butir besar' },
      { id: '2', name: 'Tepung Terigu Protein Rendah & Bubuk Matcha Uji', amount: '35g tepung + 1 sdm matcha' },
      { id: '3', name: 'Susu Cair Full Cream & Gula Kastor', amount: '25 ml susu + 30g gula' },
    ],
    steps: [
      {
        id: '1',
        title: 'Membuat Meringue Kaku Mengkilap',
        description: 'Kocok putih telur dingin sambil masukkan gula bertahap hingga mencapai stiff peak. Lipat perlahan ke dalam adonan kuning telur dan matcha.',
      },
      {
        id: '2',
        title: 'Memanggang Teknik Kukus Pan',
        description: 'Sendokkan adonan tinggi di atas teflon anti lengket api sangat kecil, beri 1 sdm air di pinggir pan, tutup selama 4 menit per sisi hingga matang fluffy.',
      },
    ],
  },
];

export const INITIAL_ADMIN_USERS: AdminUser[] = [
  {
    id: '1',
    code: '#USR-1021',
    name: 'Sarah Michaels',
    email: 'sarah.m@gmail.com',
    avatar: IMAGES.userSarah,
    status: 'Aktif',
    role: 'Kreator',
    registeredDate: '12 Mei 2024',
  },
  {
    id: '2',
    code: '#USR-1045',
    name: 'Budi Santoso',
    email: 'budi.s@outlook.com',
    avatar: IMAGES.userBudi,
    status: 'Aktif',
    role: 'Kreator',
    registeredDate: '18 Mei 2024',
  },
  {
    id: '3',
    code: '#USR-1090',
    name: 'Chef Kenji',
    email: 'kenji.food@kitchen.id',
    avatar: IMAGES.userKenji,
    status: 'Aktif',
    role: 'Kreator',
    registeredDate: '01 Jun 2024',
  },
  {
    id: '4',
    code: '#USR-1132',
    name: 'Rian Pratama',
    email: 'rian99@spam.xyz',
    avatar: IMAGES.userRian,
    status: 'Ditangguhkan',
    role: 'Pengguna',
    registeredDate: '15 Jun 2024',
  },
  {
    id: '5',
    code: '#USR-1188',
    name: 'Dewi Lestari',
    email: 'dewi.lestari@gmail.com',
    avatar: IMAGES.userDewi,
    status: 'Baru',
    role: 'Kreator',
    registeredDate: '20 Jun 2024',
  },
  {
    id: '6',
    code: '#ADM-0042',
    name: 'Andi Wijaya',
    email: 'andi.w@kuliner.id',
    avatar: IMAGES.userAndi,
    status: 'Aktif',
    role: 'Admin',
    registeredDate: '05 Jan 2024',
  },
  {
    id: '7',
    code: '#USR-1250',
    name: 'Maya Putri',
    email: 'maya.putri@foodie.com',
    avatar: IMAGES.userMaya,
    status: 'Aktif',
    role: 'Kreator',
    registeredDate: '22 Jun 2024',
  },
];
