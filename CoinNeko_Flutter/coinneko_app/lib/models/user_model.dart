// frontend/lib/models/user_model.dart
class UserModel {
  final int id;
  final String username;
  final String email;
  final int coins;
  final int gachaTickets;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.coins,
    required this.gachaTickets,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        coins: json['coins'] as int,
        gachaTickets: json['gacha_tickets'] as int,
      );

  UserModel copyWith({int? coins, int? gachaTickets}) => UserModel(
        id: id,
        username: username,
        email: email,
        coins: coins ?? this.coins,
        gachaTickets: gachaTickets ?? this.gachaTickets,
      );
}

class CatSpecies {
  final int id;
  final String name;
  final String jobTitle;
  final String rarity;
  final String emoji;
  final String description;
  final String? imageUrl;

  CatSpecies({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.rarity,
    required this.emoji,
    required this.description,
    this.imageUrl,
  });

  factory CatSpecies.fromJson(Map<String, dynamic> json) => CatSpecies(
        id: json['id'] as int,
        name: json['name'] as String,
        jobTitle: json['job_title'] as String,
        rarity: json['rarity'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
      );
}

class UserCat {
  final int id;
  final int catSpeciesId;
  final String name;
  final String jobTitle;
  final String rarity;
  final String emoji;
  final String description;
  final int starLevel;
  final String? imageUrl;

  UserCat({
    required this.id,
    required this.catSpeciesId,
    required this.name,
    required this.jobTitle,
    required this.rarity,
    required this.emoji,
    required this.description,
    required this.starLevel,
    this.imageUrl,
  });

  factory UserCat.fromJson(Map<String, dynamic> json) => UserCat(
        id: json['id'] as int,
        catSpeciesId: json['cat_species_id'] as int,
        name: json['name'] as String,
        jobTitle: json['job_title'] as String,
        rarity: json['rarity'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String? ?? '',
        starLevel: json['star_level'] as int,
        imageUrl: json['image_url'] as String?,
      );
}

class Category {
  final int id;
  final String name;
  final String icon;
  final String type; // 'income' | 'expense'

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String,
        type: json['type'] as String,
      );
}

class Transaction {
  final int id;
  final int category;
  final String catName;
  final String catIcon;
  final String catType;
  final double amount;
  final String note;
  final DateTime transactedAt;

  Transaction({
    required this.id,
    required this.category,
    required this.catName,
    required this.catIcon,
    required this.catType,
    required this.amount,
    required this.note,
    required this.transactedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        category: json['category'] as int,
        catName: json['cat_name'] as String,
        catIcon: json['cat_icon'] as String,
        catType: json['cat_type'] as String,
        amount: double.parse(json['amount'].toString()),
        note: json['note'] as String? ?? '',
        transactedAt: DateTime.parse(json['transacted_at'] as String),
      );
}

class GachaPullResult {
  final CatSpecies cat;
  final bool isDuplicate;
  final bool starUp;
  final int coinsBonus;
  final int newStarLevel;
  final UserModel user;

  GachaPullResult({
    required this.cat,
    required this.isDuplicate,
    required this.starUp,
    required this.coinsBonus,
    required this.newStarLevel,
    required this.user,
  });

  factory GachaPullResult.fromJson(Map<String, dynamic> json) => GachaPullResult(
        cat: CatSpecies.fromJson(json['cat'] as Map<String, dynamic>),
        isDuplicate: json['is_duplicate'] as bool,
        starUp: json['star_up'] as bool? ?? false,
        coinsBonus: json['coins_bonus'] as int? ?? 0,
        newStarLevel: json['new_star_level'] as int? ?? 1,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}