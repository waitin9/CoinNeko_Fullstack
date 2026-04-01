// frontend/lib/screens/gacha_screen.dart
import 'dart:math' as math;
import 'dart:ui';
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
  bool _isPullingCoins  = false;
  String? _error;

  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -14).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pull({required bool useCoins}) async {
    if (useCoins && _isPullingCoins)  return;
    if (!useCoins && _isPullingTicket) return;

    setState(() {
      _error = null;
      if (useCoins) _isPullingCoins = true;
      else          _isPullingTicket = true;
    });

    try {
      final api    = context.read<ApiService>();
      final result = await api.gachaPull(useCoins: useCoins);

      context.read<AuthService>().updateUser(result.user);
      context.read<CollectionProvider>().applyGachaResult(
        catSpeciesId: result.cat.id,
        isDuplicate:  result.isDuplicate,
        newStarLevel: result.newStarLevel,
      );

      if (mounted) _showResultOverlay(result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '網路錯誤，請稍後再試');
    } finally {
      setState(() {
        _isPullingCoins  = false;
        _isPullingTicket = false;
      });
    }
  }

  void _showResultOverlay(GachaPullResult result) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => _GachaResultOverlay(result: result),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user   = context.watch<AuthService>().user!;
    final size   = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 沉浸式放射漸層背景 ──
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                const Color(0xFF2D1B6B),
                const Color(0xFF120D2E),
                const Color(0xFF080612),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // 背景裝飾星點
        ..._buildStarDots(size),

        // ── 主體內容 ──
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: size.height * 0.02),
                    _buildHeroMachine(size),
                    SizedBox(height: size.height * 0.02),
                    _buildResourceRow(user),
                    const SizedBox(height: 24),
                    _buildJuicyButtons(user),
                    const SizedBox(height: 10),
                    if (_error != null) _buildErrorBanner(),
                    const SizedBox(height: 24),
                    _buildGlassOddsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStarDots(Size size) {
    final rng = math.Random(42);
    return List.generate(22, (i) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 2.0 + 0.5;
      return Positioned(
        left: x, top: y,
        child: Container(
          width: r * 2, height: r * 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: rng.nextDouble() * 0.4 + 0.1),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text('✨ 扭蛋機 ✨',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xFFB085FF), blurRadius: 16)],
            )),
        SizedBox(height: 4),
        Text('抽卡召喚你的財務貓咪夥伴',
            style: TextStyle(fontSize: 13, color: Colors.white60)),
      ],
    );
  }

  Widget _buildHeroMachine(Size size) {
    final heroH = (size.height * 0.28).clamp(160.0, 260.0);
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: Container(
        height: heroH,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 發光光圈
            Container(
              width: heroH * 0.88,
              height: heroH * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB085FF).withValues(alpha: 0.35),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.20),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
            // 扭蛋機 emoji 超大
            Text('🎰',
                style: TextStyle(
                  fontSize: heroH * 0.60,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassChip(emoji: '🎟️', label: '${user.gachaTickets} 扭蛋券',
            color: const Color(0xFFB085FF)),
        const SizedBox(width: 12),
        _GlassChip(emoji: '🪙', label: '${user.coins} 金幣',
            color: const Color(0xFFFFD600)),
      ],
    );
  }

  Widget _buildJuicyButtons(UserModel user) {
    final isBusy = _isPullingTicket || _isPullingCoins;
    return Column(
      children: [
        // 扭蛋券按鈕（紫粉漸層）
        ScaleTransition(
          scale: _pulseAnim,
          child: _JuicyButton(
            label: '🎟️ 使用扭蛋券',
            subtitle: '剩餘 ${user.gachaTickets} 張',
            gradientColors: const [Color(0xFFD040FB), Color(0xFF7C4DFF)],
            glowColor: const Color(0xFFB085FF),
            enabled: !isBusy && user.gachaTickets > 0,
            isLoading: _isPullingTicket,
            onPressed: () => _pull(useCoins: false),
          ),
        ),
        const SizedBox(height: 12),
        // 金幣按鈕（金色漸層）
        ScaleTransition(
          scale: _pulseAnim,
          child: _JuicyButton(
            label: '🪙 使用 50 金幣',
            subtitle: '剩餘 ${user.coins} 枚',
            gradientColors: const [Color(0xFFFFD600), Color(0xFFFF8F00)],
            glowColor: const Color(0xFFFFAB00),
            enabled: !isBusy && user.coins >= 50,
            isLoading: _isPullingCoins,
            onPressed: () => _pull(useCoins: true),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('❌ $_error',
          style: const TextStyle(
              color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  // 毛玻璃機率面板
  Widget _buildGlassOddsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 抽卡機率',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  )),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _OddsItem(rarity: 'common',    pct: '65%', color: const Color(0xFF78C17A))),
                  Expanded(child: _OddsItem(rarity: 'rare',      pct: '25%', color: const Color(0xFF4A90E8))),
                  Expanded(child: _OddsItem(rarity: 'epic',      pct: '8%',  color: const Color(0xFFB44FE8))),
                  Expanded(child: _OddsItem(rarity: 'legendary', pct: '2%',  color: const Color(0xFFFFD700))),
                ],
              ),
              const SizedBox(height: 14),
              Text('💡 重複獲得的貓咪會自動升星（上限 5 星），滿星後轉換為金幣',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.55))),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 全螢幕抽卡結果
// ══════════════════════════════════════════════
class _GachaResultOverlay extends StatefulWidget {
  final GachaPullResult result;
  const _GachaResultOverlay({required this.result});

  @override
  State<_GachaResultOverlay> createState() => _GachaResultOverlayState();
}

class _GachaResultOverlayState extends State<_GachaResultOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl, _cardCtrl, _infoCtrl, _btnCtrl,
      _rotateCtrl, _pulseCtrl, _particleCtrl;
  late final Animation<double> _bgFade, _cardScale, _infoFade, _btnFade, _pulse;
  late final Animation<Offset> _cardSlide, _infoSlide;

  @override
  void initState() {
    super.initState();
    _bgCtrl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _cardCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _infoCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _btnCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _rotateCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _bgFade    = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bgCtrl,   curve: Curves.easeOut));
    _cardScale = CurvedAnimation(parent: _cardCtrl, curve: const Cubic(0.175, 0.885, 0.32, 1.275));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _infoFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut));
    _infoSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _infoCtrl, curve: Curves.easeOut));
    _btnFade   = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _btnCtrl,  curve: Curves.easeOut));
    _pulse     = Tween<double>(begin: 0.93, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _runSeq();
  }

  Future<void> _runSeq() async {
    await _bgCtrl.forward();
    await _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 130));
    await _infoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 60));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in [_bgCtrl, _cardCtrl, _infoCtrl, _btnCtrl, _rotateCtrl, _pulseCtrl, _particleCtrl]) c.dispose();
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
        animation: Listenable.merge([_bgCtrl, _cardCtrl, _infoCtrl, _btnCtrl, _rotateCtrl, _pulseCtrl, _particleCtrl]),
        builder: (ctx, _) => Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: (_bgFade.value * 0.90).clamp(0.0, 1.0),
                child: Container(color: const Color(0xFF0B0B18))),
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
            ..._particles(size),
            Center(
              child: SizedBox(
                width: cardW,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: isWide ? 40 : 20),
                  child: Column(
                    children: [
                      SlideTransition(position: _cardSlide,
                        child: ScaleTransition(scale: _cardScale, child: _heroCard(cat, rarity, isDupe))),
                      const SizedBox(height: 18),
                      FadeTransition(opacity: _infoFade,
                        child: SlideTransition(position: _infoSlide, child: _descBox(cat))),
                      const SizedBox(height: 18),
                      FadeTransition(opacity: _btnFade, child: _buttons(isDupe)),
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

  Widget _heroCard(CatSpecies cat, String rarity, bool isDupe) {
    final hasImg = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _glow.withValues(alpha: 0.55), blurRadius: 42, spreadRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: hasImg
                ? Image.network(cat.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _EmojiBackground(emoji: cat.emoji, rarity: rarity))
                : _EmojiBackground(emoji: cat.emoji, rarity: rarity),
          ),
          Positioned(left: 0, right: 0, bottom: 0,
            child: Container(height: 210, decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Color(0xF5000000), Color(0x00000000)])))),
          Positioned(top: 14, left: 14, right: 14,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (!isDupe)
                _SmallBadge(text: '✨ NEW!', bg: Colors.white, fg: Colors.deepPurple, glow: Colors.white)
              else const SizedBox(),
              _SmallBadge(text: RarityHelper.label(rarity),
                  bg: RarityHelper.bgColor(rarity), fg: RarityHelper.textColor(rarity), glow: _glow),
            ])),
          Positioned(left: 18, right: 18, bottom: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(cat.jobTitle, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(cat.name, style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
                  fontSize: 28, fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
              const SizedBox(height: 10),
              Row(children: List.generate(5, (i) {
                final stars = widget.result.newStarLevel ?? 1;
                return Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 22, color: i < stars ? AppColors.gold : Colors.white30);
              })),
            ])),
        ]),
      ),
    );
  }

  Widget _descBox(CatSpecies cat) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Text(cat.description, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.7)),
  );

  Widget _buttons(bool isDupe) {
    final dupeText = widget.result.starUp
        ? '✨ 重複！升至 ${widget.result.newStarLevel} 星  +${widget.result.coinsBonus} 🪙'
        : '✨ 已達 5 星上限！換取 ${widget.result.coinsBonus} 🪙';
    final catId = widget.result.cat.id;

    return Column(children: [
      // ── 升星提示 Badge（靜態標籤，非按鈕）──
      if (isDupe) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.45)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 4),
            Flexible(child: Text(dupeText, textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ))),
          ]),
        ),
        const SizedBox(height: 12),
      ],

      // ── 兩個操作按鈕並排 ──
      Row(children: [
        // 繼續抽
        Expanded(child: SizedBox(height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('繼續抽 🎰',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 15)),
          ))),
        const SizedBox(width: 10),
        // 前往圖鑑
        Expanded(child: SizedBox(height: 52,
          child: OutlinedButton(
            onPressed: () {
              // 關閉結果頁，然後導航到圖鑑並帶 catId
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                '/collection',
                arguments: {'highlightCatId': catId},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('前往圖鑑 📖',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 15)),
          ))),
      ]),
    ]);
  }

  List<Widget> _particles(Size sz) {
    const ps = [
      _PC('⭐', 0.10, 0.20, 0.00, 20), _PC('🪙', 0.84, 0.18, 0.25, 18),
      _PC('✨', 0.06, 0.60, 0.50, 16), _PC('⭐', 0.88, 0.55, 0.10, 22),
      _PC('🪙', 0.16, 0.78, 0.40, 15), _PC('✨', 0.80, 0.75, 0.65, 16),
      _PC('⭐', 0.50, 0.06, 0.30, 20),
    ];
    return ps.map((p) {
      final t  = (_particleCtrl.value + p.delay) % 1.0;
      final fy = sz.height * p.y - t * 70;
      final op = ((t < 0.5 ? t * 2 : (1 - t) * 2) * _bgFade.value).clamp(0.0, 1.0);
      return Positioned(left: sz.width * p.x, top: fy,
          child: Opacity(opacity: op,
              child: Text(p.e, style: TextStyle(fontSize: p.size.toDouble()))));
    }).toList();
  }
}

class _PC { final String e; final double x, y, delay; final int size;
  const _PC(this.e, this.x, this.y, this.delay, this.size); }

class _StarburstPainter extends CustomPainter {
  final Color color;
  const _StarburstPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final maxR = size.width / 2; const rays = 18;
    final p = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < rays; i++) {
      final a1 = (i / rays) * 2 * math.pi;
      final a2 = ((i + 0.38) / rays) * 2 * math.pi;
      final r  = maxR * (i % 2 == 0 ? 1.15 : 0.65);
      final path = Path()..moveTo(cx, cy)
        ..lineTo(cx + r * math.cos(a1), cy + r * math.sin(a1))
        ..lineTo(cx + r * math.cos(a2), cy + r * math.sin(a2))..close();
      p.color = color.withValues(alpha: i % 2 == 0 ? 0.20 : 0.09);
      canvas.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(_StarburstPainter old) => old.color != color;
}

class _EmojiBackground extends StatelessWidget {
  final String? emoji; final String rarity;
  const _EmojiBackground({this.emoji, required this.rarity});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: RarityHelper.cardGradient(rarity))),
    child: Center(child: Text(emoji ?? '🐱', style: const TextStyle(fontSize: 100))));
}

class _SmallBadge extends StatelessWidget {
  final String text; final Color bg, fg, glow;
  const _SmallBadge({required this.text, required this.bg, required this.fg, required this.glow});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 12)]),
    child: Text(text, style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 12, color: fg)));
}

// ══════════════════════════════════════════════
// 子元件
// ══════════════════════════════════════════════
class _GlassChip extends StatelessWidget {
  final String emoji, label; final Color color;
  const _GlassChip({required this.emoji, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.badge),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.badge),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text('$emoji $label',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ),
    ),
  );
}

class _JuicyButton extends StatelessWidget {
  final String label, subtitle;
  final List<Color> gradientColors;
  final Color glowColor;
  final bool enabled, isLoading;
  final VoidCallback onPressed;
  const _JuicyButton({required this.label, required this.subtitle,
    required this.gradientColors, required this.glowColor,
    required this.enabled, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: enabled ? null : Colors.white12,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled ? [
                BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6)),
              ] : [],
            ),
            child: isLoading
                ? const Center(child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(label, style: const TextStyle(color: Colors.white,
                        fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 17)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
          ),
        ),
      ),
    );
  }
}

class _OddsItem extends StatelessWidget {
  final String rarity, pct; final Color color;
  const _OddsItem({required this.rarity, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 10, height: 10, margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    Text(RarityHelper.label(rarity),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(pct, style: const TextStyle(fontSize: 14, color: Colors.white,
        fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
  ]);
}