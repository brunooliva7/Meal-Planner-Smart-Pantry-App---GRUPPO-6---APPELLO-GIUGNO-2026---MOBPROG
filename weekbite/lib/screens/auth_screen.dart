import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final _formKey = GlobalKey<FormState>(); // 🟢 Aggiunto per far funzionare i controlli TextFormField
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

  // ==========================================================
  // 🔐 LOGICA DI REGISTRAZIONE MANUALE (SQLITE)
  // ==========================================================
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

      // 🟢 CORRETTO: Inserisce i dati e prende subito il VERO ID di SQLite!
      int newUserId = await db.insert('users', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text, 
        'nickname': _emailController.text.trim().split('@').first,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_uid', newUserId.toString());

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Errore registrazione: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================================
  // 🔐 LOGICA DI LOGIN MANUALE (SQLITE)
  // ==========================================================
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

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar("Email o password errati!", isError: true);
      }
    } catch (e) {
      print("Errore login: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================================
  // 🌐 LOGICA DI AUTENTICAZIONE CON GOOGLE
  // ==========================================================
  Future<void> _handleGoogleAuth() async {
    setState(() => isLoading = true);
    try {
      // 🟢 Sconnette vecchie sessioni per farti scegliere l'account
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        final db = await DatabaseHelper.instance.database;
        final existingUser = await db.query('users', where: 'email = ?', whereArgs: [googleUser.email]);
        
        int sqliteId;

        // 🟢 CORRETTO: Creiamo l'utente se non esiste e usiamo SOLO l'ID di SQLite!
        if (existingUser.isEmpty) {
          sqliteId = await db.insert('users', {
            'name': googleUser.displayName ?? 'Utente Google',
            'email': googleUser.email,
            'password': 'google_auth_placeholder', 
            'nickname': googleUser.email.split('@').first,
          });
        } else {
          sqliteId = existingUser.first['id'] as int;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_uid', sqliteId.toString());

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (error) {
      print("Errore Google Sign-In: $error");
      _showSnackBar("Errore di accesso: $error", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextDark),
          onPressed: () => Navigator.pop(context, false), 
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Form( // 🟢 Aggiunto Form per validazione
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    "weekBite",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w700, color: primaryGreen, letterSpacing: -1),
                  ),
                  Text(
                    isLogin ? "Bentornato! Accedi per continuare." : "Crea il tuo account per iniziare.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 14, color: kTextMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: !isLogin
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextFormField( // 🟢 Usiamo TextFormField
                              controller: _nameController,
                              style: GoogleFonts.montserrat(),
                              decoration: _buildInputDecoration("Nome e Cognome", Icons.person_outline),
                              validator: (value) => !isLogin && (value == null || value.isEmpty) ? "Campo obbligatorio" : null,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.montserrat(),
                    decoration: _buildInputDecoration("Indirizzo Email", Icons.email_outlined),
                    validator: (value) => value == null || !value.contains('@') ? "Email non valida" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.montserrat(),
                    decoration: _buildInputDecoration(
                      "Password", 
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: kTextMuted),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Inserisci la password" : null,
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: !isLogin
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: GoogleFonts.montserrat(),
                              decoration: _buildInputDecoration(
                                "Conferma Password", 
                                Icons.lock_reset,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: kTextMuted),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : (isLogin ? _handleEmailLogin : _handleEmailRegister),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isLogin ? "Accedi" : "Registrati",
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("OPPURE", style: GoogleFonts.montserrat(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _handleGoogleAuth,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isLogin ? "Accedi con Google" : "Registrati con Google",
                                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? "Non hai un account?" : "Hai già un account?",
                        style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                        child: Text(
                          isLogin ? "Registrati ora" : "Accedi",
                          style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
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
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(color: kTextMuted),
      prefixIcon: Icon(icon, color: primaryGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      errorStyle: GoogleFonts.montserrat(fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
    );
  }
}