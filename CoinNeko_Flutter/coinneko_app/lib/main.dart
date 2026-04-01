// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'providers/collection_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';


void main() {
  runApp(const CoinNekoApp());
}

class CoinNekoApp extends StatelessWidget {
  const CoinNekoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..tryAutoLogin(),
      child: Builder(
        builder: (context) {
          final authService = context.read<AuthService>();
          final apiService = ApiService(authService);

          return MultiProvider(
            providers: [
              Provider<ApiService>.value(value: apiService),
              ChangeNotifierProvider<CollectionProvider>(
                create: (_) => CollectionProvider(apiService),
              ),
            ],
            child: MaterialApp(
              title: 'CoinNeko 記帳貓',
              theme: AppTheme.theme,
              debugShowCheckedModeBanner: false,
              home: const _RootNavigator(),
              routes: {
                '/collection': (context) => const CollectionScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🐱', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppColors.purple),
            ],
          ),
        ),
      );
    }

    return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}