// frontend/lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginUsernameCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Register controllers
  final _regUsernameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regPassword2Ctrl = TextEditingController();

  bool _loginPassVisible = false;
  bool _regPassVisible = false;
  bool _regPass2Visible = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMsg = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regPassword2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);

    final auth = context.read<AuthService>();
    final error = await auth.login(
      username: _loginUsernameCtrl.text.trim(),
      password: _loginPasswordCtrl.text,
    );
    if (error != null && mounted) {
      setState(() => _errorMsg = error);
    }
  }

  Future<void> _doRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);

    final auth = context.read<AuthService>();
    final error = await auth.register(
      username: _regUsernameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPasswordCtrl.text,
      password2: _regPassword2Ctrl.text,
    );
    if (error != null && mounted) {
      setState(() => _errorMsg = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // ── Logo ──
                _buildLogo(),
                const SizedBox(height: 36),

                // ── Card ──
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.modal),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Column(
                    children: [
                      // Tab Bar
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.border, width: 1)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.purple,
                          indicatorWeight: 3,
                          labelColor: AppColors.purple,
                          unselectedLabelColor: AppColors.textSub,
                          labelStyle: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 15),
                          tabs: const [
                            Tab(text: '登入'),
                            Tab(text: '註冊'),
                          ],
                        ),
                      ),

                      // Error banner
                      if (_errorMsg != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          decoration: BoxDecoration(
                            color: AppColors.redLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),

                      // Tab content
                      SizedBox(
                        height: _tabController.index == 0 ? 320 : 440,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLoginForm(auth),
                            _buildRegisterForm(auth),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // 扭蛋機動畫圖示
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.card,
            ),
            child: const Center(
              child: Text('🎰', style: TextStyle(fontSize: 48)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CoinNeko',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '記帳的同時 順便抽可愛傳奇貓咪圖鑑',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthService auth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AppTextField(
              controller: _loginUsernameCtrl,
              label: '帳號',
              hint: '請輸入帳號',
              prefixIcon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? '請輸入帳號' : null,
            ),
            const SizedBox(height: 14),
            _AppTextField(
              controller: _loginPasswordCtrl,
              label: '密碼',
              hint: '請輸入密碼',
              prefixIcon: Icons.lock_outline,
              obscureText: !_loginPassVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _loginPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSub,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _loginPassVisible = !_loginPassVisible),
              ),
              validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
            ),
            const Spacer(),
            _AppButton(
              label: '登入',
              isLoading: auth.isLoading,
              onPressed: _doLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AuthService auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AppTextField(
              controller: _regUsernameCtrl,
              label: '帳號',
              hint: '請設定帳號（英數字）',
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v!.isEmpty) return '請輸入帳號';
                if (v.length < 3) return '帳號至少 3 個字元';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AppTextField(
              controller: _regEmailCtrl,
              label: 'Email（可以不用填）',
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _AppTextField(
              controller: _regPasswordCtrl,
              label: '密碼',
              hint: '至少 6 個字元',
              prefixIcon: Icons.lock_outline,
              obscureText: !_regPassVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _regPassVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSub,
                  size: 20,
                ),
                onPressed: () => setState(() => _regPassVisible = !_regPassVisible),
              ),
              validator: (v) {
                if (v!.isEmpty) return '請輸入密碼';
                if (v.length < 6) return '密碼至少 6 個字元';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AppTextField(
              controller: _regPassword2Ctrl,
              label: '確認密碼',
              hint: '再輸入一次密碼',
              prefixIcon: Icons.lock_outline,
              obscureText: !_regPass2Visible,
              suffixIcon: IconButton(
                icon: Icon(
                  _regPass2Visible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSub,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _regPass2Visible = !_regPass2Visible),
              ),
              validator: (v) {
                if (v!.isEmpty) return '請再次輸入密碼';
                if (v != _regPasswordCtrl.text) return '兩次密碼不一致';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _AppButton(
              label: '建立帳號',
              isLoading: auth.isLoading,
              onPressed: _doRegister,
            ),
            const SizedBox(height: 8),
            const Text(
              '🎟️ 註冊即送 10 張扭蛋券',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HintBadge(emoji: '🪙', text: '記帳 +10 金幣'),
            SizedBox(width: 8),
            _HintBadge(emoji: '🎟️', text: '每日首筆記帳 +1 扭蛋券'),
          ],
        ),
        SizedBox(height: 8),
        _HintBadge(emoji: '🐱', text: '一起收集可愛貓咪圖鑑吧！'),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 共用小元件
// ──────────────────────────────────────────────

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.text, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: AppColors.purple, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color? color;

  const _AppButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: AppTextStyles.button),
      ),
    );
  }
}

class _HintBadge extends StatelessWidget {
  final String emoji;
  final String text;

  const _HintBadge({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purpleLight,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        '$emoji $text',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.purple,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}