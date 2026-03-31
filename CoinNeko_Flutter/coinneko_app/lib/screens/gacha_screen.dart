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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'gacha_result',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => _GachaResultOverlay(result: result),
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
// ★ 抽卡結果 全螢幕沉浸式覆蓋
// ──────────────────────────────────────────────
class _GachaResultOverlay extends StatefulWidget {
  final GachaPullResult result;
  const _GachaResultOverlay({required this.result});

  @override
  State<_GachaResultOverlay> createState() => _GachaResultOverlayState();
}

class _GachaResultOverlayState extends State<_GachaResultOverlay>
    with TickerProviderStateMixin {
  // 控制器
  late final AnimationController _bgCtrl;       // 背景暗化
  late final AnimationController _cardCtrl;     // 卡片彈入
  late final AnimationController _infoCtrl;     // 資訊淡入
  late final AnimationController _btnCtrl;      // 按鈕浮現
  late final AnimationController _rotateCtrl;   // 光芒旋轉
  late final AnimationController _pulseCtrl;    // 重複按鈕呼吸
  late final AnimationController _particleCtrl; // 粒子

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

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _infoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut),
    );
    _cardScale = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut),
    );
    _infoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut),
    );
    _infoSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut),
    );
    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _bgCtrl.forward();
    await _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _infoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _btnCtrl.forward();
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

  @override
  Widget build(BuildContext context) {
    final cat = widget.result.cat;
    final rarity = cat.rarity;
    final isDupe = widget.result.isDuplicate;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    // 稀有度對應光芒顏色
    final glowColor = _rarityGlow(rarity);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _cardCtrl, _infoCtrl, _btnCtrl, _rotateCtrl, _pulseCtrl, _particleCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. 全螢幕黑色遮罩 ──
              Opacity(
                opacity: _bgFade.value * 0.88,
                child: Container(color: Colors.black),
              ),

              // ── 2. 放射光芒（旋轉）──
              Center(
                child: Transform.rotate(
                  angle: _rotateCtrl.value * 2 * 3.14159,
                  child: CustomPaint(
                    size: Size(size.width * 1.5, size.width * 1.5),
                    painter: _StarburstPainter(
                      color: glowColor,
                      opacity: _bgFade.value * 0.35,
                    ),
                  ),
                ),
              ),

              // ── 3. 粒子特效 ──
              ..._buildParticles(size, glowColor),

              // ── 4. 主體置中，限寬 ──
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 420 : size.width * 0.92),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: isWide ? 32 : 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── 英雄卡片 ──
                        SlideTransition(
                          position: _cardSlide,
                          child: ScaleTransition(
                            scale: _cardScale,
                            child: _buildHeroCard(cat, rarity, isDupe, isWide),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── 描述 ──
                        SlideTransition(
                          position: _infoSlide,
                          child: FadeTransition(
                            opacity: _infoFade,
                            child: _buildDescription(cat),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── 按鈕 ──
                        FadeTransition(
                          opacity: _btnFade,
                          child: _buildButtons(isDupe),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 英雄卡片
  Widget _buildHeroCard(CatSpecies cat, String rarity, bool isDupe, bool isWide) {
    final cardW = isWide ? 380.0 : double.infinity;
    return Container(
      width: cardW,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _rarityGlow(rarity).withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 貓咪大圖（滿版底圖）
            AspectRatio(
              aspectRatio: 3 / 4,
              child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                  ? Image.network(
                      cat.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1a1a2e),
                        child: Center(
                          child: Text(cat.emoji ?? '🐱',
                              style: const TextStyle(fontSize: 120)),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1a1a2e),
                      child: Center(
                        child: Text(cat.emoji ?? '🐱',
                            style: const TextStyle(fontSize: 120)),
                      ),
                    ),
            ),

            // 底部漸層遮罩
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),

            // 頂部標籤區
            Positioned(
              top: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isDupe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 12)],
                      ),
                      child: const Text(
                        '✨ NEW!',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: RarityHelper.bgColor(rarity),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _rarityGlow(rarity).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      RarityHelper.label(rarity),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: RarityHelper.textColor(rarity),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 底部文字（疊在漸層上）
            Positioned(
              left: 20, right: 20, bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.jobTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 星等
                  Row(
                    children: List.generate(5, (i) {
                      final starLevel = widget.result.newStarLevel ?? 1;
                      return Icon(
                        i < starLevel ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 22,
                        color: i < starLevel ? AppColors.gold : Colors.white30,
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

  Widget _buildDescription(CatSpecies cat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        cat.description,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildButtons(bool isDupe) {
    return Column(
      children: [
        if (isDupe)
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.result.starUp
                    ? '✨ 重複！升至 ${widget.result.newStarLevel} 星 +${widget.result.coinsBonus} 🪙'
                    : '✨ 已達 5 星上限！換取 ${widget.result.coinsBonus} 🪙',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              '繼續抽！🎰',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 粒子特效
  List<Widget> _buildParticles(Size size, Color color) {
    final particles = [
      _ParticleConfig(emoji: '⭐', x: 0.15, y: 0.25, delay: 0.0, size: 20),
      _ParticleConfig(emoji: '🪙', x: 0.80, y: 0.20, delay: 0.3, size: 18),
      _ParticleConfig(emoji: '✨', x: 0.10, y: 0.60, delay: 0.6, size: 16),
      _ParticleConfig(emoji: '⭐', x: 0.85, y: 0.55, delay: 0.1, size: 22),
      _ParticleConfig(emoji: '🪙', x: 0.20, y: 0.80, delay: 0.5, size: 16),
      _ParticleConfig(emoji: '</>', x: 0.75, y: 0.78, delay: 0.2, size: 14),
      _ParticleConfig(emoji: '✨', x: 0.50, y: 0.10, delay: 0.4, size: 20),
    ];

    return particles.map((p) {
      final t = (_particleCtrl.value + p.delay) % 1.0;
      final floatY = size.height * p.y - (t * 60);
      final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
      return Positioned(
        left: size.width * p.x,
        top: floatY,
        child: Opacity(
          opacity: opacity * _bgFade.value,
          child: Text(p.emoji,
              style: TextStyle(fontSize: p.size.toDouble())),
        ),
      );
    }).toList();
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

class _ParticleConfig {
  final String emoji;
  final double x, y, delay;
  final int size;
  const _ParticleConfig({
    required this.emoji, required this.x, required this.y,
    required this.delay, required this.size,
  });
}

// 放射光芒 CustomPainter
class _StarburstPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _StarburstPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    const rays = 16;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * 3.14159;
      final nextAngle = ((i + 0.4) / rays) * 2 * 3.14159;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + maxR * 1.2 * (i % 2 == 0 ? 1 : 0.6) * math.cos(angle),
          center.dy + maxR * 1.2 * (i % 2 == 0 ? 1 : 0.6) * math.sin(angle),
        )
        ..lineTo(
          center.dx + maxR * 1.2 * (i % 2 == 0 ? 1 : 0.6) * math.cos(nextAngle),
          center.dy + maxR * 1.2 * (i % 2 == 0 ? 1 : 0.6) * math.sin(nextAngle),
        )
        ..close();

      paint.color = color.withOpacity(opacity * (i % 2 == 0 ? 1 : 0.4));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StarburstPainter old) =>
      old.opacity != opacity || old.color != color;
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