import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import '../adminScreens/AdminHome.dart'; 

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // --- Color Palette based on the image and request ---
  static const Color _cardColor = Color(0xFF5C8A94);
  static const Color _darkBackground = Colors.white; 
  static const Color _primaryText = Colors.black;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  
  // Fixed admin email
  final String _adminEmail = 'admin@mealmuse.com';

  // Reusable text field builder for consistent styling
  Widget _buildPasswordField({
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: TextStyle(color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87),
        decoration: InputDecoration(
          hintText: TranslationHelper.t('Admin Password', 'ایڈمن پاس ورڈ'),
          hintStyle: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          prefixIcon: Icon(Icons.lock_outline, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF3A3A3A) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        ),
      ),
    );
  }

  Future<void> _loginAdmin(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Firebase authentication with fixed admin email
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _passwordController.text.trim(),
      );

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Navigate to admin screen and clear all previous routes
      if (userCredential.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminApp()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Handle errors
      String errorMessage = TranslationHelper.t('An error occurred', 'ایک خرابی پیش آگئی');
      if (e.code == 'user-not-found') {
        errorMessage = TranslationHelper.t('Admin account not found.', 'ایڈمن اکاؤنٹ نہیں ملا۔');
      } else if (e.code == 'wrong-password') {
        errorMessage = TranslationHelper.t('Wrong admin password.', 'غلط ایڈمن پاس ورڈ۔');
      } else if (e.code == 'invalid-email') {
        errorMessage = TranslationHelper.t('Invalid admin email configuration.', 'غلط ایڈمن ای میل ترتیب۔');
      }

      // Show error dialog
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
      final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: dialogBg,
            title: Text(TranslationHelper.t('Admin Login Failed', 'ایڈمن لاگ اِن ناکام ہوا'), style: TextStyle(color: textColor)),
            content: Text(errorMessage, style: TextStyle(color: textColor)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Dismiss loading indicator
      Navigator.of(context).pop();
      
      // Show generic error
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
      final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: dialogBg,
            title: Text(TranslationHelper.t('Error', 'خرابی'), style: TextStyle(color: textColor)),
            content: Text("${TranslationHelper.t('An unexpected error occurred', 'غیر متوقع خرابی پیش آگئی')}: $e", style: TextStyle(color: textColor)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : _darkBackground;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : _primaryText;
    final secondaryTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: ValueListenableBuilder<Locale?>(
        valueListenable: LocaleProvider().localeNotifier,
        builder: (context, locale, _) {
          return SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Section: Form Card ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: size.height * 0.15,
                left: 30,
                right: 30,
                bottom: 80, 
              ),
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50.0),
                  bottomRight: Radius.circular(50.0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display admin email (read-only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationHelper.t('Admin Email', 'ایڈمن ای میل'),
                                style: TextStyle(
                                  color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _adminEmail,
                                style: TextStyle(
                                  color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password field
                  _buildPasswordField(isDarkMode: isDarkMode),
                ],
              ),
            ),

            // --- Bottom Section: Logo, Title, Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Placeholder for the Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.blue,
                        size: 60,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    TranslationHelper.t('Admin Portal', 'ایڈمن پورٹل'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    TranslationHelper.t('Secure Admin Access', 'محفوظ ایڈمن رسائی'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Admin Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_passwordController.text.isEmpty) {
                          final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
                          final dialogTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: dialogBg,
                                title: Text(TranslationHelper.t('Password Required', 'پاس ورڈ درکار ہے'), style: TextStyle(color: dialogTextColor)),
                                content: Text(TranslationHelper.t('Please enter admin password.', 'براہ کرم ایڈمن پاس ورڈ درج کریں۔'), style: TextStyle(color: dialogTextColor)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _loginAdmin(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardColor,
                        foregroundColor: _darkBackground,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TranslationHelper.t('Admin Login', 'ایڈمن لاگ اِن'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.admin_panel_settings),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Security notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            TranslationHelper.t(
                              'Restricted access. Authorized personnel only.',
                              'محدود رسائی۔ صرف مجاز عملے کے لیے۔'
                            ),
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}