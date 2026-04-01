// frontend/lib/screens/collection_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/collection_provider.dart';
import '../models/user_model.dart';

class CollectionScreen extends StatefulWidget {
  final String? highlightCatId;

  const CollectionScreen({super.key, this.highlightCatId});

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

    // 若帶有 highlightCatId，畫面渲染完後自動打開該貓咪詳細頁
    if (widget.highlightCatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryAutoOpenCat(widget.highlightCatId!);
      });
    }
  }

  /// 等資料載入完後自動打開指定貓咪的詳細視窗
  Future<void> _tryAutoOpenCat(String catId) async {
    // 最多等 3 秒讓資料載入
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      final provider = context.read<CollectionProvider>();
      if (!provider.initialized) continue;

      final species = provider.species.where((s) => s.id == catId).firstOrNull;
      final userCat = provider.ownedMap[catId];
      if (species != null && userCat != null) {
        _showCatDetailById(species, userCat);
        return;
      }
    }
  }

  void _showCatDetailById(CatSpecies species, UserCat userCat) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => _CatDetailDialog(species: species, userCat: userCat),
    );
  }

  // 從 Navigator route arguments 取得 highlightCatId（pushNamed 方式）
  String? _getRouteHighlightId() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['highlightCatId'] is String) {
      return args['highlightCatId'] as String;
    }
    return widget.highlightCatId;
  }

  bool _routeAutoOpenDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeAutoOpenDone) {
      final id = _getRouteHighlightId();
      if (id != null && id != widget.highlightCatId) {
        // 只處理 route 傳入的（widget 傳入的已在 initState 處理）
        _routeAutoOpenDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryAutoOpenCat(id);
        });
      } else if (id != null) {
        _routeAutoOpenDone = true;
      }
    }
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
            Text('載入圖鑑中...',
                style: TextStyle(color: AppColors.textSub, fontSize: 13)),
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
            Text('載入失敗，請下拉重試',
                style: TextStyle(color: AppColors.textSub, fontSize: 14)),
            const SizedBox(height: 8),
            Text(provider.error!,
                style: const TextStyle(color: AppColors.red, fontSize: 11),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.load(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
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
                    child: Text('已收集 $owned / $total',
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
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
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 220,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final s = provider.species[i];
                  final userCat = provider.ownedMap[s.id];
                  final isLocked = !provider.ownedIds.contains(s.id);
                  return _CatCard(
                      species: s, userCat: userCat, isLocked: isLocked);
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

// ══════════════════════════════════════════════════════════
// ★  圖鑑卡片（滿版大圖 + 漸層文字）
// ══════════════════════════════════════════════════════════
class _CatCard extends StatelessWidget {
  final CatSpecies species;
  final UserCat? userCat;
  final bool isLocked;

  const _CatCard(
      {required this.species, required this.userCat, required this.isLocked});

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => _CatDetailDialog(species: species, userCat: userCat!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLocked ? null : () => _showDetail(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.catCard),
            child: isLocked ? _lockedCard() : _unlockedCard(),
          ),
        ),
      ),
    );
  }

  // ── 已解鎖：圖片滿版 + 底部漸層文字 ──
  Widget _unlockedCard() {
    final hasImg = species.imageUrl != null && species.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層大圖
        hasImg
            ? Image.network(species.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _CardBackground(emoji: species.emoji, rarity: species.rarity))
            : _CardBackground(emoji: species.emoji, rarity: species.rarity),

        // 底部漸層遮罩
        const Positioned(
          left: 0, right: 0, bottom: 0,
          child: SizedBox(
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xD9000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),

        // 左上：稀有度標籤
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: RarityHelper.bgColor(species.rarity),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(RarityHelper.label(species.rarity),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: RarityHelper.textColor(species.rarity))),
          ),
        ),

        // 底部：名稱 + 星星
        Positioned(
          left: 8, right: 8, bottom: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(species.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  )),
              const SizedBox(height: 3),
              if (userCat != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < userCat!.starLevel
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 12,
                      color: i < userCat!.starLevel
                          ? AppColors.gold
                          : Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 未解鎖：黑白 + 模糊 + 暗化 + 問號 ──
  Widget _lockedCard() {
    final hasImg = species.imageUrl != null && species.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 黑白去色
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: hasImg
              ? Image.network(species.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF444444)))
              : _CardBackground(emoji: species.emoji, rarity: 'common'),
        ),

        // 2. 高斯模糊（BackdropFilter 套在前一層上面）
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
            child: const SizedBox.expand(),
          ),
        ),

        // 3. 暗化遮罩
        Container(color: Colors.black.withValues(alpha: 0.42)),

        // 4. 問號 + 文字
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('?',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Colors.white54,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  )),
              SizedBox(height: 2),
              Text('尚未獲得',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// 無圖片時的彩色漸層背景
class _CardBackground extends StatelessWidget {
  final String? emoji;
  final String rarity;
  const _CardBackground({this.emoji, required this.rarity});

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
          child: Text(emoji ?? '🐱', style: const TextStyle(fontSize: 60))),
    );
  }
}

// ══════════════════════════════════════════════════════════
// ★  圖鑑詳細 Modal（深色大圖版）
// ══════════════════════════════════════════════════════════
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
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scale = CurvedAnimation(
        parent: _ctrl, curve: const Cubic(0.175, 0.885, 0.32, 1.275));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _glow {
    switch (widget.species.rarity) {
      case 'legendary': return const Color(0xFFFFD700);
      case 'epic':      return const Color(0xFFB44FE8);
      case 'rare':      return const Color(0xFF4A90E8);
      default:          return const Color(0xFF6BCB77);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s      = widget.species;
    final uc     = widget.userCat;
    final rarity = s.rarity;
    final hasImg = s.imageUrl != null && s.imageUrl!.isNotEmpty;

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: ScaleTransition(
          scale: _scale,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141422),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _glow.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 大圖區（無內距，滿版）──
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: hasImg
                              ? Image.network(s.imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _CardBackground(emoji: s.emoji, rarity: rarity))
                              : _CardBackground(emoji: s.emoji, rarity: rarity),
                        ),

                        // 底部漸層，讓文字疊在圖上
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(
                            height: 130,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF141422), Color(0x00141422)],
                              ),
                            ),
                          ),
                        ),

                        // 右上：稀有度
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: RarityHelper.bgColor(rarity),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: _glow.withValues(alpha: 0.5),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Text(RarityHelper.label(rarity),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: RarityHelper.textColor(rarity))),
                          ),
                        ),

                        // 底部文字疊在圖上
                        Positioned(
                          left: 16, right: 16, bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.jobTitle,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 2),
                              Text(s.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Nunito',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 6)
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── 資訊區 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Column(
                        children: [
                          // 星等
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) => Icon(
                              i < uc.starLevel
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 24,
                              color: i < uc.starLevel
                                  ? AppColors.gold
                                  : Colors.white24,
                            )),
                          ),

                          // 描述
                          if (s.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(s.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    height: 1.65,
                                  )),
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
                                backgroundColor: _glow,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('關閉',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Colors.white,
                                  )),
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
}