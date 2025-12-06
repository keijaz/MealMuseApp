import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const Color _cardColor = Color(0xFF5C8A94);
  static const Color _black = Colors.black;
  static const Color _primaryText = Colors.white;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Check if username is unique
  Future<bool> _isUsernameUnique(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking username uniqueness: $e");
      return false;
    }
  }

  // Save user data to Firestore and create subcollections
  Future<void> _saveUserToFirestore(User user, String username) async {
    try {
      // Create the main user document
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': username.toLowerCase(),
        'displayName': username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Create empty inventory subcollection with a default document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc('default')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'items': [], // Empty array to store inventory items
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      // Create empty saved_recipes subcollection with a default document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc('default')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'recipes': [], // Empty array to store saved recipe IDs or data
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      print("User data and subcollections created successfully");
    } catch (e) {
      print("Error saving user to Firestore: $e");
      rethrow;
    }
  }

  // Password validation function
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return TranslationHelper.t('Password must be at least 6 characters long', 'پاس ورڈ کم از کم 6 حروف طویل ہونا چاہیے');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return TranslationHelper.t('Password must contain at least one number', 'پاس ورڈ میں کم از کم ایک عدد ہونا چاہیے');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return TranslationHelper.t('Password must contain at least one special character', 'پاس ورڈ میں کم از کم ایک خاص حرف ہونا چاہیے');
    }
    return null;
  }

  // Username validation function
  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return TranslationHelper.t('Username is required', 'صارف نام ضروری ہے');
    }
    if (username.length < 3) {
      return TranslationHelper.t('Username must be at least 3 characters long', 'صارف نام کم از کم 3 حروف پر مشتمل ہونا چاہیے');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return TranslationHelper.t('Username can only contain letters, numbers, and underscores', 'صارف نام میں صرف حروف، اعداد، اور انڈر اسکور شامل ہو سکتے ہیں');
    }
    if (username.length > 20) {
      return TranslationHelper.t('Username cannot exceed 20 characters', 'صارف نام 20 حروف سے زیادہ نہیں ہو سکتا');
    }
    return null;
  }

  // Reusable text field builder for consistent styling
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
    VoidCallback? onChanged,
    required bool isDarkMode,
    bool? isPasswordVisible,
    VoidCallback? onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        style: TextStyle(color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87),
        onChanged: (value) {
          if (onChanged != null) {
            onChanged();
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          prefixIcon: Icon(icon, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: IconButton(
                    icon: Icon(
                      (isPasswordVisible ?? false) ? Icons.visibility : Icons.visibility_off,
                      color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
                    ),
                    onPressed: onToggleVisibility,
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

  Future<void> _registerUser(BuildContext context) async {
    // Validate all fields are filled
    if (_emailController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog(
        context,
        TranslationHelper.t('Missing Information', 'معلومات غائب ہیں'),
        TranslationHelper.t('Please fill in all fields.', 'براہ کرم تمام خانے پُر کریں۔'),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorDialog(
        context,
        TranslationHelper.t('Invalid Email', 'غلط ای میل'),
        TranslationHelper.t('Please enter a valid email address.', 'براہ کرم درست ای میل پتہ درج کریں۔'),
      );
      return;
    }

    // Validate username format
    final usernameError = _validateUsername(_usernameController.text.trim());
    if (usernameError != null) {
      _showErrorDialog(
        context,
        TranslationHelper.t('Invalid Username', 'غلط صارف نام'),
        usernameError,
      );
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(
        context,
        TranslationHelper.t('Password Mismatch', 'پاس ورڈ میں عدم مطابقت'),
        TranslationHelper.t('Passwords do not match. Please try again.', 'پاس ورڈ مماثل نہیں۔ براہ کرم دوبارہ کوشش کریں۔'),
      );
      return;
    }

    // Validate password strength
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      final reqHeader = TranslationHelper.t('Password requirements:', 'پاس ورڈ کے تقاضے:');
      final req1 = TranslationHelper.t('At least 6 characters', 'کم از کم 6 حروف');
      final req2 = TranslationHelper.t('At least one number (0-9)', 'کم از کم ایک عدد (0-9)');
      final req3 = TranslationHelper.t('At least one special character (!@#%^&* etc.)', 'کم از کم ایک خاص حرف (!@#%^&* وغیرہ)');
      _showErrorDialog(
        context,
        TranslationHelper.t('Weak Password', 'کمزور پاس ورڈ'),
        '$passwordError.\n\n$reqHeader\n• $req1\n• $req2\n• $req3',
      );
      return;
    }

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

      // Check if username is unique
      final isUnique = await _isUsernameUnique(_usernameController.text.trim());
      if (!isUnique) {
        Navigator.of(context).pop(); // Dismiss loading
        _showErrorDialog(
          context,
          TranslationHelper.t('Username Taken', 'صارف نام پہلے سے موجود ہے'),
          TranslationHelper.t('This username is already taken. Please choose a different one.', 'یہ صارف نام پہلے سے لیا جا چکا ہے۔ براہ کرم کوئی دوسرا منتخب کریں۔'),
        );
        return;
      }

      // Firebase authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user data to Firestore and create subcollections
      await _saveUserToFirestore(
        userCredential.user!, 
        _usernameController.text.trim()
      );

      // Optional: Update user display name in Auth
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(_usernameController.text.trim());
        } catch (e) {
          print("Error updating display name: $e");
          // Continue even if display name update fails
        }
      }

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message and navigate to login
      _showSuccessDialog(context);
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Handle errors
      String errorMessage = TranslationHelper.t('An error occurred during registration', 'رجسٹریشن کے دوران خرابی پیش آگئی');
      if (e.code == 'weak-password') {
        errorMessage = TranslationHelper.t('The password provided is too weak.', 'مہیا کردہ پاس ورڈ بہت کمزور ہے۔');
      } else if (e.code == 'email-already-in-use') {
        errorMessage = TranslationHelper.t('An account already exists for that email.', 'اس ای میل کے لیے اکاؤنٹ پہلے سے موجود ہے۔');
      } else if (e.code == 'invalid-email') {
        errorMessage = TranslationHelper.t('The email address is not valid.', 'ای میل پتہ درست نہیں ہے۔');
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = TranslationHelper.t('Email/password accounts are not enabled.', 'ای میل/پاس ورڈ اکاؤنٹس فعال نہیں ہیں۔');
      }

      _showErrorDialog(
        context,
        TranslationHelper.t('Registration Failed', 'رجسٹریشن ناکام ہوگئی'),
        errorMessage,
      );
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show generic error
      _showErrorDialog(
        context,
        TranslationHelper.t('Error', 'خرابی'),
        '${TranslationHelper.t('An unexpected error occurred', 'غیر متوقع خرابی پیش آگئی')}: $e',
      );
    }
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Text(content, style: TextStyle(color: textColor)),
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

  void _showSuccessDialog(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(TranslationHelper.t('Registration Successful', 'رجسٹریشن کامیاب'), style: TextStyle(color: textColor)), 
          content: Text(TranslationHelper.t('Your account has been created successfully!', 'آپ کا اکاؤنٹ کامیابی سے بنا دیا گیا ہے!'), style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ));
              },
              child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
            ),
          ],
        );
      },
    );
  }

  // Widget to show password requirements
  Widget _buildPasswordRequirements(Color textColor) {
    final password = _passwordController.text;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.t('Password must contain:', 'پاس ورڈ میں شامل ہونا چاہیے:'),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildRequirementLine(TranslationHelper.t('At least 6 characters', 'کم از کم 6 حروف'), password.length >= 6),
          _buildRequirementLine(TranslationHelper.t('At least one number', 'کم از کم ایک عدد'), RegExp(r'[0-9]').hasMatch(password)),
          _buildRequirementLine(TranslationHelper.t('At least one special character', 'کم از کم ایک خاص حرف'), 
              RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
        ],
      ),
    );
  }

  // Widget to show username requirements
  // Widget _buildUsernameRequirements() {
  //   final username = _usernameController.text;
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Username requirements:',
  //           style: TextStyle(
  //             color: _primaryText.withOpacity(0.8),
  //             fontSize: 12,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         _buildRequirementLine('3-20 characters', username.length >= 3 && username.length <= 20),
  //         _buildRequirementLine('Letters, numbers, underscores only', 
  //             username.isEmpty || RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRequirementLine(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? Colors.green : Colors.grey,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : _primaryText;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : _black;
    final secondaryTextColor = isDarkMode ? const Color(0xFFB0B0B0) : _primaryText.withOpacity(0.8);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: ValueListenableBuilder<Locale?>(
        valueListenable: LocaleProvider().localeNotifier,
        builder: (context, locale, _) {
          return SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Section: Logo and Title ---
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.1,
                left: 30.0,
                right: 30.0,
                bottom: 30.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 10),
                  Text(
                    TranslationHelper.t('Lets Create\nYour Account!', 'چلیں\nآپ کا اکاؤنٹ بنائیں!'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: size.width * 0.09,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // --- Bottom Section: Form Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                left: 30,
                right: 30,
                bottom: 50,
              ),
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
              ),
              child: Column(
                children: [
                  // Text Fields
                  _buildTextField(
                    hintText: TranslationHelper.t('Email', 'ای میل'), 
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    isDarkMode: isDarkMode,
                  ),
                  _buildTextField(
                    hintText: TranslationHelper.t('Username', 'صارف نام'), 
                    icon: Icons.person_outline,
                    controller: _usernameController,
                    onChanged: () => setState(() {}), // Trigger rebuild when username changes
                    isDarkMode: isDarkMode,
                  ),
                  // Username requirements
                  // _buildUsernameRequirements(),
                  _buildTextField(
                    hintText: TranslationHelper.t('Password', 'پاس ورڈ'), 
                    icon: Icons.lock_outline, 
                    isPassword: true,
                    controller: _passwordController,
                    onChanged: () => setState(() {}), // Trigger rebuild when password changes
                    isDarkMode: isDarkMode,
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  // Password requirements
                  _buildPasswordRequirements(secondaryTextColor),
                  _buildTextField(
                    hintText: TranslationHelper.t('Retype Password', 'پاس ورڈ دوبارہ لکھیں'), 
                    icon: Icons.lock_outline, 
                    isPassword: true,
                    controller: _confirmPasswordController,
                    onChanged: () => setState(() {}), // Trigger rebuild when confirm password changes
                    isDarkMode: isDarkMode,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _registerUser(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryText,
                        foregroundColor: _black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        TranslationHelper.t('Register', 'رجسٹر کریں'),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // "Sign In" link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: TranslationHelper.t('Already have an account? ', 'پہلے سے اکاؤنٹ موجود ہے؟ '),
                        style: TextStyle(color: secondaryTextColor, fontSize: 16),
                        children: <TextSpan>[
                          TextSpan(
                            text: TranslationHelper.t('Sign In', 'سائن اِن'),
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFFE1E1E1) : _primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}