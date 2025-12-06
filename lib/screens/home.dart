import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'account_screen.dart';
import 'navbar.dart'; 
import 'inventory_screen.dart';
import 'dishes.dart';
import 'saved_recipes.dart';
import 'add_item_screen.dart';
import 'settings.dart';
import 'grocery_list.dart';
import 'chatbot.dart';

// --- COLOR PALETTE (Required for local widgets) ---
class AppColors {
  static const Color headerBackground = Color(0xFF5C8A94);
  static const Color headerText = Colors.white;
  static const Color addButton = Color(0xFF5C8A94);  
  static const Color findRecipes = Color(0xFFAFB73D);
  static const Color openInventory = Color(0xFFD97D55);
  static const Color savedRecipes = Color(0xFFF5CA59);
  static const Color settings = Color(0xFF5C8A94);
  static const Color cardShadow = Color(0x33000000); 
  static const Color expiringRed = Color(0xFFBC0805); 
}

// --- CONTENT SCREEN WRAPPERS ---
// These wrappers use the imported screen files for the body content when tabs are switched.

class SearchContentScreen extends StatelessWidget {
  const SearchContentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const AddItemScreen(); // Content for Nav Index 1
  }
}

class ProfileContentScreen extends StatelessWidget {
  const ProfileContentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ProfileCheck(); // Content for Nav Index 4
  }
}

// --- REUSABLE GRID BUTTON WIDGET (Handles push navigation to dedicated screens) ---
class GridButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen; 

  const GridButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- USER DATA STREAM ---
class UserDataStream extends StatelessWidget {
  final Widget Function(String displayName) builder;
  
  const UserDataStream({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return builder('Guest'); // Fallback if user is not logged in
    }
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builder('...'); // Loading state
        }
        
        if (snapshot.hasError) {
          print('Error fetching user data: ${snapshot.error}');
          return builder('User'); // Fallback on error
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return builder('User'); // Fallback if no user data
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] as String?;
        
        return builder(displayName ?? 'User'); // Use displayName or fallback
      },
    );
  }
}

// --- ACTUAL HOME SCREEN CONTENT (The body of the Home tab) ---
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    // Rebuild when locale changes (e.g., returning from Settings)
    if (mounted) {
      setState(() {});
    }
  }


 // AI chatbot
  Widget _buildAddItemButton(BuildContext context) {
    final addNewItemLabel = TranslationHelper.t('AI Support', 'بات چیت روبوٹ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()), // Navigates to dedicated screen
          );
        },
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: Text(
          addNewItemLabel,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.addButton,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: AppColors.cardShadow,
        ),
      ),
    );
  }

  Widget _buildGridButtons(BuildContext context) {
    final findRecipesLabel = TranslationHelper.t('Find Recipes', 'ریسیپیز تلاش کریں');
    final openInventoryLabel = TranslationHelper.t('Open Inventory', 'انوینٹری کھولیں');
    final savedRecipesLabel = TranslationHelper.t('Saved Recipes', 'محفوظ ریسیپیز');
    final settingsLabel = TranslationHelper.get('settings');
    final shoppingLabel = TranslationHelper.t('Shopping List', 'خریداری');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.05,
        children: [
          GridButton(
            title: findRecipesLabel,
            icon: Icons.ramen_dining_rounded,
            color: AppColors.findRecipes,
            screen: RecipeApp(), // Navigates to FindRecipesScreen
          ),
          GridButton(
            title: openInventoryLabel,
            icon: Icons.kitchen_outlined, 
            color: AppColors.openInventory,
            screen: InventoryCategoriesScreen(), // Navigates to InventoryScreen
          ),
          GridButton(
            title: savedRecipesLabel,
            icon: Icons.bookmark_border_rounded,
            color: AppColors.savedRecipes,
            screen: const SavedRecipesScreen(), // Navigates to SavedRecipesScreen
          ),
          GridButton(
            title: shoppingLabel,
            icon: Icons.shopping_cart_outlined,
            color: AppColors.settings,
            screen: GroceryListScreen(), // Navigates to groccery list
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.25;
    final welcomeBackLabel = TranslationHelper.t('Welcome back', 'خوش آمدید');

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            height: headerHeight,
            decoration: const BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserDataStream(
                          builder: (displayName) {
                            final hiLabel = TranslationHelper.t('Hi', 'ہیلو');
                            return Text(
                              '$hiLabel $displayName!',
                              style: const TextStyle(
                                color: AppColors.headerText,
                                fontSize: 32,
                              ),
                            );
                          },
                        ),
                        Text(
                          welcomeBackLabel,
                          style: const TextStyle(
                            color: AppColors.headerText,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileCheck()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.headerText.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.headerText,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildAddItemButton(context),
          _buildGridButtons(context),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// --- MAIN APPLICATION SHELL (Stateful Widget) ---
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  // State variable to track the currently selected content index: 0=Home, 1=Search, 2=Profile
  int _selectedIndex = 0;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  // List of the main screen content widgets (3 screens that replace the body)
  final List<Widget> _tabContent = <Widget>[
    const HomeScreenContent(),  // Content Index 0: Home (Nav Index 0)
    const SearchContentScreen(), // Content Index 1: Search (Nav Index 1)
    const ProfileContentScreen(),// Content Index 2: Profile (Nav Index 4)
  ];
  
  // Handles state update from the CustomBottomNavBar for content-switching tabs (0, 1, 2)
  void _onTabContentTapped(int contentIndex) {
    setState(() {
      _selectedIndex = contentIndex; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // Content Index (0, 1, 2) to Nav Bar Index (0, 1, 4) mapping for highlighting
    int navBarIndex = _selectedIndex;
    // Content Index 2 (Profile) must map to Nav Index 4.
    if (_selectedIndex == 2) {
      navBarIndex = 4; 
    }
    // Content index 0 (Home) and 1 (Search) map directly to Nav indices 0 and 1.

    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      
      // Display the selected tab content in the body
      body: _tabContent.elementAt(_selectedIndex), 

      // --- IMPORTED CUSTOM BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: _onTabContentTapped, 
        currentIndex: navBarIndex,
        navContext: context, 
      ),
    );
  }
}

