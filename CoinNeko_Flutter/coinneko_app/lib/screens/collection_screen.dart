// frontend/lib/screens/collection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/collection_provider.dart';
import '../models/user_model.dart';
import '../widgets/cat_avatar.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
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
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 230, // ★ 從 200 改 230，給星星足夠空間
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

class _CatCard extends StatelessWidget {
  final CatSpecies species;
  final UserCat? userCat;
  final bool isLocked;

  const _CatCard({
    required this.species,
    required this.userCat,
    required this.isLocked,
  });

  void _showDetailModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _CatDetailDialog(species: species, userCat: userCat!),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 未獲得：黑白剪影 + 半透明，心癢癢效果
    if (isLocked) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(AppRadius.catCard),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.catCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 黑白去色貓咪圖（若有圖）
              if (species.imageUrl != null && species.imageUrl!.isNotEmpty)
                Opacity(
                  opacity: 0.18,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                    child: Image.network(
                      species.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                )
              else
                Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      species.emoji ?? '🐱',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              // 問號疊在上面
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '?',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                    Text(
                      '尚未獲得',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 已獲得：可點擊，跳出詳細視窗
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetailModal(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: RarityHelper.cardGradient(species.rarity),
            ),
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CatAvatar(
                    imageUrl: species.imageUrl,
                    emoji: species.emoji,
                    size: 72,
                  ),
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
                  const SizedBox(height: 4),
                  if (userCat != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < userCat!.starLevel ? Icons.star : Icons.star_border,
                          size: 14,
                          color: i < userCat!.starLevel
                              ? AppColors.gold
                              : AppColors.border,
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ★ 圖鑑詳細資訊 Modal
// ──────────────────────────────────────────────
class _CatDetailDialog extends StatefulWidget {
  final CatSpecies species;
  final UserCat userCat;

  const _CatDetailDialog({required this.species, required this.userCat});

  @override
  State<_CatDetailDialog> createState() => _CatDetailDialogState();
}

class _CatDetailDialogState extends State<_CatDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.species;
    final uc = widget.userCat;
    final rarity = s.rarity;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: RarityHelper.cardGradient(rarity),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 頂部稀有度色條
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: RarityHelper.textColor(rarity).withOpacity(0.15),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: RarityHelper.bgColor(rarity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        RarityHelper.label(rarity),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RarityHelper.textColor(rarity),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    children: [
                      // 貓咪大圖
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: RarityHelper.textColor(rarity)
                                  .withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            final imgSize =
                                (screenWidth < 400 ? screenWidth * 0.5 : 180.0)
                                    .clamp(140.0, 200.0);
                            return SizedBox(
                              width: imgSize,
                              height: imgSize,
                              child: s.imageUrl != null &&
                                      s.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        s.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            s.emoji ?? '🐱',
                                            style: TextStyle(
                                                fontSize: imgSize * 0.55),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        s.emoji ?? '🐱',
                                        style: TextStyle(
                                            fontSize: imgSize * 0.55),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 名字
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // 職稱
                      Text(
                        s.jobTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 星等
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Icon(
                            i < uc.starLevel ? Icons.star : Icons.star_border,
                            size: 22,
                            color: i < uc.starLevel
                                ? AppColors.gold
                                : AppColors.border,
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      // 分隔線
                      Container(
                          height: 1,
                          color: Colors.black.withOpacity(0.06)),
                      const SizedBox(height: 14),

                      // 描述
                      if (s.description.isNotEmpty)
                        Text(
                          s.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSub,
                            height: 1.6,
                          ),
                        ),
                      const SizedBox(height: 18),

                      // 關閉按鈕
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                RarityHelper.textColor(rarity),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '關閉',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}