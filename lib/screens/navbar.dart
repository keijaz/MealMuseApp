import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'expiring.dart'; 
import 'add_item_screen.dart'; 
// import 'dishes.dart';
import 'home.dart';
import 'settings.dart';
import 'inventory_screen.dart';
import '../utils/translation_helper.dart';

// --- COLOR PALETTE ---
class AppColors {
  static const Color expiringRed = Color(0xFF5C8A94); // Used for highlight color
}

class CustomBottomNavBar extends StatelessWidget {
  // Callback function for tabs that switch content within the parent (Home, Search, Profile)
  final Function(int) onTabContentTapped; 
  final int currentIndex;
  // The BuildContext from the parent Scaffold/Screen, necessary for Navigator.of(context)
  final BuildContext navContext; 

  const CustomBottomNavBar({
    super.key,
    required this.onTabContentTapped,
    required this.currentIndex,
    required this.navContext, // Crucial for navigation
  });

  // --- NAVIGATION HANDLER: Handles both page transitions and state updates ---
  void _handleNavigation(int index) {
    if (index == 3) {
      // 1. Expire (Trash icon): Navigate to a new page (ExpiringItemsScreen)
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => const ExpiringItemsScreen(),
        ),
      );
    } else if (index == 2) {
      // 2. Add (Plus icon): Navigate to a new page (AddItem)
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => const AddItemScreen(),
        ),
      );
    } 
    else if (index == 4) {
      // Profile icon: Navigate to Settings page
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => const Setting_menu(),
        ),
      );
    }
    else if (index == 0) {
      // 2. Add (Plus icon): Navigate to a new page (AddItem)
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => const MainHomeScreen(),
        ),
      );
    } else if (index == 1) {
      // 2. Add (Plus icon): Navigate to a new page (AddItem)
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (context) => const InventoryApp(),
        ),
      );
    }
    else {
      // 3. Home (0), Search (1), Profile (4): Update the parent state to switch content
      onTabContentTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    
    return BottomNavigationBar(
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.expiringRed,
      unselectedItemColor: isDarkMode ? const Color(0xFF808080) : Colors.grey,
      backgroundColor: backgroundColor,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: TranslationHelper.t('Home', 'ہوم'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.kitchen_outlined),
          label: TranslationHelper.t('Inventory', 'انوینٹری'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 30),
          label: TranslationHelper.t('Add', 'شامل کریں'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          label: TranslationHelper.t('Expire', 'ختم ہونے والے'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          label: TranslationHelper.t('Settings', 'ترتیبات'),
        ),
      ],
      // Pass the current index and the internal handler
      currentIndex: currentIndex,
      onTap: _handleNavigation, 
    );

  }
}