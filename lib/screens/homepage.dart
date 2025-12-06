import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginScreen
import 'register.dart'; // Import the RegisterScreen
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'admin_login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Custom color from the design (5C8A94)
  static const Color primaryTeal = Color(0xFF5C8A94);
  
  // Using a network placeholder for the image since the Google Drive link
  // is not directly usable as a Flutter asset or network URL.
  // You should replace this with Image.asset('path/to/your/image.png') 
  // after adding the image to your project's assets folder.
  // 
  final String foodImage = "assets/images/logo.png";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor, // Background for the top content area
      body: ValueListenableBuilder<Locale?>(
        valueListenable: LocaleProvider().localeNotifier,
        builder: (context, locale, _) {
          return Column(
        children: [
          // === TOP SECTION (Image and Title) ===
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Image
                    // IMPORTANT: Replace Image.network with Image.asset after adding your image.
                    Image.asset(
                      foodImage,
                      height: screenHeight * 0.3,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    // Main Title
                    Text(
                      'Meal Muse',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Your go to pantry assistant!',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === BOTTOM SECTION (Buttons) ===
          Container(
            height: screenHeight * 0.45, // Increased height to accommodate the new button
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50.0), // Rounded top-left corner
                topRight: Radius.circular(50.0), // Rounded top-right corner
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Login Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to LoginScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        TranslationHelper.t('Login', 'لاگ اِن'),
                        style: TextStyle(
                          color: isDarkMode ? Colors.black : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- 'Or' Text ---
                  Text(
                    TranslationHelper.t('Or', 'یا'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- Register Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to RegisterScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        TranslationHelper.t('Register', 'رجسٹر کریں'),
                        style: TextStyle(
                          color: isDarkMode ? Colors.black : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Text(
                    TranslationHelper.t('Or', 'یا'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- Login as Admin Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to LoginScreen (same as regular login)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        TranslationHelper.t('Admin Login', 'ایڈمن لاگ ان'),
                        style: TextStyle(
                          color: isDarkMode ? Colors.black : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          );
        },
      ),
    );
  }
}