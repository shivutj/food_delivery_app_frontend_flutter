// lib/screens/login_screen.dart - WITH GRADIENT BACKGROUND
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';
import 'restaurant_dashboard.dart';
import 'otp_verification_screen.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'customer';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isLogin) {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        final user = result['user'];
        
        if (!mounted) return;
        
        if (user.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (user.role == 'restaurant') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RestaurantDashboard(user: user)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
          );
        }
      } else {
        if (result['requiresOTP'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                userId: result['userId'],
                email: _emailController.text.trim(),
              ),
            ),
          );
        } else {
          _showSnackBar(result['message'], Colors.red);
        }
      }
    } else {
      final result = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
        _selectedRole,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              userId: result['userId'],
              email: _emailController.text.trim(),
              otp: result['otp'],
            ),
          ),
        );
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
            ? themeProvider.darkGradient 
            : themeProvider.lightGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme Toggle Button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),

              // Main Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_menu,
                                    size: 64, color: Colors.green.shade700),
                                const SizedBox(height: 24),

                                Text(
                                  _isLogin ? 'Welcome Back' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (!_isLogin)
                                  _field(_nameController, 'Name', Icons.person),

                                _field(
                                  _emailController,
                                  'Email',
                                  Icons.email,
                                  type: TextInputType.emailAddress,
                                ),

                                if (!_isLogin)
                                  _field(
                                    _phoneController,
                                    'Phone',
                                    Icons.phone,
                                    type: TextInputType.phone,
                                    max: 10,
                                  ),

                                _field(
                                  _passwordController,
                                  'Password',
                                  Icons.lock,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),

                                if (!_isLogin) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedRole,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'customer',
                                          child: Text('Customer'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'restaurant',
                                          child: Text('Restaurant Owner'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRole = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            _isLogin ? 'Login' : 'Register',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),

                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _selectedRole = 'customer';
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Create account'
                                        : 'Already have account',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
    int? max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        maxLength: max,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}