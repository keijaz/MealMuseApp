import 'package:flutter/material.dart';
import 'UsersScreen.dart';
import '../screens/homepage.dart'; // Assuming HomePage is imported
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Don't wrap in MaterialApp - use existing app's MaterialApp
    return const AdminAccountScreen();
  }
}

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key}); // Remove const from constructor

  // Define the main colors used in the design
  static const Color primaryColor = Color(0xFF5C8A94); // The teal/blue-grey color matching homepage
  static const Color accentColor = Colors.white; 

  // Firebase Auth instance - remove 'final' and initialize in build method
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Logout function
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Navigate to HomePage after successful logout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false, // Remove all routes from stack
      );
    } catch (e) {
      // Handle any errors that occur during logout
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: Column(
        children: <Widget>[
          // 1. Custom Rounded Header/AppBar Area
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50.0),
                bottomRight: Radius.circular(50.0),
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Welcome to\nAdmin Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 2. The "Check Users" Button
          Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsersScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: primaryColor, size: 28),
                      const SizedBox(width: 20),
                      const Text(
                        'Check Users',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () => _signOut(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE57373).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE57373).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Color(0xFFE57373), size: 28),
                      const SizedBox(width: 20),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFFE57373).withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
      ),
    );
  }
}