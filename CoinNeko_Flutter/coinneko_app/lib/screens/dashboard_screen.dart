// frontend/lib/screens/dashboard_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  bool   _loading = true;
  String _currentMonth = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api  = context.read<ApiService>();
      final data = await api.getSummary(month: _currentMonth);
      setState(() => _summary = data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    // 標題 + 月份選擇
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('月度總覽', style: AppTextStyles.heading2),
                      _MonthSelector(month: _currentMonth, onChanged: (m) {
                        setState(() => _currentMonth = m);
                        _load();
                      }),
                    ]),
                    const SizedBox(height: 20),

                    // 主卡片：結餘（大）
                    _buildBalanceHero(),
                    const SizedBox(height: 12),

                    // 次卡片：收入 + 支出（小，並排）
                    _buildIncomeExpenseRow(),
                    const SizedBox(height: 24),

                    // 甜甜圈圖
                    if (_summary != null) _buildDonut(),
                    const SizedBox(height: 24),

                    // 類別統計排行
                    if (_summary != null) _buildCategoryRanking(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── 結餘主卡片 ──
  Widget _buildBalanceHero() {
    final income  = ((_summary?['income']  as num?)?.toDouble() ?? 0);
    final expense = ((_summary?['expense'] as num?)?.toDouble() ?? 0);
    final balance = income - expense;
    final isPos   = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPos
              ? [const Color(0xFF7B52FF), const Color(0xFF4A1FA8)]
              : [const Color(0xFFE53935), const Color(0xFF8B0000)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isPos ? AppColors.purple : AppColors.red).withOpacity(0.35),
          blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('本月結餘', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          Icon(isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: Colors.white54, size: 22),
        ]),
        const SizedBox(height: 10),
        Text(
          '${isPos ? '' : '-'}\$${balance.abs().toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito',
              fontSize: 40, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(_currentMonth, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  // ── 收入 + 支出小卡片 ──
  Widget _buildIncomeExpenseRow() {
    final income  = ((_summary?['income']  as num?)?.toDouble() ?? 0);
    final expense = ((_summary?['expense'] as num?)?.toDouble() ?? 0);
    return Row(children: [
      Expanded(child: _MiniStatCard(label: '本月收入', value: income,
          color: AppColors.green, bgColor: AppColors.greenLight, icon: Icons.arrow_downward_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _MiniStatCard(label: '本月支出', value: expense,
          color: AppColors.red, bgColor: AppColors.redLight, icon: Icons.arrow_upward_rounded)),
    ]);
  }

  // ── 甜甜圈圖 ──
  Widget _buildDonut() {
    final cats = (_summary!['by_category'] as List? ?? [])
        .where((c) => c['type'] == 'expense')
        .toList();
    if (cats.isEmpty) return const SizedBox();

    final total = cats.fold<double>(0, (s, c) => s + (c['total'] as num).toDouble());
    final colors = _catColors();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('支出分佈', style: AppTextStyles.cardTitle),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: _DonutPainter(
              sections: cats.asMap().entries.map((e) => _DonutSection(
                value: (e.value['total'] as num).toDouble(),
                color: colors[e.key % colors.length],
              )).toList(),
              total: total,
              centerLabel: '\$${total.toStringAsFixed(0)}',
            ),
            child: Container(),
          ),
        ),
      ]),
    );
  }

  // ── 類別統計排行 ──
  Widget _buildCategoryRanking() {
    final cats = (_summary!['by_category'] as List? ?? []);
    if (cats.isEmpty) return const Center(
        child: Padding(padding: EdgeInsets.all(40),
          child: Text('本月尚無記帳紀錄 🐱',
              style: TextStyle(color: AppColors.textSub, fontSize: 14))));

    final expCats = cats.where((c) => c['type'] == 'expense').toList();
    final totalExp = expCats.fold<double>(0, (s, c) => s + (c['total'] as num).toDouble());
    final colors = _catColors();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('類別統計', style: AppTextStyles.cardTitle),
      const SizedBox(height: 12),
      ...cats.asMap().entries.map((entry) {
        final c       = entry.value;
        final isIncome = c['type'] == 'income';
        final amount  = (c['total'] as num).toDouble();
        final ratio   = (totalExp > 0 && !isIncome) ? (amount / totalExp).clamp(0.0, 1.0) : 0.0;
        final barColor = isIncome ? AppColors.green : colors[entry.key % colors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.greenLight : AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(c['icon'] as String, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(c['name'] as String, style: AppTextStyles.bodyBold)),
              Text(
                '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800,
                    fontSize: 15, color: isIncome ? AppColors.green : AppColors.red),
              ),
            ]),
            if (!isIncome && totalExp > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                )),
                const SizedBox(width: 10),
                Text('${(ratio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w600)),
              ]),
            ],
          ]),
        );
      }),
    ]);
  }

  List<Color> _catColors() => const [
    Color(0xFF7C4DFF), Color(0xFF00BCD4), Color(0xFFFF5722), Color(0xFF4CAF50),
    Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF2196F3), Color(0xFF9C27B0),
  ];
}

// ── 甜甜圈圖 Painter ──
class _DonutSection { final double value; final Color color;
  const _DonutSection({required this.value, required this.color}); }

class _DonutPainter extends CustomPainter {
  final List<_DonutSection> sections;
  final double total;
  final String centerLabel;
  const _DonutPainter({required this.sections, required this.total, required this.centerLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final radius = math.min(cx, cy) - 10;
    final strokeW = radius * 0.38;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (final s in sections) {
      final sweep = total > 0 ? (s.value / total) * 2 * math.pi : 0.0;
      paint.color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - strokeW / 2),
        startAngle, sweep - 0.02, false, paint,
      );
      startAngle += sweep;
    }

    // 中央文字
    final tp = TextPainter(
      text: TextSpan(text: centerLabel,
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900,
              fontSize: 18, color: AppColors.text)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.total != total;
}

// ── 小統計卡 ──
class _MiniStatCard extends StatelessWidget {
  final String label; final double value;
  final Color color, bgColor; final IconData icon;
  const _MiniStatCard({required this.label, required this.value,
    required this.color, required this.bgColor, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppShadows.card,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      Text('\$${value.toStringAsFixed(0)}',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    ]),
  );
}

class _MonthSelector extends StatelessWidget {
  final String month; final ValueChanged<String> onChanged;
  const _MonthSelector({required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.parse('$month-01'),
        firstDate: DateTime(2020),
        lastDate: now,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.purple)),
          child: child!),
      );
      if (picked != null) onChanged(picked.toIso8601String().substring(0, 7));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.purple),
        const SizedBox(width: 6),
        Text(month, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.purple, fontSize: 13)),
      ]),
    ),
  );
}