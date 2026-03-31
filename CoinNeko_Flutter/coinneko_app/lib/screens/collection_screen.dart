// frontend/lib/screens/collection_screen.dart
import 'dart:ui';
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

// ──────────────────────────────────────────────
// ★ 圖鑑卡片
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

  void _showDetailModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black60,
      builder: (ctx) => _CatDetailDialog(species: species, userCat: userCat!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLocked ? null : () => _showDetailModal(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            child: isLocked ? _buildLocked() : _buildUnlocked(),
          ),
        ),
      ),
    );
  }

  // ── 已解鎖：大圖滿版 + 漸層文字 ──
  Widget _buildUnlocked() {
    final hasImage = species.imageUrl != null && species.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：貓咪大圖
        hasImage
            ? Image.network(
                species.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _EmojiBackground(emoji: species.emoji, rarity: species.rarity),
              )
            : _EmojiBackground(emoji: species.emoji, rarity: species.rarity),

        // 中層：底部漸層遮罩
        const Positioned(
          left: 0, right: 0, bottom: 0,
          child: SizedBox(
            height: 90,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),

        // 頂左：稀有度標籤
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: RarityHelper.bgColor(species.rarity),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              RarityHelper.label(species.rarity),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: RarityHelper.textColor(species.rarity),
              ),
            ),
          ),
        ),

        // 底層文字：名稱 + 星星
        Positioned(
          left: 8, right: 8, bottom: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                species.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 3),
              if (userCat != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => Icon(
                    i < userCat!.starLevel ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 12,
                    color: i < userCat!.starLevel ? AppColors.gold : Colors.white38,
                  )),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 未解鎖：灰階 + 高斯模糊 + 暗化 + 問號 ──
  Widget _buildLocked() {
    final hasImage = species.imageUrl != null && species.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：黑白去色
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: hasImage
              ? Image.network(
                  species.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF333333)),
                )
              : _EmojiBackground(emoji: species.emoji, rarity: 'common'),
        ),

        // 高斯模糊疊在上
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: const SizedBox(),
          ),
        ),

        // 暗化遮罩
        Container(color: Colors.black.withOpacity(0.40)),

        // 問號 + 文字
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '?',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
              SizedBox(height: 2),
              Text(
                '尚未獲得',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 沒有圖片時的彩色 emoji 背景
class _EmojiBackground extends StatelessWidget {
  final String? emoji;
  final String rarity;
  const _EmojiBackground({this.emoji, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: RarityHelper.cardGradient(rarity),
        ),
      ),
      child: Center(
        child: Text(emoji ?? '🐱', style: const TextStyle(fontSize: 64)),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ★ 圖鑑詳細資訊 Modal（大圖版）
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
    final hasImage = s.imageUrl != null && s.imageUrl!.isNotEmpty;
    final glowColor = _rarityGlow(rarity);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 英雄圖片區（滿版，無內距）──
                    Stack(
                      children: [
                        // 大圖
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: hasImage
                              ? Image.network(
                                  s.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _EmojiBackground(emoji: s.emoji, rarity: rarity),
                                )
                              : _EmojiBackground(emoji: s.emoji, rarity: rarity),
                        ),

                        // 底部漸層遮罩
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(
                            height: 120,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF1C1C2E), Color(0x001C1C2E)],
                              ),
                            ),
                          ),
                        ),

                        // 右上：稀有度標籤
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: RarityHelper.bgColor(rarity),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: glowColor.withOpacity(0.5), blurRadius: 8),
                              ],
                            ),
                            child: Text(
                              RarityHelper.label(rarity),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: RarityHelper.textColor(rarity),
                              ),
                            ),
                          ),
                        ),

                        // 圖片底部：名稱疊在漸層上
                        Positioned(
                          left: 16, right: 16, bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.jobTitle,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Nunito',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── 資訊區（圖片下方）──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        children: [
                          // 星等
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) => Icon(
                              i < uc.starLevel ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 24,
                              color: i < uc.starLevel ? AppColors.gold : Colors.white24,
                            )),
                          ),

                          if (s.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Text(
                                s.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.65,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // 關閉按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: glowColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '關閉',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }

  Color _rarityGlow(String rarity) {
    switch (rarity) {
      case 'legendary': return const Color(0xFFFFD700);
      case 'epic':      return const Color(0xFFB44FE8);
      case 'rare':      return const Color(0xFF4F9EE8);
      default:          return const Color(0xFF78C17A);
    }
  }
}