import 'package:flutter/material.dart';
import 'register.dart'; 
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import '../adminScreens/AdminHome.dart'; // Make sure to import the AdminApp screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Color Palette based on the image and request ---
  static const Color _cardColor = Color(0xFF5C8A94);
  static const Color _darkBackground = Colors.white; 
  static const Color _primaryText = Colors.black;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Reusable text field builder for consistent styling
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          prefixIcon: Icon(icon, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          suffixIcon: isPassword
              ? Padding(
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
                )
              : null,
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

  Future<void> _loginUser(BuildContext context) async {
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

      // Firebase authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Navigate to appropriate screen based on user email
      if (userCredential.user != null) {
        final userEmail = userCredential.user!.email?.toLowerCase().trim();
        
        if (userEmail == 'admin@mealmuse.com') {
          // Navigate to admin screen and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminApp()),
            (Route<dynamic> route) => false,
          );
        } else {
          // Navigate to regular home screen and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainHomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Handle errors
      String errorMessage = TranslationHelper.t('An error occurred', 'ایک خرابی پیش آگئی');
      if (e.code == 'user-not-found') {
        errorMessage = TranslationHelper.t('No user found for that email.', 'اس ای میل کے لیے کوئی صارف نہیں ملا۔');
      } else if (e.code == 'wrong-password') {
        errorMessage = TranslationHelper.t('Wrong password provided.', 'غلط پاس ورڈ درج کیا گیا۔');
      } else if (e.code == 'invalid-email') {
        errorMessage = TranslationHelper.t('Invalid email address.', 'غلط ای میل ایڈریس۔');
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
            title: Text(TranslationHelper.t('Login Failed', 'لاگ اِن ناکام ہوا'), style: TextStyle(color: textColor)),
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

  void _showForgotPasswordDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final fieldBg = isDarkMode ? const Color(0xFF3A3A3A) : Colors.white;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(TranslationHelper.t('Reset Password', 'پاس ورڈ ری سیٹ کریں'), style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(TranslationHelper.t("Enter your email address and we'll send you a password reset link.", 'اپنا ای میل پتہ درج کریں، ہم آپ کو پاس ورڈ ری سیٹ لنک بھیجیں گے۔'), style: TextStyle(color: textColor)),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: TranslationHelper.t('Email', 'ای میل'),
                  labelStyle: TextStyle(color: textColor),
                  hintText: TranslationHelper.t('Enter your email', 'اپنا ای میل درج کریں'),
                  hintStyle: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: fieldBg,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(TranslationHelper.t('Cancel', 'منسوخ کریں')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(TranslationHelper.t('Please enter your email address', 'براہ کرم اپنا ای میل پتہ درج کریں'))),
                  );
                  return;
                }
                
                await _sendPasswordResetEmail(context, emailController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cardColor,
              ),
              child: Text(TranslationHelper.t('Send Link', 'لنک بھیجیں'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail(BuildContext context, String email) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      await _auth.sendPasswordResetEmail(email: email);
      
      // Dismiss loading and dialog
      Navigator.of(context).pop(); // Dismiss loading
      Navigator.of(context).pop(); // Dismiss dialog
      
      // Show success message
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
      final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: dialogBg,
            title: Text(TranslationHelper.t('Email Sent', 'ای میل بھیج دی گئی'), style: TextStyle(color: textColor)),
            content: Text("${TranslationHelper.t('Password reset link has been sent to', 'پاس ورڈ ری سیٹ لنک اس ای میل پر بھیج دیا گیا ہے')}: $email. ${TranslationHelper.t('Please check your inbox.', 'براہ کرم اپنے ان باکس کو چیک کریں۔')}", style: TextStyle(color: textColor)) ,
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
      
    } on FirebaseAuthException catch (e) {
      // Dismiss loading
      Navigator.of(context).pop();
      
      String errorMessage = TranslationHelper.t('Failed to send reset email. Please try again.', 'ری سیٹ ای میل بھیجنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔');
      if (e.code == 'user-not-found') {
        errorMessage = TranslationHelper.t('No account found with this email address.', 'اس ای میل پتے کے ساتھ کوئی اکاؤنٹ نہیں ملا۔');
      } else if (e.code == 'invalid-email') {
        errorMessage = TranslationHelper.t('Please enter a valid email address.', 'براہ کرم درست ای میل پتہ درج کریں۔');
      } else if (e.code == 'too-many-requests') {
        errorMessage = TranslationHelper.t('Too many attempts. Please try again later.', 'بہت زیادہ کوششیں۔ براہ کرم بعد میں دوبارہ کوشش کریں۔');
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Dismiss loading
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${TranslationHelper.t('An error occurred', 'ایک خرابی پیش آگئی')}: $e"),
          backgroundColor: Colors.red,
        ),
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
                  // Text Fields
                  _buildTextField(
                    hintText: TranslationHelper.t('Email', 'ای میل'), 
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    isDarkMode: isDarkMode,
                  ),
                  _buildTextField(
                    hintText: TranslationHelper.t('Password', 'پاس ورڈ'), 
                    icon: Icons.lock_outline, 
                    isPassword: true,
                    controller: _passwordController,
                    isDarkMode: isDarkMode,
                  ),
                  
                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog(context);
                      },
                      child: Text(
                        TranslationHelper.t('Forgot Password?', 'پاس ورڈ بھول گئے؟'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Bottom Section: Logo, Title, Button, and Sign Up Link ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Placeholder for the Logo (Pasta/Tomatoes image)
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.red,
                        size: 60,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    TranslationHelper.t('Lets Start\nCooking!', 'چلیں\nپکانا شروع کریں!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: size.width * 0.09,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                          final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
                          final dialogTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: dialogBg,
                                title: Text(TranslationHelper.t('Missing Information', 'معلومات غائب ہیں'), style: TextStyle(color: dialogTextColor)),
                                content: Text(TranslationHelper.t('Please enter both email and password.', 'براہ کرم ای میل اور پاس ورڈ دونوں درج کریں۔'), style: TextStyle(color: dialogTextColor)),
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
                          _loginUser(context);
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
                            TranslationHelper.t('Login', 'لاگ اِن'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // "Sign up" link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const RegistrationScreen(),
                      ));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: TranslationHelper.t('Dont have an account? ', 'اکاؤنٹ نہیں ہے؟ '),
                        style: TextStyle(color: secondaryTextColor, fontSize: 16),
                        children: <TextSpan>[
                          TextSpan(
                            text: TranslationHelper.t('Sign up', 'سائن اپ'),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}