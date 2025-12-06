import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

// --------------------------------------------------------------------------
// --- FIREBASE USER DATA CLASS ---
// --------------------------------------------------------------------------
class UserData {
  static final UserData _instance = UserData._internal();
  factory UserData() => _instance;
  UserData._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Properties
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPassword = "";
  String? _userId;
  bool _isInitialized = false;

  String get userPasswordDisplay => "********";

  // Initialize user data from Firebase
  Future<void> initializeUser() async {
    if (_isInitialized) return;

    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      await _loadUserData();
      _isInitialized = true;
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['displayName'] ?? data['username'] ?? "User";
          userEmail = data['email'] ?? _auth.currentUser?.email ?? "No email";
        });
      } else {
        await _createUserDocument();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() {
        userName = "Error loading";
        userEmail = "Error loading";
      });
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument() async {
    if (_userId == null) return;

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(_userId).set({
        'uid': _userId,
        'email': user.email,
        'username': user.email?.split('@').first ?? "user",
        'displayName': user.displayName ?? user.email?.split('@').first ?? "User",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
    }
  }

  // Update user name in Firestore
  Future<void> updateUserName(String newName) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'displayName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        userName = newName;
      });
    } catch (e) {
      debugPrint("Error updating user name: $e");
      rethrow;
    }
  }

  // Update user password using Firebase Auth
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  // Helper method to trigger UI updates
  void setState(VoidCallback callback) {
    callback();
  }

  // Get current user ID
  String? get userId => _userId;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _userId = null;
    _isInitialized = false;
    userName = "Loading...";
    userEmail = "Loading...";
  }
}

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5);

class ProfileCheck extends StatefulWidget {
  const ProfileCheck({super.key});
  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<ProfileCheck> {
  final UserData _userData = UserData();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  Future<void> _initializeUserData() async {
    await _userData.initializeUser();
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _navigateHome(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  // --- Name Editing Dialog with Firebase ---
  Future<void> _showEditNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _userData.userName);

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: _buildNameDialogContent(context, nameController),
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userData.updateUserName(newName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!'))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: $e'))
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNameDialogContent(BuildContext context, TextEditingController controller) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final fieldBg = isDarkMode ? const Color(0xFF3A3A3A) : _kSubtleGray;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400];
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Update Name",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Enter New Name",
              hintStyle: TextStyle(color: hintColor, fontSize: 18),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: const BorderSide(color: _kButtonColor, width: 2),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: _kButtonColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    String trimmedText = controller.text.trim();
                    Navigator.of(context).pop(trimmedText.isNotEmpty ? trimmedText : null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Password Editing Dialog with Firebase Auth ---
  Future<void> _showEditPasswordDialog() async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: _PasswordDialogContent(),
        );
      },
    );

    if (newPassword != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userData.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e'))
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Save all changes to Firebase
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Any additional save logic can go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All changes saved successfully!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white, // Clean background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C8A94)),
                strokeWidth: 4.0,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Color(0xFF5C8A94),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : _kScreenBackgroundColor;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtleGray = isDarkMode ? const Color(0xFF2A2A2A) : _kSubtleGray;

    final accountTitle = TranslationHelper.get('account');
    final nameLabel = TranslationHelper.t('Name', 'نام');
    final emailLabel = TranslationHelper.t('Email', 'ای میل');
    final passwordLabel = TranslationHelper.t('Password', 'پاس ورڈ');
    final saveChangesLabel = TranslationHelper.t('Save Changes', 'تبدیلیاں محفوظ کریں');

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 4,
        navContext: context,
      ),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 28),
                    ),
                    Text(
                      accountTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 34),
                  ]
                ),
              ),
              Divider(color: subtleGray, thickness: 1.5, height: 0),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      _SleekInputField(
                        label: nameLabel,
                        value: _userData.userName,
                        isEditable: true,
                        onEditTap: _showEditNameDialog,
                      ),
                      const SizedBox(height: 25),

                      // Email Field
                      _SleekInputField(
                        label: emailLabel,
                        value: _userData.userEmail,
                        isEditable: false, 
                      ),
                      const SizedBox(height: 25),

                      // Password Field
                      _SleekInputField(
                        label: passwordLabel,
                        value: _userData.userPasswordDisplay,
                        isEditable: true,
                        isObscured: true,
                        onEditTap: _showEditPasswordDialog,
                      ),
                      const SizedBox(height: 60),

                      // Save Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kButtonColor,
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 8,
                            shadowColor: _kButtonColor.withOpacity(0.4),
                          ),
                          child: Text(
                            saveChangesLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- Password Dialog Content for Firebase Auth ---
// --------------------------------------------------------------------------
class _PasswordDialogContent extends StatefulWidget {
  const _PasswordDialogContent();

  @override
  _PasswordDialogContentState createState() => _PasswordDialogContentState();
}

class _PasswordDialogContentState extends State<_PasswordDialogContent> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isObscuredNew = true;
  bool _isObscuredConfirm = true;
  bool _passwordsMatch = false;

  Map<String, bool> _validationChecks = {
    'At least 6 characters': false,
    'At least one number (0-9)': false,
    'At least one special character (!@ etc.)': false,
  };

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(_validateNewPassword);
    _confirmPassController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _newPassController.removeListener(_validateNewPassword);
    _confirmPassController.removeListener(_checkPasswordMatch);
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
  
  void _validateNewPassword() {
    final password = _newPassController.text;
    if (password.isEmpty) {
      setState(() {
        _validationChecks = _validationChecks.map((key, value) => MapEntry(key, false));
      });
      _checkPasswordMatch();
      return;
    }

    setState(() {
      _validationChecks['At least 6 characters'] = password.length >= 6;
      _validationChecks['At least one number (0-9)'] = password.contains(RegExp(r'[0-9]'));
      _validationChecks['At least one special character (!@ etc.)'] = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
    
    _checkPasswordMatch();
  }

  void _checkPasswordMatch() {
    setState(() {
      _passwordsMatch = _newPassController.text.isNotEmpty && _newPassController.text == _confirmPassController.text;
    });
  }

  bool _isPasswordValid() {
    return _validationChecks.values.every((isValid) => isValid) && _passwordsMatch;
  }

  Widget _buildValidationRow(String text, bool isValid) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final checkIconColor = isDarkMode ? _kButtonColor : _kButtonColor;
    final uncheckedIconColor = isDarkMode ? const Color(0xFF606060) : Colors.grey[400];
    final validTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final invalidTextColor = isDarkMode ? const Color(0xFF808080) : Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            color: isValid ? checkIconColor : uncheckedIconColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? validTextColor : invalidTextColor,
                fontSize: 14,
                fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final secondaryTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    final fieldBg = isDarkMode ? const Color(0xFF3A3A3A) : _kSubtleGray;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400];
    final iconColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final checkIconColor = isDarkMode ? _kButtonColor : _kButtonColor;
    final uncheckedIconColor = isDarkMode ? const Color(0xFF606060) : Colors.grey[400];
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              "Update Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 25),
          
          // New Password Input
          Text("New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassController,
            obscureText: _isObscuredNew,
            decoration: InputDecoration(
              hintText: "Enter New Password",
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(_isObscuredNew ? Icons.visibility_off : Icons.visibility, color: iconColor),
                onPressed: () {
                  setState(() {
                    _isObscuredNew = !_isObscuredNew;
                  });
                },
              ),
            ),
            style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Validation Checklist
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _validationChecks.entries
                .map((entry) => _buildValidationRow(entry.key, entry.value))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Confirm Password Input
          Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassController,
            obscureText: _isObscuredConfirm,
            decoration: InputDecoration(
              hintText: "Confirm New Password",
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(_isObscuredConfirm ? Icons.visibility_off : Icons.visibility, color: iconColor),
                onPressed: () {
                  setState(() {
                    _isObscuredConfirm = !_isObscuredConfirm;
                  });
                },
              ),
            ),
            style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // Password Match Indicator
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(
                  _passwordsMatch ? Icons.check_circle : Icons.circle_outlined,
                  color: _passwordsMatch ? checkIconColor : uncheckedIconColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Passwords match",
                  style: TextStyle(
                    color: _passwordsMatch ? textColor : secondaryTextColor,
                    fontSize: 14,
                    fontWeight: _passwordsMatch ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    side: const BorderSide(color: _kButtonColor, width: 2),
                  ),
                  child: Text("Cancel", style: TextStyle(color: _kButtonColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPasswordValid()
                      ? () {
                        Navigator.of(context).pop(_newPassController.text);
                      }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 5,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                  ),
                  child: Text("Done", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Sleek Input Field for Account Screen ---
// --------------------------------------------------------------------------
class _SleekInputField extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditable;
  final bool isObscured;
  final VoidCallback? onEditTap;

  const _SleekInputField({
    required this.label,
    required this.value,
    this.isEditable = false,
    this.isObscured = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final labelColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final containerColor = isDarkMode ? const Color(0xFF2A2A2A) : _kSubtleGray;
    final valueColor = isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF404040);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Value Container
        Container(
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: containerColor, width: 2),
          ),
          padding: const EdgeInsets.only(top: 15, bottom: 15, left: 20, right: 15),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Value Text
              Expanded(
                child: Text(
                  isObscured ? '•' * 8 : value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Edit Icon (if editable)
              if (isEditable)
                GestureDetector(
                  onTap: onEditTap,
                  child: const Icon(
                    Icons.edit_note,
                    color: Color(0xFF5B8A94),
                    size: 30,
                  ),
                ),
            ]
          ),
        ),
      ],
    );
  }
}