// frontend/lib/screens/gacha_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/collection_provider.dart';
import '../models/user_model.dart';
import '../widgets/cat_avatar.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with TickerProviderStateMixin {
  bool _isPullingTicket = false;
  bool _isPullingCoins = false;
  String? _error;

  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pull({required bool useCoins}) async {
    if (useCoins && _isPullingCoins) return;
    if (!useCoins && _isPullingTicket) return;

    setState(() {
      _error = null;
      if (useCoins) {
        _isPullingCoins = true;
      } else {
        _isPullingTicket = true;
      }
    });

    try {
      final api = context.read<ApiService>();
      final result = await api.gachaPull(useCoins: useCoins);

      context.read<AuthService>().updateUser(result.user);
      context.read<CollectionProvider>().applyGachaResult(
            catSpeciesId: result.cat.id,
            isDuplicate: result.isDuplicate,
            newStarLevel: result.newStarLevel,
          );

      // ★ 抽完後跳出 Modal
      if (mounted) {
        _showResultModal(result);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '網路錯誤，請稍後再試');
    } finally {
      setState(() {
        _isPullingCoins = false;
        _isPullingTicket = false;
      });
    }
  }

  void _showResultModal(GachaPullResult result) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _GachaResultDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user!;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildGachaMachine(),
                const SizedBox(height: 8),
                _buildResourceRow(user),
                const SizedBox(height: 24),
                _buildButtons(user),
                const SizedBox(height: 8),
                if (_error != null) _buildErrorBanner(),
                const SizedBox(height: 24),
                _buildOddsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          '扭蛋機',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '抽卡召喚你的財務貓咪夥伴',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
      ],
    );
  }

  Widget _buildGachaMachine() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: const Text('🎰', style: TextStyle(fontSize: 96)),
    );
  }

  Widget _buildResourceRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ResourceChip(
          emoji: '🎟️',
          label: '${user.gachaTickets} 扭蛋券',
          color: AppColors.purple,
          bgColor: AppColors.purpleLight,
        ),
        const SizedBox(width: 12),
        _ResourceChip(
          emoji: '🪙',
          label: '${user.coins} 金幣',
          color: AppColors.gold,
          bgColor: AppColors.goldLight,
        ),
      ],
    );
  }

  Widget _buildButtons(UserModel user) {
    final isBusy = _isPullingTicket || _isPullingCoins;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _GachaButton(
          label: '🎟️ 使用扭蛋券',
          subtitle: '剩餘 ${user.gachaTickets} 張',
          color: AppColors.purple,
          enabled: !isBusy && user.gachaTickets > 0,
          isLoading: _isPullingTicket,
          onPressed: () => _pull(useCoins: false),
        ),
        _GachaButton(
          label: '🪙 使用 50 金幣',
          subtitle: '剩餘 ${user.coins} 枚',
          color: AppColors.gold,
          enabled: !isBusy && user.coins >= 50,
          isLoading: _isPullingCoins,
          onPressed: () => _pull(useCoins: true),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '❌ $_error',
        style: const TextStyle(
            color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildOddsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('抽卡機率', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _OddsRow(rarity: 'common', pct: '65%')),
            Expanded(child: _OddsRow(rarity: 'rare', pct: '25%')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _OddsRow(rarity: 'epic', pct: '8%')),
            Expanded(child: _OddsRow(rarity: 'legendary', pct: '2%')),
          ]),
          const SizedBox(height: 14),
          const Text(
            '💡 重複獲得的貓咪會自動升星（上限 5 星），滿星後轉換為金幣',
            style: TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ★ 抽卡結果 Modal
// ──────────────────────────────────────────────
class _GachaResultDialog extends StatefulWidget {
  final GachaPullResult result;

  const _GachaResultDialog({required this.result});

  @override
  State<_GachaResultDialog> createState() => _GachaResultDialogState();
}

class _GachaResultDialogState extends State<_GachaResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
    final cat = widget.result.cat;
    final rarity = cat.rarity;
    final isDupe = widget.result.isDuplicate;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
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
                // ── 頂部稀有度顏色條 ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: RarityHelper.textColor(rarity).withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  child: Center(
                    child: _RarityBadge(rarity: rarity, large: true),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      // ── 貓咪圖片（大圖，自適應螢幕）──
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
                            // 根據螢幕寬度自動決定圖片大小，手機/電腦都好看
                            final screenWidth = MediaQuery.of(context).size.width;
                            final imgSize = (screenWidth < 400
                                    ? screenWidth * 0.55
                                    : 220.0)
                                .clamp(160.0, 260.0);
                            return SizedBox(
                              width: imgSize,
                              height: imgSize,
                              child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        cat.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            cat.emoji ?? '🐱',
                                            style: TextStyle(fontSize: imgSize * 0.55),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        cat.emoji ?? '🐱',
                                        style: TextStyle(fontSize: imgSize * 0.55),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 貓咪名字 ──
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // ── 職稱 ──
                      Text(
                        cat.jobTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 分隔線 ──
                      Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.06),
                      ),
                      const SizedBox(height: 16),

                      // ── 描述 ──
                      Text(
                        cat.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 結果訊息（新貓 or 重複）──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDupe
                              ? AppColors.goldLight
                              : AppColors.greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDupe
                              ? (widget.result.starUp
                                  ? '✨ 重複！升至 ${widget.result.newStarLevel} 星 +${widget.result.coinsBonus} 🪙'
                                  : '✨ 已達 5 星上限！換取 ${widget.result.coinsBonus} 🪙')
                              : '🎉 新貓咪加入圖鑑！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDupe ? AppColors.gold : AppColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 關閉按鈕 ──
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RarityHelper.textColor(rarity),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '繼續抽！',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
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

// ──────────────────────────────────────────────
// 子元件
// ──────────────────────────────────────────────

class _ResourceChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bgColor;

  const _ResourceChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _GachaButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GachaButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? color : color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final String rarity;
  final bool large;

  const _RarityBadge({required this.rarity, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 8,
        vertical: large ? 5 : 2,
      ),
      decoration: BoxDecoration(
        color: RarityHelper.bgColor(rarity),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        RarityHelper.label(rarity),
        style: TextStyle(
          fontSize: large ? 13 : 10,
          fontWeight: FontWeight.w700,
          color: RarityHelper.textColor(rarity),
        ),
      ),
    );
  }
}

class _OddsRow extends StatelessWidget {
  final String rarity;
  final String pct;

  const _OddsRow({required this.rarity, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RarityBadge(rarity: rarity),
        const SizedBox(width: 8),
        Text(pct,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.text)),
      ],
    );
  }
}