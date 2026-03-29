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
  List<Category>? _categories;
  bool _loading = true;
  String? _loadError;

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
      // ★ 分開載入，避免一個失敗整個壞掉
      final transactions = await api.getTransactions();
      final categories = await api.getCategories();
      setState(() {
        _transactions = transactions;
        _categories = categories;
      });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddModal() {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTransactionSheet(
        categories: _categories!,
        onSuccess: (coinsEarned, ticketEarned, updatedUser) {
          context.read<AuthService>().updateUser(updatedUser);
          _load();
          _showSnackBar(
            '記帳成功！+$coinsEarned 🪙'
            '${ticketEarned > 0 ? " +1 🎟️ 今日首筆獎勵！" : ""}',
          );
        },
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😿', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('載入失敗，請下拉重試',
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
                  child: _transactions == null || _transactions!.isEmpty
                      ? const Center(
                          child: Text('還沒有記帳紀錄\n點下方 + 開始記帳 🐱',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSub, height: 1.8)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _transactions!.length,
                          itemBuilder: (_, i) {
                            final tx = _transactions![i];
                            return _TxItem(
                              tx: tx,
                              onDelete: () async {
                                await context
                                    .read<ApiService>()
                                    .deleteTransaction(tx.id);
                                _load();
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

class _TxItem extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onDelete;

  const _TxItem({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.catType == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Text(tx.catIcon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.catName + (tx.note.isNotEmpty ? ' · ${tx.note}' : ''),
                  style: AppTextStyles.bodyBold,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.transactedAt.year}/${tx.transactedAt.month}/${tx.transactedAt.day}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isIncome ? AppColors.green : AppColors.red,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 18, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final List<Category> categories;
  final Function(int coinsEarned, int ticketEarned, UserModel user) onSuccess;

  const _AddTransactionSheet({
    required this.categories,
    required this.onSuccess,
  });

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  String _type = 'expense';
  late int _selectedCategoryId;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final filtered = _filtered();
    // ★ 防止 filtered 是空的導致 crash
    if (filtered.isNotEmpty) {
      _selectedCategoryId = filtered.first.id;
    }
  }

  List<Category> _filtered() =>
      widget.categories.where((c) => c.type == _type).toList();

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入有效金額'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<ApiService>().createTransaction(
            categoryId: _selectedCategoryId,
            amount: amount,
            note: _noteCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
        widget.onSuccess(
          result['coins_earned'] as int,
          result['ticket_earned'] as int,
          user,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('錯誤：$e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('找不到類別，請重新整理後再試')),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
              const Text('新增記帳', style: AppTextStyles.heading3),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSub)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final exp = widget.categories
                        .where((c) => c.type == 'expense')
                        .toList();
                    if (exp.isEmpty) return;
                    setState(() {
                      _type = 'expense';
                      _selectedCategoryId = exp.first.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _type == 'expense'
                          ? AppColors.red
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('支出',
                          style: TextStyle(
                              color: _type == 'expense'
                                  ? Colors.white
                                  : AppColors.textSub,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final inc = widget.categories
                        .where((c) => c.type == 'income')
                        .toList();
                    if (inc.isEmpty) return;
                    setState(() {
                      _type = 'income';
                      _selectedCategoryId = inc.first.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _type == 'income'
                          ? AppColors.green
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('收入',
                          style: TextStyle(
                              color: _type == 'income'
                                  ? Colors.white
                                  : AppColors.textSub,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(labelText: '類別'),
            items: filtered.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text('${c.icon} ${c.name}'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: '金額', prefixText: '\$ '),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: '備註（選填）'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('確認記帳 +10 🪙',
                      style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}