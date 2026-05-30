import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E);
const Color kTextMuted = Color(0xFF9CA3AF);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true; 

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Le password non coincidono!", isError: true);
      return;
    }
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final existingUser = await db.query('users', where: 'email = ?', whereArgs: [_emailController.text.trim()]);
      
      if (existingUser.isNotEmpty) {
        _showSnackBar("Questa email è già registrata!", isError: true);
        setState(() => isLoading = false);
        return;
      }

      int newUserId = await db.insert('users', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text, 
        'nickname': _emailController.text.trim().split('@').first,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_uid', newUserId.toString());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print("Errore registrazione: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final userQuery = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [_emailController.text.trim(), _passwordController.text],
      );

      if (userQuery.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_uid', userQuery.first['id'].toString());
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar("Email o password errati!", isError: true);
      }
    } catch (e) {
      print("Errore login: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark), onPressed: () => Navigator.pop(context, false))),
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: primaryGreen),
                  const SizedBox(height: 16),
                  Text("weekBite", textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w700, color: primaryGreen, letterSpacing: -1)),
                  const SizedBox(height: 40),
                  if (!isLogin) TextFormField(controller: _nameController, decoration: _buildInputDecoration("Nome e Cognome", Icons.person_outline), validator: (v) => !isLogin && (v == null || v.isEmpty) ? "Campo obbligatorio" : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emailController, decoration: _buildInputDecoration("Indirizzo Email", Icons.email_outlined), validator: (v) => v == null || !v.contains('@') ? "Email non valida" : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _passwordController, obscureText: _obscurePassword, decoration: _buildInputDecoration("Password", Icons.lock_outline, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: kTextMuted), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(controller: _confirmPasswordController, obscureText: _obscureConfirm, decoration: _buildInputDecoration("Conferma Password", Icons.lock_reset, suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: kTextMuted), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)))),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : (isLogin ? _handleEmailLogin : _handleEmailRegister),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text(isLogin ? "Accedi" : "Registrati", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? "Non hai un account?" : "Hai già un account?"),
                      TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Registrati" : "Accedi", style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: primaryGreen), suffixIcon: suffixIcon, filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
  }
}