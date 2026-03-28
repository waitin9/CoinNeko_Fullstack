// frontend/lib/screens/dashboard_screen.dart
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
  bool _loading = true;
  String _currentMonth = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 月份選擇
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('月度總覽', style: AppTextStyles.heading2),
                    _MonthSelector(
                      month: _currentMonth,
                      onChanged: (m) {
                        setState(() => _currentMonth = m);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 三格總覽（對應 .stats-grid）
                _buildStatsGrid(),
                const SizedBox(height: 20),

                // 類別明細
                if (_summary != null) _buildCategoryList(),
              ],
            ),
    );
  }

  Widget _buildStatsGrid() {
    if (_summary == null) return const SizedBox();
    final income = ((_summary!['income'] as num?)?.toDouble() ?? 0);
    final expense = ((_summary!['expense'] as num?)?.toDouble() ?? 0);
    final balance = income - expense;

    return Row(
      children: [
        Expanded(child: _StatCard(label: '本月收入', value: income, type: 'income')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: '本月支出', value: expense, type: 'expense')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: '結餘', value: balance, type: 'balance')),
      ],
    );
  }

  Widget _buildCategoryList() {
    final categories = _summary!['by_category'] as List? ?? [];
    if (categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('本月尚無記帳紀錄 🐱',
              style: TextStyle(color: AppColors.textSub, fontSize: 14)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('類別統計', style: AppTextStyles.cardTitle),
        const SizedBox(height: 12),
        ...categories.map((c) {
          final isIncome = c['type'] == 'income';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isIncome ? AppColors.greenLight : AppColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(c['icon'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(c['name'] as String,
                      style: AppTextStyles.bodyBold),
                ),
                Text(
                  '${isIncome ? '+' : '-'}\$${(c['total'] as num).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isIncome ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final String type; // 'income' | 'expense' | 'balance'

  const _StatCard({required this.label, required this.value, required this.type});

  Color get _color {
    switch (type) {
      case 'income': return AppColors.green;
      case 'expense': return AppColors.red;
      default: return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String month;
  final ValueChanged<String> onChanged;

  const _MonthSelector({required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 使用 showDatePicker 選月份
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.parse('$month-01'),
          firstDate: DateTime(2020),
          lastDate: now,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.purple),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().substring(0, 7));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.purple),
            const SizedBox(width: 6),
            Text(month,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}