class Ingredient {
  final String id;
  final String name;
  final String amount;

  Ingredient({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory Ingredient.fromDb(Map<String, dynamic> row) {
    return Ingredient(
      id: row['id'].toString(),
      name: (row['name'] ?? '') as String,
      amount: (row['amount'] ?? '') as String,
    );
  }

  Ingredient copyWith({String? id, String? name, String? amount}) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}

class CookingStep {
  final String id;
  final String title;
  final String description;

  CookingStep({
    required this.id,
    required this.title,
    required this.description,
  });

  factory CookingStep.fromDb(Map<String, dynamic> row) {
    return CookingStep(
      id: row['id'].toString(),
      title: (row['title'] ?? '') as String,
      description: (row['description'] ?? '') as String,
    );
  }

  CookingStep copyWith({String? id, String? title, String? description}) {
    return CookingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

class Recipe {
  final String id;
  final String code;
  final String title;
  final String description;
  final String category;
  final String filterKey;
  final String author;
  final String? authorAvatar;
  final bool verified;
  final String likes;
  final int likesCount;
  final String? recooks;
  final String time;
  final String servings;
  final String difficulty;
  final String image;
  final List<String>? secondaryImages;
  bool isFavorite;
  final bool isMyRecipe;
  final String publishedAgo;
  final int? reportedCount;
  final List<Ingredient> ingredients;
  final List<CookingStep> steps;

  Recipe({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.filterKey,
    required this.author,
    this.authorAvatar,
    this.verified = false,
    required this.likes,
    required this.likesCount,
    this.recooks,
    required this.time,
    required this.servings,
    required this.difficulty,
    required this.image,
    this.secondaryImages,
    this.isFavorite = false,
    this.isMyRecipe = false,
    required this.publishedAgo,
    this.reportedCount,
    required this.ingredients,
    required this.steps,
  });

  /// Bangun objek Recipe dari baris JSON API (tabel MySQL `recipes`
  /// yang sudah di-join dengan `users`).
  factory Recipe.fromDb(
    Map<String, dynamic> row, {
    bool isFavorite = false,
    int? currentUserId,
    List<Ingredient>? ingredients,
    List<CookingStep>? steps,
  }) {
    final authorId = (row['user_id'] ?? 0) as int;
    return Recipe(
      id: row['id'].toString(),
      code: (row['code'] ?? '') as String,
      title: (row['title'] ?? '') as String,
      description: (row['description'] ?? '') as String,
      category: (row['category'] ?? '') as String,
      filterKey: ((row['category'] ?? '') as String).toLowerCase(),
      author: (row['author_name'] ?? 'Anonim') as String,
      authorAvatar: row['author_avatar'] as String?,
      verified: false,
      likes: '${row['likes_count'] ?? 0}',
      likesCount: (row['likes_count'] ?? 0) as int,
      recooks: '${row['recooks_count'] ?? 0}',
      time: (row['cook_time'] ?? '-') as String,
      servings: (row['servings'] ?? '-') as String,
      difficulty: (row['difficulty'] ?? 'Mudah') as String,
      image: (row['image'] ?? '') as String,
      isFavorite: isFavorite,
      isMyRecipe: currentUserId != null && authorId == currentUserId,
      publishedAgo: Recipe._formatAgo(row['created_at']),
      ingredients: ingredients ?? [],
      steps: steps ?? [],
    );
  }

  static String _formatAgo(dynamic createdAt) {
    if (createdAt == null) return 'Baru saja';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return 'Baru saja';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }

  Recipe copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? category,
    String? filterKey,
    String? author,
    String? authorAvatar,
    bool? verified,
    String? likes,
    int? likesCount,
    String? recooks,
    String? time,
    String? servings,
    String? difficulty,
    String? image,
    List<String>? secondaryImages,
    bool? isFavorite,
    bool? isMyRecipe,
    String? publishedAgo,
    int? reportedCount,
    List<Ingredient>? ingredients,
    List<CookingStep>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      filterKey: filterKey ?? this.filterKey,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      verified: verified ?? this.verified,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      recooks: recooks ?? this.recooks,
      time: time ?? this.time,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      image: image ?? this.image,
      secondaryImages: secondaryImages ?? this.secondaryImages,
      isFavorite: isFavorite ?? this.isFavorite,
      isMyRecipe: isMyRecipe ?? this.isMyRecipe,
      publishedAgo: publishedAgo ?? this.publishedAgo,
      reportedCount: reportedCount ?? this.reportedCount,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }
}

class AdminUser {
  final String id;
  final String code;
  final String name;
  final String email;
  final String avatar;
  String status; // 'Aktif', 'Ditangguhkan', 'Baru'
  final String role; // 'Kreator', 'Pengguna', 'Admin'
  final String registeredDate;

  AdminUser({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.avatar,
    required this.status,
    required this.role,
    required this.registeredDate,
  });
}

class MockImages {
  static const String salmonMentaiHero =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCsyxX9au8BFpgZhR4rgWp4tHecw3sg5MTlCxbdehxw-PGh0rnyvPqCeA9E-kTvTO0SE_UX5tESBYd-lArrkYB-9AKmKvqVoyJxg0XyG-mYsR-y32BHiIZLcEI9KGDvpIlGH0PS9PGCdui_MJWnIjlsny4ZUUl5onE05347YNwQ-LkoVVRF99ElvPaQ-h-wR2JZW5wlaPACCKJehBXEk0VmTEhR-W-XVhV1A7qZ2rQJOYwFTJeoGy6u';
  static const String salmonMentaiSub1 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCwOfjbamWJXhU5rlvki9dYHGYbukNUxeGta4X8qx0atIh1qieOeDNFJ5y3ytOl20e8dG-yNxgrylxMb1ijQgjQ5FgIXT702VROfoM5KUt-WOlDqICKd76ji2YFby9Yeg_zykAMKZOVUDQtUErdilsacLjQDQ_cgQqBxZmI_SnsLxoX2Gpz7DSkM0GH0nZd8--nsFGSexhjZnarGgqQyaiLb9wgGyrMrLOWTJ83nHpHcH6RBvmd7D3I';
  static const String salmonMentaiSub2 =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDfdWlk42e8zw6Cj56Px_OjJntwQw_zqv7TSfvG88_V8Dnqc3wvVvNza-C-SPR_KT71bQxP1wwMzvqPeBzbFhUrb8hiAGUpOtCP2DdYOyZHcRYAKsa6FaYWE5EQAY111RoisMunqMIqZgjVG9ViCQT7aETOi1NHRakQ_52lBFAiq7qt9gluGMm0cO4uvd4oCrEAjTcBG1kNml8YnPVDGC3dK0QwQXYvnV5ZpFXaCAi5KzyBLTisSxle';

  static const String nasiLemakHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAAgLPrG6tuPvLMVtDaOfodJIRf2CWNJb-VYdUnbZylAd_u37FZcDeJ0R2oDouJN_O2N51dzFcAQyFD6SXbLrFRItDRnydfU_giqnWNit0KCkwHbDkKbNOYLvFN-EM2L7geNivQDod_GeQZcnhcYY7oYwnyX2qzGYeyutC44rCidHXwFvmwVwSWmHu3A2iAlkDhPG4ukP2MmWBuoayIcJQcjYK3BRn4keWQiWY_n5fTZdxIMYd6rmF9';
  static const String chickenMentaiHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCI_FVvtmJrchVMexVYO4ealDg7snrV91aRNH_EA42t4fA_DzWbeGIuDja_1_Oo-Pr6brC9ackfbu_LfSda_P4eUGaC94eXQv08Jc080YamOsYr0F1v6h_wnnGAlH-HQl-yl5ERmFkmV87hKToHPZLr0uulX1tLWK4yg5SeGSGUBYNYDzAq7fSf6X_R8pUyVV1ph13UssGg8canJYbkIxsutipDwLHMpjyC5TPIan0k83SfNxkq00nT';
  static const String salmonPokeHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDly8qn7IdY5TIm6tHh9arAOtX11ljQUNioHfNwakWeGQnoHdDO9THEnZPNMLcAdFOzbmhhnIamEy6dgWu8pRYtTX8desUnI9Sy_Nt94aPoHeFEqfXqDfIgvc7ZvIQy42ETBI3_KDh3B8mN1egUAr1Zo-O0LWGau7j8B_8yzP6axsaQ95qq6y5f0Jlt8aYovS7uD5_El_yaUhS3Qs0uyIHlHImhrfXuXcYRjVsp1Asyr5OXaGGG-iX1';
  static const String pizzaHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAElSWJHStzTTsurQl1KDcEVLAs-zZAEv3ZCzNxAO9HUHNlUHQ3j7BAD8YWH_46Ug3i_LLEv3Nox2FFqEUXefcV4jtNPvECbYFbkM-I022t2b8DNiPeBTo2rLTRF_5AhlQtPbzPoqbTFUFUvXnbLd8Gxpb2kLNrzxEJT3Ya0JnrgRQrrmIBhsNYQGfGedF7S3Y9gGvtyRqi1rvxadOq_a8GpreKOcEKp7gUnxGIkLEZEvzctYDTdjil';
  static const String dimsumHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBsJb8LUnULuZHgMgQUuSam1HnQ-kbvkQuxuIiSvhEtcjevuC8jhw_JNFlL_wxcXybPNb7hbH6swFrCQVPBA_JdTZJpRNXduWJ8gZjj5Em4iPckXf-K5HT59JAi_YqX0LR8lw0sZjC-kN_ir5ZXLzvoMqvmH7T2y64QLxYSwu_RDbIEqx2OqmpwJ_23wE-1bUXvE7EHVDDE_pzEvyBgcqv8O2NpHWIzHWjp9AdBKN9aXlvG9bBvrNlx';
  static const String carbonaraHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDO9EqGQdFzQLBU4LlDTacZnbKFgpDUyQB1BwKqCrPv1GM64owmcq1tF37-ZNNZXDXoBWuiVjMVY3QoonNRuU2iZL3J-zqLILZxJiYxv8SRSKqG5jdDeofGK62CeCuDJiiOzf0QXDQRuwOfTQErbSjIvJhHo1vYUdZU7b7FTTjC-9mADXthj1nETIQwK1TrRKhMVumx9DHlfrZFTHc21MdINyv-RkkJz1bsiCXDXQhMEcDOiiY5N-bn';
  static const String matchaPancakeHome =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC00THvajHXixCim-fKKMmWMubuFbDv8uI6YmGgo4UdHXixplCsqraALZnJM9GDJIDjwEOAIkVaRT6GXPRHOCY_fNWYpZzCONzj6vKSwHMLCTD5yHkbOMp06wW6bEtXplru1N3cyMbF5hFORPm6ubtoVu_Mb28NNqk5lBAo_NGUa2sIGwce1gWBMe3K3_Pgvn0kqc5ycE3wPxns4nLuG_vgodbBt2GQHSUR53ufzjOtepTK74V_Eaqg';

  static const String westernBanner =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCob_q4kXZhFg9S6elWZTi8p4n1QP2m1O2Frfc4XUIg0txOOimO-vw4omAwnKMRMtuUGZjP4THniNsZLNr-_NOTWm_u7bRmZk3rn00Q4S8Vqm-tkgNTGUiCFZZq7NVP_ss9zwTwNM7ebokOA5EwORIauOZanh1r2PB4U9ou646zA3P-PMapg43c3KXa_t0oUHoo0FbN9gjKXJFxZRtZfGKQ2rmxLzQbJiPP9M2Nxm4N9z43iPXDg8GB';
  static const String nusantaraBanner =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD_CipZITJviI1dXu2Mxw-uAzP7hCID-hlFqOEg51KFi9vHtK1ylzW2wAcyC_EbszXJwNGImZ064_BlzYPT3oLunmRCqXPHYav5Yf8PrehqKmNNYtrNE8OVfFtR4o0zkjk8NqltGV3P1zVHnunwVH2i0I2rBs47AK2TIbxYeMriyQFfZhCyId_PnAx9cObxd8rlHfJT_yQMT_efaBHEh_8wSdq1IsTQqRa0DK8ueH670n0rAtS7-YpS';
  static const String beefCurryExplore =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBmZOR7RoMDyiwyzKWAau4Rgvg5MzKNoH9ceRPCcCnnwOBoZ7Z6Wr-gybl5-XjhuSHe6MkiGRwklpTzLq6uItpRrP4ZvxuUVIxekW5s4pjCdCoRRiMzKxApbmWlJLrLhCq1OGw1GSeY0xkq3GA-SvlXZgTaE7d5FMbGEngGJ4QDhFJsfBi7lg0LZqkDIanZFP5c4y1SPqVKAyjFm4xiRMhdiJJUX90WQazqpjsFrG0znIWUTcKIwWJ6';
  static const String trufflePastaExplore =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCpgiCvEG6XyhTltGKI7Hd40vyYLOZ__SHdNh2k0qMKRT5udtl9o61r2yj1anlowbMWBJkc4PGkFeZc0nzQESMXBsblXs0L8wCWZwKyPvQLvcG_hxXRn-OEqTgy2VgG9PvAG6z5QMcMSnwulNXZgnOpuD9KjHSadO4BQm-V4QwTWmWgzd3ArszmYlLk-ZIjI_Ig1e4JEaJkkX966UKHQlMYzaxwCi9_hbi0zGyTUI4enDSk4nDbeCD9';
  static const String ayamBakarExplore =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFfRt-lRVitfPfDiGbkfyhhmfpB2WIz0I7_fNzIhzUxzSunjkuZQ70K_yBRZZhJDcqCrsRyRvZ6A2zjb7r1a0_vWjRuvk4V5bjEVQ9dSWLwmt4Oulk_ngl20Y03sDxMHIXels4HniG5MDGalbay-wO2G-5RvEzz_CikICyc3FqZb1RAzgjr8eJqXbfF__c_GVIIJifBBtAH04EiWpbwUyXi527odzatx78DUs7B7ZIO8Oo7t3Pu0W';

  static const String annaRobertsAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB_Oin1mlZCrGQ5vqr5IAf1dMxVWDVngwtzggYh5Or0YTPqR4PEQ9WaMqjcB6eRW0XX2Vz8ycbpmRyEUMOU5nIYdepZ-RSaXCFL_r_q7Ivi6tPN_3SrFAPIOoiiA4EzllP2aRWoJEPZnbZ7Z4CN7bY9Chk3mVtkAL76X5vziO4jb0jmvAzDcF1IwzBj9IAAhrUh5nVUTK5bODN2G5diOCbX8946_IKQrBdsQhevIKSbQZqXvRTAF1eo';
  static const String chefKenjiAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBhf5jD8VWCep9qYNPWI69bf0kF3PArbpXz10v2uIktMPTUF9hDIzShJ__vzlTURKooWJvsMeOHdVQc7UyzzbEKiUmOJETVVvnzi3wMD9iykNdmg2vZXkOKBJ6ylG_fYZM-TTmv7EhCLJ6LjZY9DYgnGzddhkl-bEqFTajDzGS9ETZecDllYxGhN5oaQMUTYbfSeyYcj2_0Tkv6OrzVZ8EuDFaAHe1L0XJtEv3O-lqMi-_EQFgHF8dJ';
  static const String sarahMichaelsAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB-WtPWGGbCHhQVTXhCgwqevoqJXM95oXwNDTElVg73dNTuMADvbpSSENw2_1KgfraYbeFI_ilqHZ7G1xNg1WwftM-fwEiMkGXCGCp2jFKmTaXSYWUCWcGZoAap5-nr-YO4aUEEYrEHypswDQp3MLH_IMPYGszmBb5zJXoQueP547SmEjuasAZu99xQlViTk1yXo1KY8cx-t0YSi0egjyr6AalWwqtz93GphvTRdsJE4ma4MMbtfhT0';
  static const String budiSantosoAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDJMUFEO5W4D9fa2yovcByIBKe9AR13VSzg4tEZbWNWge7XkycD9WCmwvM3bMW0tVP2xNDwubUYzYtYX_h3WoTCdO-C_DheBbNdXS4z_5JUNOGJE5agV-alqnMVVVxg5LkQiXjZA47txn_cZRHqCZzLftUjflsSet6tSoZz0DbCW-OnlPEdS7QhZkkmoSrykBOBY6L_NFFAAOSQeojG7NU2_4GtT6tE2xyC6wQS48sCemt2TEuCa2-I';
  static const String adminHeadChef =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDRy4p1WnJ-YSJrnjcGAQSDN-Mio_sNR6pNH_BC_5rkuC4Ha2Nr24QZp-XnSYafWrWUl23YgpisSffJnDC-1JKy0hOhb0V9XX36rK0nvgVcqTgaEFlR9ZoWIH46lGmrfNZFUe8P2Gygdff6H4wqsae8-e8sYKzn2o40Utws5xpz1V3tkymDs7aBE31Y_fTJqgh0Ls7qNKG8tA0rOBKr9ZXZbAdP7C4A_EDw3WXZizRS9RWf40zQkIZT';
}

class MockData {
  static List<Recipe> getInitialRecipes() {
    return [
      Recipe(
        id: 'nasi-lemak',
        code: '#RSP-3041',
        title: 'Nasi Lemak',
        description:
            'Nasi gurih santan pandan disajikan dengan sambal bilis merah pedas manis, kacang tanah sangrai, telur rebus, dan irisan timun segar.',
        category: 'Asian Food',
        filterKey: 'asian',
        author: 'Sarah Michaels',
        authorAvatar: MockImages.sarahMichaelsAvatar,
        verified: true,
        likes: '1.5k',
        likesCount: 1500,
        recooks: '920 recook',
        time: '40 Menit',
        servings: '3-4 Porsi',
        difficulty: 'Sedang',
        image: MockImages.nasiLemakHome,
        isFavorite: true,
        isMyRecipe: true,
        publishedAgo: '2 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Beras Bulir Panjang & Santan Kental', amount: '350g beras + 200ml santan'),
          Ingredient(id: '2', name: 'Ikan Bilis / Teri Medan & Kacang Tanah', amount: '100 gram'),
          Ingredient(id: '3', name: 'Daun Pandan, Serai & Jahe Geprek', amount: '3 lbr pandan + 2 serai'),
          Ingredient(id: '4', name: 'Sambal Tumis Bawang & Cabai Kering', amount: '150 gram'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Menanak Nasi Santan Pandan',
            description:
                'Cuci bersih beras, masukkan ke rice cooker bersama santan, air, daun pandan simpul, serai, dan sedikit garam hingga matang harum.',
          ),
          CookingStep(
            id: '2',
            title: 'Menumis Sambal & Pelengkap',
            description:
                'Tumis bumbu halus cabai kering dan bawang merah hingga pecah minyak, bumbui gula aren dan asam jawa. Sajikan dengan ikan bilis goreng dan telur rebus.',
          ),
        ],
      ),
      Recipe(
        id: 'chicken-mentai-rice',
        code: '#RSP-3040',
        title: 'Chicken Mentai Rice',
        description:
            'Saus mentai gurih manis smoky dengan taburan nori dan potongan ayam karage renyah di atas nasi hangat.',
        category: 'Asian Food',
        filterKey: 'asian',
        author: 'Teo Kim',
        authorAvatar: MockImages.chefKenjiAvatar,
        verified: true,
        likes: '2.1k',
        likesCount: 2100,
        recooks: '1.4k recook',
        time: '30 Menit',
        servings: '2 Porsi',
        difficulty: 'Mudah',
        image: MockImages.chickenMentaiHome,
        isFavorite: false,
        isMyRecipe: true,
        publishedAgo: '1 minggu lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Nasi Jepang Hangat & Nori Bubuk', amount: '300 gram'),
          Ingredient(id: '2', name: 'Paha Ayam Fillet (Marinasi Soy Sauce)', amount: '250 gram'),
          Ingredient(id: '3', name: 'Mayones Jepang, Tobiko & Saus Sambal', amount: '5 sdm mayo + 2 sdm tobiko'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Memasak Ayam & Nasi Nori',
            description:
                'Panggang paha ayam marinasi hingga kecokelatan dan potong dadu. Aduk nasi hangat dengan minyak wijen dan furikake.',
          ),
          CookingStep(
            id: '2',
            title: 'Melapisi Saus Mentai & Torch',
            description:
                'Tuang saus mentai di atas susunan nasi dan ayam, lalu bakar permukaannya menggunakan blow torch hingga wangi smoky.',
          ),
        ],
      ),
      Recipe(
        id: 'salmon-poke',
        code: '#RSP-3039',
        title: 'Salmon Poke',
        description:
            'Semangkuk kesegaran salmon sashimi pilihan dengan saus ponzu wijen, alpukat matang, edamame, dan acar jahe.',
        category: 'Japanese',
        filterKey: 'asian healthy',
        author: 'Maya Lin',
        authorAvatar: MockImages.chefKenjiAvatar,
        verified: false,
        likes: '1.8k',
        likesCount: 1800,
        recooks: '640 recook',
        time: '20 Menit',
        servings: '2 Porsi',
        difficulty: 'Mudah',
        image: MockImages.salmonPokeHome,
        isFavorite: false,
        publishedAgo: '3 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Salmon Sashimi Grade (Potong Dadu)', amount: '200 gram'),
          Ingredient(id: '2', name: 'Alpukat Mentega, Edamame & Wakame', amount: '1 buah alpukat + 50g edamame'),
          Ingredient(id: '3', name: 'Saus Shoyu, Minyak Wijen & Biji Wijen', amount: '3 sdm'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Marinasi Salmon Segar',
            description:
                'Campurkan potongan salmon dengan shoyu, minyak wijen, dan perasan jeruk nipis. Diamkan 10 menit.',
          ),
          CookingStep(
            id: '2',
            title: 'Penyusunan Poke Bowl',
            description:
                'Tata sushi rice di mangkuk, susun salmon, irisan alpukat, edamame, dan taburi biji wijen sangrai.',
          ),
        ],
      ),
      Recipe(
        id: 'japanese-beef-curry',
        code: '#RSP-3046',
        title: 'Japanese Beef Curry',
        description:
            'Kari daging sapi khas Jepang dengan kuah kental gurih manis dari karamelisasi bawang bombay, kentang, dan wortel lembut.',
        category: 'Asian Food',
        filterKey: 'asian',
        author: 'Chef Kenji',
        authorAvatar: MockImages.chefKenjiAvatar,
        verified: true,
        likes: '1.2k',
        likesCount: 1200,
        recooks: '1.2k recook',
        time: '45 Menit',
        servings: '4 Porsi',
        difficulty: 'Menengah',
        image: MockImages.beefCurryExplore,
        isFavorite: true,
        publishedAgo: '5 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Daging Sapi Sengkel / Chuck (Potong Dadu)', amount: '400 gram'),
          Ingredient(id: '2', name: 'Blok Roux Kari Jepang & Kentang', amount: '100g roux + 2 kentang'),
          Ingredient(id: '3', name: 'Bawang Bombay Karamel & Apel Parut', amount: '2 bombay + 1/2 apel'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Menumis Bombay & Sapi',
            description: 'Tumis bawang bombay hingga harum kecokelatan, masukkan daging sapi, rebus hingga empuk.',
          ),
          CookingStep(
            id: '2',
            title: 'Memasukkan Blok Kari',
            description: 'Masukkan wortel dan kentang lunak, larutkan blok kari Jepang, masak hingga mengental harum.',
          ),
        ],
      ),
      Recipe(
        id: 'creamy-truffle-pasta',
        code: '#RSP-3048',
        title: 'Creamy Truffle Pasta',
        description:
            'Tagliatelle al dente berbalut saus krim jamur truffle hitam harum dengan taburan keju Parmigiano-Reggiano asli.',
        category: 'Western Food',
        filterKey: 'western pasta',
        author: 'Sarah Michaels',
        authorAvatar: MockImages.sarahMichaelsAvatar,
        verified: true,
        likes: '890',
        likesCount: 890,
        recooks: '890 recook',
        time: '25 Menit',
        servings: '2 Porsi',
        difficulty: 'Mudah',
        image: MockImages.trufflePastaExplore,
        isFavorite: true,
        publishedAgo: '4 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Pasta Tagliatelle / Fettuccine', amount: '220 gram'),
          Ingredient(id: '2', name: 'Heavy Cream, Jamur Champignon & Truffle', amount: '200ml krim + 1 sdm truffle'),
          Ingredient(id: '3', name: 'Keju Parmesan Parut & Bawang Putih', amount: '50 gram'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Rebus Pasta Al Dente',
            description: 'Rebus pasta dalam air mendidih bergaram. Sisihkan 100 ml air pasta.',
          ),
          CookingStep(
            id: '2',
            title: 'Saus Krim Truffle',
            description: 'Tumis jamur dengan butter dan bawang putih, tuang cream dan truffle paste, aduk rata bersama pasta.',
          ),
        ],
      ),
      Recipe(
        id: 'ayam-bakar-madu-pedas',
        code: '#RSP-3044',
        title: 'Ayam Bakar Madu Pedas',
        description:
            'Ayam panggang bumbu rempah Nusantara dengan olesan madu hutan dan cabai merah yang terkaramelisasi sempurna.',
        category: 'Asian Food',
        filterKey: 'asian',
        author: 'Budi Santoso',
        authorAvatar: MockImages.budiSantosoAvatar,
        verified: true,
        likes: '2.4k',
        likesCount: 2400,
        recooks: '2.4k recook',
        time: '40 Menit',
        servings: '4 Porsi',
        difficulty: 'Menengah',
        image: MockImages.ayamBakarExplore,
        isFavorite: false,
        publishedAgo: '3 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Paha & Dada Ayam Negeri', amount: '800 gram (4 potong)'),
          Ingredient(id: '2', name: 'Madu Murni, Kecap Manis & Sambal', amount: '4 sdm madu + 3 sdm kecap'),
          Ingredient(id: '3', name: 'Bumbu Halus (Bawang, Kemiri, Cabai)', amount: '150 gram'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Ungkep Ayam Bumbu Rempah',
            description: 'Tumis bumbu halus, masukkan ayam dan air kelapa, ungkep hingga bumbu meresap dan matang.',
          ),
          CookingStep(
            id: '2',
            title: 'Bakar Olesan Madu',
            description: 'Panggang ayam sambil diolesi racikan madu dan mentega hingga berkilau harum kecokelatan.',
          ),
        ],
      ),
      Recipe(
        id: 'salmon-mentai-rice-bowl',
        code: '#RSP-3050',
        title: 'Salmon Mentai Rice Bowl',
        description:
            'Perpaduan salmon panggang juicy dengan saus mentai gurih-creamy yang ditorch hingga wangi smoky menggugah selera.',
        category: 'Asian Fusion',
        filterKey: 'asian',
        author: 'Chef Kenji',
        authorAvatar: MockImages.chefKenjiAvatar,
        verified: true,
        likes: '3.1k',
        likesCount: 3100,
        recooks: '1.9k recook',
        time: '30 Menit',
        servings: '2-3 Porsi',
        difficulty: 'Sedang',
        image: MockImages.salmonMentaiHero,
        secondaryImages: [MockImages.salmonMentaiSub1, MockImages.salmonMentaiSub2],
        isFavorite: true,
        publishedAgo: '1 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Beras Jepang / Japonica Rice', amount: '300 gram'),
          Ingredient(id: '2', name: 'Fillet Ikan Salmon Segar', amount: '200 gram (potong dadu)'),
          Ingredient(id: '3', name: 'Mayones Kewpie & Tobiko', amount: '4 sdm mayo + 2 sdm tobiko'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Persiapan Nasi & Salmon',
            description: 'Aduk nasi pulen hangat dengan furikake dan minyak wijen. Marinasi salmon dengan soy sauce.',
          ),
          CookingStep(
            id: '2',
            title: 'Torch Saus Mentai',
            description: 'Tata salmon di atas nasi, lapisi saus mentai tebal, torch hingga smoky kecokelatan.',
          ),
        ],
      ),
      Recipe(
        id: 'homemade-pepperoni-pizza',
        code: '#RSP-3051',
        title: 'Homemade Pepperoni Pizza',
        description:
            'Adonan fermentasi 24 jam dengan saus tomat San Marzano, lelehan mozzarella segar, dan pepperoni renyah.',
        category: 'Western',
        filterKey: 'western',
        author: 'Adam Malik',
        authorAvatar: MockImages.budiSantosoAvatar,
        verified: false,
        likes: '950',
        likesCount: 950,
        recooks: '410 recook',
        time: '35 Menit',
        servings: '3-4 Porsi',
        difficulty: 'Mudah',
        image: MockImages.pizzaHome,
        isFavorite: true,
        isMyRecipe: true,
        publishedAgo: '5 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Tepung Protein Tinggi & Air Hangat', amount: '300g tepung + 190ml air'),
          Ingredient(id: '2', name: 'Mozzarella & Beef Pepperoni', amount: '180g keju + 80g pepperoni'),
          Ingredient(id: '3', name: 'Saus Tomat San Marzano & Basil', amount: '5 sdm saus'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Membentuk Adonan Pizza',
            description: 'Pipihkan adonan menggunakan jari dari tengah ke tepi agar pinggiran renyah berongga.',
          ),
          CookingStep(
            id: '2',
            title: 'Topping & Panggang Oven',
            description: 'Oles saus tomat, tabur keju dan pepperoni. Panggang suhu 250°C selama 10-12 menit.',
          ),
        ],
      ),
      Recipe(
        id: 'dimsum-ayam-udang',
        code: '#RSP-3043',
        title: 'Dimsum Ayam Udang',
        description:
            'Siomay dimsum ayam dan udang cincang kenyal dengan taburan wortel parut serta saus asam manis pedas.',
        category: 'Asian Food',
        filterKey: 'asian',
        author: 'Jennie Lee',
        authorAvatar: MockImages.sarahMichaelsAvatar,
        verified: false,
        likes: '950',
        likesCount: 950,
        recooks: '730 recook',
        time: '35 Menit',
        servings: '16 Buah',
        difficulty: 'Mudah',
        image: MockImages.dimsumHome,
        isFavorite: false,
        publishedAgo: '4 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Daging Paha Ayam Giling & Udang', amount: '300g ayam + 150g udang'),
          Ingredient(id: '2', name: 'Kulit Dimsum Tipis', amount: '16 lembar'),
          Ingredient(id: '3', name: 'Tapioka, Minyak Wijen & Saus Tiram', amount: '3 sdm tapioka + 2 sdm bumbu'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Mencampur Adonan Isian',
            description: 'Aduk rata ayam, udang, bawang putih, minyak wijen, putih telur, dan tapioka hingga kalis lengket.',
          ),
          CookingStep(
            id: '2',
            title: 'Membungkus & Mengukus',
            description: 'Isi kulit dimsum, lipat bergelombang, beri wortel parut di atasnya. Kukus 20 menit.',
          ),
        ],
      ),
      Recipe(
        id: 'spaghetti-carbonara',
        code: '#RSP-3042',
        title: 'Spaghetti Carbonara',
        description:
            'Resep otentik Romawi menggunakan emulsi kuning telur segar, keju Pecorino Romano, smoked beef, dan lada hitam.',
        category: 'Western Food',
        filterKey: 'western pasta',
        author: 'Hannah Brown',
        authorAvatar: MockImages.sarahMichaelsAvatar,
        verified: true,
        likes: '1.4k',
        likesCount: 1400,
        recooks: '810 recook',
        time: '20 Menit',
        servings: '2 Porsi',
        difficulty: 'Mudah',
        image: MockImages.carbonaraHome,
        isFavorite: false,
        publishedAgo: 'Kemarin',
        ingredients: [
          Ingredient(id: '1', name: 'Spaghetti Bronze-Die', amount: '200 gram'),
          Ingredient(id: '2', name: 'Kuning Telur & Keju Pecorino Romano', amount: '3 kuning telur + 60g keju'),
          Ingredient(id: '3', name: 'Smoked Beef / Guanciale & Lada Hitam', amount: '100 gram'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Goreng Crispy Daging Asap',
            description: 'Goreng smoked beef tanpa minyak hingga crispy. Kocok telur dan keju di mangkuk.',
          ),
          CookingStep(
            id: '2',
            title: 'Emulsi Carbonara Tanpa Api',
            description: 'Matikan kompor wajan, masukkan pasta hangat, tuang kocokan telur keju sambil diaduk cepat.',
          ),
        ],
      ),
      Recipe(
        id: 'matcha-pancake',
        code: '#RSP-3045',
        title: 'Matcha Souffle Pancake',
        description:
            'Souffle pancake Jepang super lembut dan mengembang tinggi dengan taburan bubuk matcha Uji organik serta sirup maple.',
        category: 'Dessert',
        filterKey: 'dessert',
        author: 'Kenji Sato',
        authorAvatar: MockImages.chefKenjiAvatar,
        verified: false,
        likes: '1.9k',
        likesCount: 1900,
        recooks: '520 recook',
        time: '30 Menit',
        servings: '2 Porsi',
        difficulty: 'Menengah',
        image: MockImages.matchaPancakeHome,
        isFavorite: false,
        publishedAgo: '4 hari lalu',
        ingredients: [
          Ingredient(id: '1', name: 'Telur Ayam Segar (Pisah Kuning & Putih)', amount: '2 butir besar'),
          Ingredient(id: '2', name: 'Tepung Terigu & Matcha Uji Organik', amount: '35g tepung + 1 sdm matcha'),
          Ingredient(id: '3', name: 'Susu Cair Full Cream & Gula Pasir', amount: '25ml susu + 30g gula'),
        ],
        steps: [
          CookingStep(
            id: '1',
            title: 'Kocok Meringue Stiff Peak',
            description: 'Kocok putih telur dan gula hingga kaku mengkilap. Lipat lembut ke adonan matcha.',
          ),
          CookingStep(
            id: '2',
            title: 'Panggang Pan Tutup',
            description: 'Sendokkan adonan tinggi di wajan anti-lengket api kecil, tutup 4 menit per sisi hingga matang fluffy.',
          ),
        ],
      ),
    ];
  }

  static List<AdminUser> getInitialUsers() {
    return [
      AdminUser(
        id: '1',
        code: '#USR-1021',
        name: 'Sarah Michaels',
        email: 'sarah.m@gmail.com',
        avatar: MockImages.sarahMichaelsAvatar,
        status: 'Aktif',
        role: 'Kreator',
        registeredDate: '12 Mei 2024',
      ),
      AdminUser(
        id: '2',
        code: '#USR-1045',
        name: 'Budi Santoso',
        email: 'budi.s@outlook.com',
        avatar: MockImages.budiSantosoAvatar,
        status: 'Aktif',
        role: 'Kreator',
        registeredDate: '18 Mei 2024',
      ),
      AdminUser(
        id: '3',
        code: '#USR-1090',
        name: 'Chef Kenji',
        email: 'kenji.food@kitchen.id',
        avatar: MockImages.chefKenjiAvatar,
        status: 'Aktif',
        role: 'Kreator',
        registeredDate: '01 Jun 2024',
      ),
      AdminUser(
        id: '4',
        code: '#USR-1132',
        name: 'Rian Pratama',
        email: 'rian99@spam.xyz',
        avatar: MockImages.budiSantosoAvatar,
        status: 'Ditangguhkan',
        role: 'Pengguna',
        registeredDate: '15 Jun 2024',
      ),
      AdminUser(
        id: '5',
        code: '#USR-1188',
        name: 'Dewi Lestari',
        email: 'dewi.lestari@gmail.com',
        avatar: MockImages.sarahMichaelsAvatar,
        status: 'Baru',
        role: 'Kreator',
        registeredDate: '20 Jun 2024',
      ),
      AdminUser(
        id: '6',
        code: '#ADM-0042',
        name: 'Andi Wijaya',
        email: 'andi.w@kuliner.id',
        avatar: MockImages.adminHeadChef,
        status: 'Aktif',
        role: 'Admin',
        registeredDate: '05 Jan 2024',
      ),
    ];
  }
}
