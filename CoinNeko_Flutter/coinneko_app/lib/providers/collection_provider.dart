// frontend/lib/providers/collection_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CollectionProvider extends ChangeNotifier {
  final ApiService apiService;

  CollectionProvider(this.apiService);

  List<CatSpecies> _species = [];
  List<UserCat> _userCats = [];
  Set<int> _ownedIds = {};
  Map<int, UserCat> _ownedMap = {};
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  List<CatSpecies> get species => _species;
  List<UserCat> get userCats => _userCats;
  Set<int> get ownedIds => _ownedIds;
  Map<int, UserCat> get ownedMap => _ownedMap;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;
  int get ownedCount => _ownedIds.length;
  int get totalCount => _species.length;

  Future<void> load({bool silent = false}) async {
    // 避免重複載入
    if (_loading) return;

    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final speciesList = await apiService.getCatSpecies();
      final collection = await apiService.getCollection();

      _species = speciesList;
      _ownedIds = collection.map((c) => c.catSpeciesId).toSet();
      _ownedMap = {for (var c in collection) c.catSpeciesId: c};
      _userCats = collection;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('CollectionProvider.load error: $e');
    } finally {
      // ★ 不管成功或失敗，initialized 都設成 true，避免永遠轉圈
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  /// 抽卡後直接更新本地狀態，不需要重新 fetch
  void applyGachaResult({
    required int catSpeciesId,
    required bool isDuplicate,
    required int newStarLevel,
  }) {
    if (isDuplicate) {
      final existingCat = _ownedMap[catSpeciesId];
      if (existingCat != null) {
        final updated = UserCat(
          id: existingCat.id,
          catSpeciesId: existingCat.catSpeciesId,
          name: existingCat.name,
          jobTitle: existingCat.jobTitle,
          rarity: existingCat.rarity,
          emoji: existingCat.emoji,
          description: existingCat.description,
          starLevel: newStarLevel,
        );
        _ownedMap[catSpeciesId] = updated;
        final idx =
            _userCats.indexWhere((c) => c.catSpeciesId == catSpeciesId);
        if (idx != -1) _userCats[idx] = updated;
      }
    } else {
      _ownedIds.add(catSpeciesId);
      final speciesData = _species.firstWhere(
        (s) => s.id == catSpeciesId,
        orElse: () => CatSpecies(
          id: catSpeciesId,
          name: '',
          jobTitle: '',
          rarity: 'common',
          emoji: '🐱',
          description: '',
        ),
      );
      final newUserCat = UserCat(
        id: 0,
        catSpeciesId: catSpeciesId,
        name: speciesData.name,
        jobTitle: speciesData.jobTitle,
        rarity: speciesData.rarity,
        emoji: speciesData.emoji,
        description: speciesData.description,
        starLevel: 1,
      );
      _ownedMap[catSpeciesId] = newUserCat;
      _userCats.add(newUserCat);
    }

    notifyListeners();
  }
}