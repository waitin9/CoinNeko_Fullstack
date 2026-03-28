// frontend/lib/screens/collection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/collection_provider.dart';
import '../models/user_model.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
    // ★ 用 Future.microtask 取代 addPostFrameCallback
    // 確保 Provider 樹已建立完成再觸發載入
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<CollectionProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();

    // ── 載入中（且尚未初始化）──
    if (!provider.initialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.purple),
            const SizedBox(height: 12),
            Text(
              '載入圖鑑中...',
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // ── 錯誤狀態 ──
    if (provider.error != null && provider.species.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '載入失敗，請下拉重試',
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: const TextStyle(color: AppColors.red, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.load(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple),
              child: const Text('重新載入',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final owned = provider.ownedCount;
    final total = provider.totalCount;

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () => provider.load(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('貓咪圖鑑', style: AppTextStyles.heading2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '已收集 $owned / $total',
                      style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final s = provider.species[i];
                  final userCat = provider.ownedMap[s.id];
                  final isLocked = !provider.ownedIds.contains(s.id);
                  return _CatCard(
                    species: s,
                    userCat: userCat,
                    isLocked: isLocked,
                  );
                },
                childCount: provider.species.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// _CatCard
// ──────────────────────────────────────────────

class _CatCard extends StatelessWidget {
  final CatSpecies species;
  final UserCat? userCat;
  final bool isLocked;

  const _CatCard({
    required this.species,
    required this.userCat,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isLocked ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? AppColors.card : null,
          gradient: !isLocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: RarityHelper.cardGradient(species.rarity),
                )
              : null,
          borderRadius: BorderRadius.circular(AppRadius.catCard),
          boxShadow: AppShadows.card,
        ),
        child: ColorFiltered(
          colorFilter: isLocked
              ? const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ])
              : const ColorFilter.mode(
                  Colors.transparent, BlendMode.color),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(species.emoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 6),
                Text(
                  species.name,
                  style: AppTextStyles.catName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  species.jobTitle,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSub),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: RarityHelper.bgColor(species.rarity),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    RarityHelper.label(species.rarity),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: RarityHelper.textColor(species.rarity)),
                  ),
                ),
                if (userCat != null) ...[
                  const SizedBox(height: 4),
                  _buildStars(userCat!.starLevel),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text('未獲得',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSub)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStars(int level) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Text(
          i < level ? '★' : '☆',
          style: TextStyle(
            fontSize: 11,
            color: i < level ? AppColors.gold : AppColors.border,
          ),
        );
      }),
    );
  }
}