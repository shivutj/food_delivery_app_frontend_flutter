// lib/screens/register_screen.dart - WITH PAN/AADHAAR VERIFICATION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;
  String _selectedRole = 'customer';
  String _selectedIdType = 'pan'; // pan or aadhaar
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _phoneController.text.trim(),
      _selectedRole,
      idType: _selectedRole == 'restaurant' ? _selectedIdType : null,
      idNumber: _selectedRole == 'restaurant' ? _idNumberController.text.trim() : null,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showMessage(result['message'], Colors.green);
      
      // Navigate to OTP verification
      Navigator.pushReplacement(
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
      _showMessage(result['message'], Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateIdNumber(String? value) {
    if (_selectedRole != 'restaurant') return null;
    
    if (value == null || value.trim().isEmpty) {
      return 'ID is required for restaurant owners';
    }

    final trimmed = value.trim().toUpperCase();

    if (_selectedIdType == 'pan') {
      // PAN format: ABCDE1234F
      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
      if (!panRegex.hasMatch(trimmed)) {
        return 'Invalid PAN format (e.g., ABCDE1234F)';
      }
    } else {
      // Aadhaar format: 12 digits
      final aadhaarRegex = RegExp(r'^[0-9]{12}$');
      if (!aadhaarRegex.hasMatch(value.trim())) {
        return 'Aadhaar must be 12 digits';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Register',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10 digits',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    hintText: 'At least 6 characters',
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'customer',
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Customer'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'restaurant',
                          child: Row(
                            children: [
                              Icon(Icons.restaurant, color: Colors.blue),
                              SizedBox(width: 12),
                              Text('Restaurant Owner'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                      },
                    ),
                  ),
                ),

                // ✅ ID VERIFICATION FOR RESTAURANT OWNERS
                if (_selectedRole == 'restaurant') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ID Verification Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Restaurant owners must verify their identity with PAN or Aadhaar',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ID Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('PAN Card'),
                          value: 'pan',
                          groupValue: _selectedIdType,
                          onChanged: (value) {
                            setState(() {
                              _selectedIdType = value!;
                              _idNumberController.clear();
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Aadhaar'),
                          value: 'aadhaar',
                          groupValue: _selectedIdType,
                          onChanged: (value) {
                            setState(() {
                              _selectedIdType = value!;
                              _idNumberController.clear();
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ID Number Input
                  TextFormField(
                    controller: _idNumberController,
                    decoration: InputDecoration(
                      labelText: _selectedIdType == 'pan' ? 'PAN Number' : 'Aadhaar Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.credit_card),
                      hintText: _selectedIdType == 'pan' ? 'ABCDE1234F' : '123456789012',
                    ),
                    textCapitalization: _selectedIdType == 'pan' 
                        ? TextCapitalization.characters 
                        : TextCapitalization.none,
                    maxLength: _selectedIdType == 'pan' ? 10 : 12,
                    inputFormatters: _selectedIdType == 'pan'
                        ? [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              return newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                              );
                            }),
                          ]
                        : [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateIdNumber,
                  ),
                ],

                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
}