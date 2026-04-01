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
  bool   _loading = true;
  String? _loadError;
  String _month = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final api   = context.read<ApiService>();
      final budgets   = await api.getBudgets(month: _month);
      final categories = await api.getCategories();
      setState(() { _budgets = budgets; _categories = categories; });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // 總覽計算
  double get _totalLimit  => (_budgets ?? []).fold(0, (s, b) => s + (double.tryParse(b['limit_amount'].toString()) ?? 0));
  double get _totalSpent  => (_budgets ?? []).fold(0, (s, b) => s + (double.tryParse(b['spent'].toString()) ?? 0));
  double get _totalRemain => _totalLimit - _totalSpent;

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
          : _loadError != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: _load,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildContent(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😿', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('載入失敗，請重試', style: TextStyle(color: AppColors.textSub)),
      const SizedBox(height: 8),
      Text(_loadError!, style: const TextStyle(color: AppColors.red, fontSize: 11)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
          child: const Text('重新載入', style: TextStyle(color: Colors.white))),
    ]),
  );

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        // 標題列
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('預算管理', style: AppTextStyles.heading2),
          Text(_month, style: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),

        // 頂部總覽卡
        if (_budgets != null && _budgets!.isNotEmpty) ...[
          _buildOverviewCard(),
          const SizedBox(height: 16),
        ],

        // 預算列表
        if (_budgets == null || _budgets!.isEmpty)
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
    );
  }

  Widget _buildOverviewCard() {
    final pct = _totalLimit > 0 ? (_totalSpent / _totalLimit).clamp(0.0, 1.0) : 0.0;
    Color barColor;
    if (pct < 0.7)      barColor = AppColors.green;
    else if (pct < 0.9) barColor = AppColors.gold;
    else                barColor = AppColors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple.withOpacity(0.85), const Color(0xFF5A1FBF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('本月預算總覽', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _OverviewStat(label: '總預算', value: _totalLimit, color: Colors.white)),
          Expanded(child: _OverviewStat(label: '已花費', value: _totalSpent, color: Colors.white70)),
          Expanded(child: _OverviewStat(label: '剩餘', value: _totalRemain,
              color: _totalRemain >= 0 ? const Color(0xFF98F5A0) : const Color(0xFFFF8A80))),
        ]),
        const SizedBox(height: 14),
        // 整體進度條
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> b) {
    final spent = double.tryParse(b['spent'].toString()) ?? 0.0;
    final limit = double.tryParse(b['limit_amount'].toString()) ?? 0.0;
    final pct   = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final remain = limit - spent;

    Color barColor;
    if (pct < 0.7)      barColor = AppColors.green;
    else if (pct < 0.9) barColor = AppColors.gold;
    else                barColor = AppColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // 左上：icon + 名稱
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(b['cat_icon'] as String, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Text(b['cat_name'] as String, style: AppTextStyles.bodyBold),
          ]),
          // 右上：已花費 / 總預算
          Text(
            '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 6),
        // 右下：剩餘小字
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '剩餘 \$${remain.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, color: remain >= 0 ? AppColors.green : AppColors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  void _showAddBudgetModal() {
    if (_categories == null || _categories!.isEmpty) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('類別載入中，請稍後再試'), backgroundColor: AppColors.purple));
      return;
    }
    final expCats = _categories!.where((c) => c.type == 'expense').toList();
    if (expCats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('找不到支出類別'), backgroundColor: AppColors.red));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddBudgetSheet(
        categories: expCats,
        month: _month,
        onSuccess: () { Navigator.pop(context); _load(); },
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label; final double value; final Color color;
  const _OverviewStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Text('\$${value.toStringAsFixed(0)}',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: color)),
  ]);
}

// ══════════════════════════════════════════════
// 新增預算 Sheet
// ══════════════════════════════════════════════
class _AddBudgetSheet extends StatefulWidget {
  final List<Category> categories;
  final String month;
  final VoidCallback onSuccess;
  const _AddBudgetSheet({required this.categories, required this.month, required this.onSuccess});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  late int _selectedId;
  final _limitCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.categories.first.id;
  }

  InputDecoration _inputDeco(String label, {String? prefix}) => InputDecoration(
    labelText: label, prefixText: prefix, filled: false,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.purple, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Future<void> _submit() async {
    final limit = double.tryParse(_limitCtrl.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('請輸入有效金額'), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<ApiService>().createBudget(
        categoryId: _selectedId,
        month: widget.month,
        limitAmount: limit,
      );
      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錯誤：$e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('設定預算', style: AppTextStyles.heading3),
          IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.textSub)),
        ]),
        const SizedBox(height: 16),

        DropdownButtonFormField<int>(
          value: _selectedId,
          decoration: _inputDeco('類別（支出）'),
          items: widget.categories.map((c) => DropdownMenuItem(
            value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
          onChanged: (v) => setState(() => _selectedId = v!),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _limitCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDeco('預算上限', prefix: '\$ '),
        ),
        const SizedBox(height: 18),

        SizedBox(height: 48, child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('確認設定', style: AppTextStyles.button),
        )),
        const SizedBox(height: 20),
      ]),
    );
  }
}