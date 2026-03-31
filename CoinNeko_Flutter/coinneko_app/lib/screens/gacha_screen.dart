// frontend/lib/screens/gacha_screen.dart
import 'dart:math' as math;
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

      if (mounted) {
        _showResultOverlay(result);
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

  void _showResultOverlay(GachaPullResult result) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => _GachaResultOverlay(result: result),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
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
                _buildPullButtons(user),
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
        Text('扭蛋機',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            )),
        SizedBox(height: 4),
        Text('抽卡召喚你的財務貓咪夥伴',
            style: TextStyle(fontSize: 14, color: AppColors.textSub)),
      ],
    );
  }

  Widget _buildGachaMachine() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _floatAnim.value), child: child),
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

  Widget _buildPullButtons(UserModel user) {
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
      child: Text('❌ $_error',
          style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
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

// ══════════════════════════════════════════════════════════
// ★  全螢幕沉浸式抽卡結果覆蓋層
// ══════════════════════════════════════════════════════════
class _GachaResultOverlay extends StatefulWidget {
  final GachaPullResult result;
  const _GachaResultOverlay({required this.result});

  @override
  State<_GachaResultOverlay> createState() => _GachaResultOverlayState();
}

class _GachaResultOverlayState extends State<_GachaResultOverlay>
    with TickerProviderStateMixin {
  // 控制器
  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _infoCtrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _particleCtrl;

  // 動畫
  late final Animation<double> _bgFade;
  late final Animation<double> _cardScale;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _infoFade;
  late final Animation<Offset> _infoSlide;
  late final Animation<double> _btnFade;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _infoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();

    _bgFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));
    _cardScale = CurvedAnimation(
        parent: _cardCtrl,
        curve: const Cubic(0.175, 0.885, 0.32, 1.275));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _infoFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut));
    _infoSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut));
    _btnFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 0.93, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _bgCtrl.forward();
    await _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 130));
    await _infoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 60));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _infoCtrl.dispose();
    _btnCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Color get _glow {
    switch (widget.result.cat.rarity) {
      case 'legendary': return const Color(0xFFFFD700);
      case 'epic':      return const Color(0xFFB44FE8);
      case 'rare':      return const Color(0xFF4A90E8);
      default:          return const Color(0xFF6BCB77);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat    = widget.result.cat;
    final rarity = cat.rarity;
    final isDupe = widget.result.isDuplicate;
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 560;
    final cardW  = isWide ? 400.0 : size.width * 0.90;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl, _cardCtrl, _infoCtrl, _btnCtrl,
          _rotateCtrl, _pulseCtrl, _particleCtrl,
        ]),
        builder: (ctx, _) => Stack(
          fit: StackFit.expand,
          children: [
            // 1. 黑色背景
            Opacity(
              opacity: (_bgFade.value * 0.90).clamp(0.0, 1.0),
              child: Container(color: const Color(0xFF0B0B18)),
            ),

            // 2. 旋轉光芒
            Center(
              child: Opacity(
                opacity: (_bgFade.value * 0.45).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: _rotateCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(size.width * 1.7, size.width * 1.7),
                    painter: _StarburstPainter(color: _glow),
                  ),
                ),
              ),
            ),

            // 3. 粒子
            ..._particles(size),

            // 4. 主體（置中 + 限寬 + 可捲動）
            Center(
              child: SizedBox(
                width: cardW,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: isWide ? 40 : 20),
                  child: Column(
                    children: [
                      // 英雄卡片
                      SlideTransition(
                        position: _cardSlide,
                        child: ScaleTransition(
                          scale: _cardScale,
                          child: _heroCard(cat, rarity, isDupe),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 描述
                      FadeTransition(
                        opacity: _infoFade,
                        child: SlideTransition(
                          position: _infoSlide,
                          child: _descBox(cat),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 按鈕
                      FadeTransition(
                        opacity: _btnFade,
                        child: _buttons(isDupe),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 英雄卡片（貓咪滿版大圖 + 漸層文字）
  Widget _heroCard(CatSpecies cat, String rarity, bool isDupe) {
    final hasImg = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _glow.withValues(alpha: 0.55), blurRadius: 42, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 貓咪大圖（3:4）
            AspectRatio(
              aspectRatio: 3 / 4,
              child: hasImg
                  ? Image.network(cat.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _EmojiBackground(emoji: cat.emoji, rarity: rarity))
                  : _EmojiBackground(emoji: cat.emoji, rarity: rarity),
            ),

            // 底部漸層
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 210,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF5000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),

            // 頂部標籤
            Positioned(
              top: 14, left: 14, right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isDupe)
                    _Badge(
                      text: '✨ NEW!',
                      bg: Colors.white,
                      fg: Colors.deepPurple,
                      glow: Colors.white,
                    )
                  else
                    const SizedBox(),
                  _Badge(
                    text: RarityHelper.label(rarity),
                    bg: RarityHelper.bgColor(rarity),
                    fg: RarityHelper.textColor(rarity),
                    glow: _glow,
                  ),
                ],
              ),
            ),

            // 底部名稱 + 星星
            Positioned(
              left: 18, right: 18, bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.jobTitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(cat.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      )),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final stars = widget.result.newStarLevel ?? 1;
                      return Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 22,
                        color: i < stars ? AppColors.gold : Colors.white30,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 描述區塊
  Widget _descBox(CatSpecies cat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        cat.description,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
      ),
    );
  }

  // 按鈕區
  Widget _buttons(bool isDupe) {
    final dupeText = widget.result.starUp
        ? '✨ 重複！升至 ${widget.result.newStarLevel} 星  +${widget.result.coinsBonus} 🪙'
        : '✨ 已達 5 星上限！換取 ${widget.result.coinsBonus} 🪙';

    return Column(
      children: [
        if (isDupe) ...[
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF7A00)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 22, spreadRadius: 2)
                ],
              ),
              child: Text(dupeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  )),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('繼續抽！🎰',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 17)),
          ),
        ),
      ],
    );
  }

  // 粒子
  List<Widget> _particles(Size sz) {
    const ps = [
      _ParticleCfg('⭐', 0.10, 0.20, 0.00, 20),
      _ParticleCfg('🪙', 0.84, 0.18, 0.25, 18),
      _ParticleCfg('✨', 0.06, 0.60, 0.50, 16),
      _ParticleCfg('⭐', 0.88, 0.55, 0.10, 22),
      _ParticleCfg('🪙', 0.16, 0.78, 0.40, 15),
      _ParticleCfg('✨', 0.80, 0.75, 0.65, 16),
      _ParticleCfg('⭐', 0.50, 0.06, 0.30, 20),
    ];
    return ps.map((p) {
      final t   = (_particleCtrl.value + p.delay) % 1.0;
      final fy  = sz.height * p.y - t * 70;
      final op  = ((t < 0.5 ? t * 2 : (1 - t) * 2) * _bgFade.value).clamp(0.0, 1.0);
      return Positioned(
        left: sz.width * p.x,
        top: fy,
        child: Opacity(opacity: op,
            child: Text(p.e, style: TextStyle(fontSize: p.size.toDouble()))),
      );
    }).toList();
  }
}

// 粒子設定
class _ParticleCfg {
  final String e;
  final double x, y, delay;
  final int size;
  const _ParticleCfg(this.e, this.x, this.y, this.delay, this.size);
}

// 放射光芒 Painter
class _StarburstPainter extends CustomPainter {
  final Color color;
  const _StarburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width / 2;
    const rays = 18;
    final p = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rays; i++) {
      final a1 = (i / rays) * 2 * math.pi;
      final a2 = ((i + 0.38) / rays) * 2 * math.pi;
      final r  = maxR * (i % 2 == 0 ? 1.15 : 0.65);
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(cx + r * math.cos(a1), cy + r * math.sin(a1))
        ..lineTo(cx + r * math.cos(a2), cy + r * math.sin(a2))
        ..close();
      p.color = color.withValues(alpha: i % 2 == 0 ? 0.20 : 0.09);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_StarburstPainter old) => old.color != color;
}

// 標籤小元件
class _Badge extends StatelessWidget {
  final String text;
  final Color bg, fg, glow;
  const _Badge({required this.text, required this.bg, required this.fg, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 12)],
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: fg)),
    );
  }
}

// 沒有圖片時用漸層 + emoji
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
          child: Text(emoji ?? '🐱', style: const TextStyle(fontSize: 100))),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 子元件
// ══════════════════════════════════════════════════════════

class _ResourceChip extends StatelessWidget {
  final String emoji, label;
  final Color color, bgColor;
  const _ResourceChip(
      {required this.emoji, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Text('$emoji $label',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _GachaButton extends StatelessWidget {
  final String label, subtitle;
  final Color color;
  final bool enabled, isLoading;
  final VoidCallback onPressed;
  const _GachaButton({
    required this.label, required this.subtitle, required this.color,
    required this.enabled, required this.isLoading, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? color : color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: enabled
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: isLoading
              ? const Center(child: SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: const TextStyle(
                      color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
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
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 8, vertical: large ? 5 : 2),
      decoration: BoxDecoration(
          color: RarityHelper.bgColor(rarity),
          borderRadius: BorderRadius.circular(AppRadius.badge)),
      child: Text(RarityHelper.label(rarity),
          style: TextStyle(
              fontSize: large ? 13 : 10,
              fontWeight: FontWeight.w700,
              color: RarityHelper.textColor(rarity))),
    );
  }
}

class _OddsRow extends StatelessWidget {
  final String rarity, pct;
  const _OddsRow({required this.rarity, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _RarityBadge(rarity: rarity , large: true),
      const SizedBox(width: 8),
      Text(pct,
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text)),
    ]);
  }
}