// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'gacha_screen.dart';
import 'collection_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    GachaScreen(),
    CollectionScreen(),
    BudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🐱 CoinNeko'),
            const Spacer(),
            // 金幣顯示
            _CurrencyBadge(emoji: '🪙', value: user.coins),
            const SizedBox(width: 8),
            // 扭蛋券顯示
            _CurrencyBadge(emoji: '🎟️', value: user.gachaTickets),
            const SizedBox(width: 8),
            // 登出
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                await context.read<AuthService>().logout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: '總覽'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: '記帳'),
          BottomNavigationBarItem(icon: Icon(Icons.casino_outlined), label: '扭蛋'),
          BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), label: '圖鑑'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), label: '預算'),
        ],
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final String emoji;
  final int value;

  const _CurrencyBadge({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}