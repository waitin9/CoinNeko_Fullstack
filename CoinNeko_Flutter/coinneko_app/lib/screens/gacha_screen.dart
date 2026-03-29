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
  GachaPullResult? _lastResult;
  bool _isPullingTicket = false;
  bool _isPullingCoins = false;
  String? _error;

  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  late final AnimationController _popCtrl;
  late final Animation<double> _popAnim;

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

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popAnim = CurvedAnimation(
      parent: _popCtrl,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _popCtrl.dispose();
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
    _popCtrl.reset();

    try {
      final api = context.read<ApiService>();
      final result = await api.gachaPull(useCoins: useCoins);

      context.read<AuthService>().updateUser(result.user);

      context.read<CollectionProvider>().applyGachaResult(
            catSpeciesId: result.cat.id,
            isDuplicate: result.isDuplicate,
            newStarLevel: result.newStarLevel,
          );

      setState(() => _lastResult = result);
      _popCtrl.forward();
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
                const SizedBox(height: 8),
                if (_lastResult != null) _buildResultCard(_lastResult!),
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
          emoji: '🪙',
          label: '${user.coins} 金幣',
          color: AppColors.gold,
          bgColor: AppColors.goldLight,
        ),
        const SizedBox(width: 12),
        _ResourceChip(
          emoji: '🎟️',
          label: '${user.gachaTickets} 扭蛋券',
          color: AppColors.purple,
          bgColor: AppColors.purpleLight,
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

  Widget _buildResultCard(GachaPullResult result) {
    final cat = result.cat;
    final rarity = cat.rarity;

    return ScaleTransition(
      scale: _popAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: RarityHelper.cardGradient(rarity),
          ),
          borderRadius: BorderRadius.circular(AppRadius.modal),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          children: [
            CatAvatar(
              imageUrl: cat.imageUrl,
              emoji: cat.emoji,
              size: 100,
            ),
            const SizedBox(height: 10),
            _RarityBadge(rarity: rarity, large: true),
            const SizedBox(height: 12),
            Text(
              cat.name,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cat.jobTitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              cat.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            if (result.isDuplicate)
              _buildDupeMessage(result)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎉 新貓咪加入圖鑑！',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDupeMessage(GachaPullResult result) {
    final msg = result.starUp
        ? '✨ 重複！升至 ${result.newStarLevel} 星 + ${result.coinsBonus} 🪙'
        : '✨ 已達 5 星上限！換取 ${result.coinsBonus} 🪙';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        msg,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
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