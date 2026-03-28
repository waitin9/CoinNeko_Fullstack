// frontend/lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Map<String, dynamic>>? _budgets;
  List<Category>? _categories;
  bool _loading = true;
  String _month = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getBudgets(month: _month),
        api.getCategories(),
      ]);
      setState(() {
        _budgets = results[0] as List<Map<String, dynamic>>;
        _categories = results[1] as List<Category>;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetModal,
        backgroundColor: AppColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              color: AppColors.purple,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('預算管理', style: AppTextStyles.heading2),
                      Text(_month,
                          style: const TextStyle(
                              color: AppColors.textSub, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_budgets!.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('本月尚未設定預算\n點 + 新增 🐱',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSub, height: 1.8)),
                      ),
                    )
                  else
                    ..._budgets!.map(_buildBudgetItem),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> b) {
    final spent = double.tryParse(b['spent'].toString()) ?? 0.0;
    final limit = double.tryParse(b['limit_amount'].toString()) ?? 0.0;
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (pct < 0.7) barColor = AppColors.green;
    else if (pct < 0.9) barColor = AppColors.gold;
    else barColor = AppColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(b['cat_icon'] as String,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(b['cat_name'] as String, style: AppTextStyles.bodyBold),
              ]),
              Text(
                '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 進度條（對應 .progress-bar）
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetModal() {
    if (_categories == null) return;
    final expenseCategories = _categories!.where((c) => c.type == 'expense').toList();
    int selectedId = expenseCategories.first.id;
    final limitCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('設定預算', style: AppTextStyles.heading3),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedId,
                decoration: const InputDecoration(labelText: '類別（支出）'),
                items: expenseCategories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.icon} ${c.name}'),
                )).toList(),
                onChanged: (v) => setModal(() => selectedId = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '預算上限', prefixText: '\$ '),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final limit = double.tryParse(limitCtrl.text);
                    if (limit == null || limit <= 0) return;
                    await context.read<ApiService>().createBudget(
                          categoryId: selectedId,
                          month: _month,
                          limitAmount: limit,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('確認設定', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}