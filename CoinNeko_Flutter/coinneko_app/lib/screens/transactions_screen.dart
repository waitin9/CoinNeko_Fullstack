// frontend/lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction>? _transactions;
  List<Category>?   _categories;
  bool   _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final api = context.read<ApiService>();
      final txs  = await api.getTransactions();
      final cats = await api.getCategories();
      setState(() { _transactions = txs; _categories = cats; });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddModal() {
    if (_categories == null || _categories!.isEmpty) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('類別載入中，請稍後再試'),
        backgroundColor: AppColors.purple,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTransactionSheet(
        categories: _categories!,
        onSuccess: (coinsEarned, ticketEarned, updatedUser) {
          context.read<AuthService>().updateUser(updatedUser);
          _load();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '記帳成功！+$coinsEarned 🪙'
              '${ticketEarned > 0 ? " +1 🎟️ 今日首筆獎勵！" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
  }

  // 把清單按日期分組
  Map<String, List<Transaction>> _grouped() {
    final map = <String, List<Transaction>>{};
    for (final tx in (_transactions ?? [])) {
      final d = tx.transactedAt;
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      map.putIfAbsent(key, () => []).add(tx);
    }
    // 按日期降序
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  String _dayLabel(String key) {
    final dt = DateTime.parse(key);
    const weekdays = ['一','二','三','四','五','六','日'];
    return '${dt.month}月${dt.day}日  星期${weekdays[dt.weekday - 1]}';
  }

  // 計算總覽
  double get _totalIncome  => (_transactions ?? []).where((t) => t.catType == 'income').fold(0, (s, t) => s + t.amount);
  double get _totalExpense => (_transactions ?? []).where((t) => t.catType == 'expense').fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
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
                      child: _buildList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😿', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('載入失敗，請下拉重試', style: TextStyle(color: AppColors.textSub)),
      const SizedBox(height: 8),
      Text(_loadError!, style: const TextStyle(color: AppColors.red, fontSize: 11)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
        child: const Text('重新載入', style: TextStyle(color: Colors.white))),
    ]),
  );

  Widget _buildList() {
    if (_transactions == null || _transactions!.isEmpty) {
      return const Center(child: Text('還沒有記帳紀錄\n點下方 + 開始記帳 🐱',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSub, height: 1.8)));
    }

    final grouped = _grouped();
    final children = <Widget>[];

    // 頂部總覽卡
    children.add(_buildSummaryCard());
    children.add(const SizedBox(height: 16));

    // 按日期分組列表
    for (final entry in grouped.entries) {
      children.add(_buildDateHeader(entry.key));
      for (final tx in entry.value) {
        children.add(_buildTxTile(tx));
      }
      children.add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: children,
    );
  }

  Widget _buildSummaryCard() {
    final balance = _totalIncome - _totalExpense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(children: [
        Expanded(child: _SummaryItem(label: '本月收入', value: _totalIncome,  color: AppColors.green)),
        _divider(),
        Expanded(child: _SummaryItem(label: '本月支出', value: _totalExpense, color: AppColors.red)),
        _divider(),
        Expanded(child: _SummaryItem(label: '結餘',     value: balance,       color: AppColors.purple)),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.border);

  Widget _buildDateHeader(String key) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(_dayLabel(key),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
            letterSpacing: 0.4,
          )),
    );
  }

  Widget _buildTxTile(Transaction tx) {
    final isIncome = tx.catType == 'income';
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('刪除紀錄？'),
            content: const Text('此操作無法復原。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('刪除', style: TextStyle(color: AppColors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        await context.read<ApiService>().deleteTransaction(tx.id);
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          // 圓形 icon 容器
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isIncome ? AppColors.greenLight : AppColors.redLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(tx.catIcon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.catName, style: AppTextStyles.bodyBold),
            if (tx.note.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(tx.note, style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                  overflow: TextOverflow.ellipsis),
            ],
          ])),
          // 金額（放大加粗）
          Text(
            '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: isIncome ? AppColors.green : AppColors.red,
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w600)),
    const SizedBox(height: 5),
    Text('\$${value.toStringAsFixed(0)}',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
  ]);
}

// ══════════════════════════════════════════════
// 新增記帳 Sheet
// ══════════════════════════════════════════════
class _AddTransactionSheet extends StatefulWidget {
  final List<Category> categories;
  final Function(int coinsEarned, int ticketEarned, UserModel user) onSuccess;
  const _AddTransactionSheet({required this.categories, required this.onSuccess});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  String _type = 'expense';
  late int _selectedCategoryId;
  late DateTime _selectedDate;
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    final filtered = _filtered();
    if (filtered.isNotEmpty) _selectedCategoryId = filtered.first.id;
  }

  List<Category> _filtered() =>
      widget.categories.where((c) => c.type == _type).toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.purple)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('請輸入有效金額'), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // 實際 API：傳入 _selectedDate，DB 儲存時使用 DateTime.now() 或指定日期
      final result = await context.read<ApiService>().createTransaction(
        categoryId: _selectedCategoryId,
        amount: amount,
        note: _noteCtrl.text,
        // transactedAt: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
        //     DateTime.now().hour, DateTime.now().minute), // 示範：日期 + 當下時間
      );
      if (mounted) {
        Navigator.pop(context);
        final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
        widget.onSuccess(result['coins_earned'] as int, result['ticket_earned'] as int, user);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('錯誤：$e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 統一輸入框樣式
  InputDecoration _inputDeco(String label, {String? prefix}) => InputDecoration(
    labelText: label,
    prefixText: prefix,
    filled: false,
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    if (filtered.isEmpty) {
      return const Padding(padding: EdgeInsets.all(40),
          child: Center(child: Text('找不到類別，請重新整理後再試')));
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('新增記帳', style: AppTextStyles.heading3),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSub)),
          ]),
          const SizedBox(height: 14),

          // 支出 / 收入 切換
          Row(children: [
            Expanded(child: _TypeButton(label: '支出', selected: _type == 'expense',
                color: AppColors.red, onTap: () {
                  final exp = widget.categories.where((c) => c.type == 'expense').toList();
                  if (exp.isEmpty) return;
                  setState(() { _type = 'expense'; _selectedCategoryId = exp.first.id; });
                })),
            const SizedBox(width: 8),
            Expanded(child: _TypeButton(label: '收入', selected: _type == 'income',
                color: AppColors.green, onTap: () {
                  final inc = widget.categories.where((c) => c.type == 'income').toList();
                  if (inc.isEmpty) return;
                  setState(() { _type = 'income'; _selectedCategoryId = inc.first.id; });
                })),
          ]),
          const SizedBox(height: 14),

          // 類別下拉
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: _inputDeco('類別'),
            items: filtered.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.icon} ${c.name}'),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v!),
          ),
          const SizedBox(height: 12),

          // 金額
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDeco('金額', prefix: '\$ '),
          ),
          const SizedBox(height: 12),

          // 備註
          TextFormField(
            controller: _noteCtrl,
            decoration: _inputDeco('備註（選填）'),
          ),
          const SizedBox(height: 12),

          // 日期選擇（只選日期，不選時間）
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.purple),
                const SizedBox(width: 10),
                Text(
                  '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2,'0')}/${_selectedDate.day.toString().padLeft(2,'0')}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),

          // 確認按鈕
          SizedBox(height: 48, child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('確認記帳 +10 🪙', style: AppTextStyles.button),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color : AppColors.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppColors.textSub,
        fontWeight: FontWeight.w700,
      ))),
    ),
  );
}