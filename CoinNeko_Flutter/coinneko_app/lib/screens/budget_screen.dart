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
  String? _loadError;
  String _month = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final api = context.read<ApiService>();
      final budgets = await api.getBudgets(month: _month);
      final categories = await api.getCategories();
      setState(() {
        _budgets = budgets;
        _categories = categories;
      });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😿', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('載入失敗，請重試',
                          style: TextStyle(color: AppColors.textSub)),
                      const SizedBox(height: 8),
                      Text(_loadError!,
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 11)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple),
                        child: const Text('重新載入',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
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
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_budgets == null || _budgets!.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('本月尚未設定預算\n點 + 新增 🐱',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textSub, height: 1.8)),
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
    // ★ categories 還沒載入就先觸發載入再提示
    if (_categories == null || _categories!.isEmpty) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('類別載入中，請稍後再試'),
          backgroundColor: AppColors.purple,
        ),
      );
      return;
    }

    final expenseCategories =
        _categories!.where((c) => c.type == 'expense').toList();

    if (expenseCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('找不到支出類別'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

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
              left: 24,
              right: 24,
              top: 24),
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
                items: expenseCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icon} ${c.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setModal(() => selectedId = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: limitCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: '預算上限', prefixText: '\$ '),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final limit = double.tryParse(limitCtrl.text);
                    if (limit == null || limit <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('請輸入有效金額'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      await context.read<ApiService>().createBudget(
                            categoryId: selectedId,
                            month: _month,
                            limitAmount: limit,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('錯誤：$e'),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
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