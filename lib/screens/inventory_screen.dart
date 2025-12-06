import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'inventory_categories.dart';
import 'dishes.dart';
import 'navbar.dart';

// --- Data Model for Inventory Items ---
class InventoryItem {
  final String name;
  final IconData icon;
  final String category;

  const InventoryItem({
    required this.name,
    required this.icon,
    required this.category,
  });
}

// --- Main Inventory Categories Screen Widget ---
class InventoryCategoriesScreen extends StatefulWidget {
  const InventoryCategoriesScreen({super.key});

  @override
  State<InventoryCategoriesScreen> createState() => _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends State<InventoryCategoriesScreen> {
  // Data for the main category buttons
  final List<InventoryItem> categories = const [
    InventoryItem(name: 'All', icon: Icons.all_inclusive, category: 'All'),
    InventoryItem(name: 'Vegetables', icon: Icons.grass_outlined, category: 'Vegetable'),
    InventoryItem(name: 'Fruits', icon: Icons.apple, category: 'Fruit'),
    InventoryItem(name: 'Protein', icon: Icons.local_fire_department_outlined, category: 'Protein'),
    InventoryItem(name: 'Dairy', icon: Icons.local_drink_outlined, category: 'Dairy'),
    InventoryItem(name: 'Grains', icon: Icons.grain_outlined, category: 'Grain'),
    InventoryItem(name: 'Beverages', icon: Icons.coffee, category: 'Beverage'),
    InventoryItem(name: 'Snacks', icon: Icons.cookie, category: 'Snack'),
    InventoryItem(name: 'Spices', icon: Icons.energy_savings_leaf, category: 'Spices'),
    InventoryItem(name: 'Other', icon: Icons.more_horiz, category: 'Other'),
  ];

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
    setState(() {});
  }
 
  String _translateCategoryName(String name) {
    switch (name.toLowerCase()) {
      case 'all':
        return TranslationHelper.t('All', 'تمام');
      case 'vegetables':
        return TranslationHelper.t('Vegetables', 'سبزی');
      case 'fruits':
        return TranslationHelper.t('Fruits', 'پھل');
      case 'protein':
        return TranslationHelper.t('Protein', 'پروٹین');
      case 'dairy':
        return TranslationHelper.t('Dairy', 'ڈیری');
      case 'grains':
        return TranslationHelper.t('Grains', 'اناج');
      case 'beverages':
        return TranslationHelper.t('Beverages', 'مشروب');
      case 'snacks':
        return TranslationHelper.t('Snacks', 'اسنیکس');
      case 'spices':
        return TranslationHelper.t('Spices', 'مصالحے');
      case 'other':
        return TranslationHelper.t('Other', 'دیگر');
      default:
        return name;
    }
  }

  // Helper function for navigating to the InventoryScreen with category
  void _navigateToInventoryScreen(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryScreen(category: category),
      ),
    );
  }

  // Widget for a single, stylish category button
  Widget _buildCategoryButton(BuildContext context, InventoryItem category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _navigateToInventoryScreen(context, category.category),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C8A94),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 24.0),
            const SizedBox(width: 15),
            Text(
              _translateCategoryName(category.name),
              style: const TextStyle(fontSize: 18.0),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18.0),
          ],
        ),
      ),
    );
  }

  // Widget for the clickable search bar
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showSearchScreen(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 24.0),
            const SizedBox(width: 10),
            Text(
              'Search All Items',
              style: TextStyle(color: Colors.grey[600], fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchInventoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final searchBarColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    final searchTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    final searchBorderColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300]!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 1,
        navContext: context,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 28.0, color: textColor),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text(
                    TranslationHelper.t('Inventory', 'انوینٹری'),
                    style: TextStyle(
                      fontSize: 32.0,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance the back button
                ],
              ),
              const SizedBox(height: 30),

              // Search Bar
              GestureDetector(
                onTap: () => _showSearchScreen(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  margin: const EdgeInsets.only(bottom: 24.0),
                  decoration: BoxDecoration(
                    color: searchBarColor,
                    borderRadius: BorderRadius.circular(25.0),
                    border: Border.all(color: searchBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: searchTextColor, size: 24.0),
                      const SizedBox(width: 10),
                      Text(
                        TranslationHelper.t('Search All Items', 'تمام آئٹمز تلاش کریں'),
                        style: TextStyle(color: searchTextColor, fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryButton(context, categories[index]);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Find Recipes Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _navigateToRecipes(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFB73D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFb8cf6b).withOpacity(0.5),
                  ),
                  child: Text(
                    TranslationHelper.t('Find Recipes →', 'ریسیپیز تلاش کریں →'),
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeApp(),
      ),
    );
  }
}

// --- Search Screen Widget ---
class SearchInventoryScreen extends StatefulWidget {
  const SearchInventoryScreen({super.key});

  @override
  State<SearchInventoryScreen> createState() => _SearchInventoryScreenState();
}

class _SearchInventoryScreenState extends State<SearchInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  void _searchInventory(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('inventory')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching inventory: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _performFuzzySearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('inventory')
          .get();

      // Perform client-side fuzzy filtering
      final filteredResults = snapshot.docs.where((doc) {
        final String name = doc['name'].toString().toLowerCase();
        final String searchQuery = query.toLowerCase();
        return name.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Error performing fuzzy search: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildSearchResultItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: ListTile(
        leading: _getCategoryIcon(data['category'] ?? 'Other'),
        title: Text(
          data['name'] ?? 'Unknown Item',
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(
          '${data['quantity'] ?? ''} ${data['unit'] ?? ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Text(
          data['category'] ?? 'Other',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return const Icon(Icons.all_inclusive, color: Colors.purple);
      case 'vegetable':
        return const Icon(Icons.grass_outlined, color: Colors.green);
      case 'fruit':
        return const Icon(Icons.apple, color: Colors.red);
      case 'protein':
      case 'meat':
        return const Icon(Icons.local_fire_department_outlined, color: Colors.orange);
      case 'dairy':
        return const Icon(Icons.local_drink_outlined, color: Colors.blue);
      case 'grain':
        return const Icon(Icons.grain_outlined, color: Colors.amber);
      case 'beverage':
        return const Icon(Icons.coffee, color: Colors.brown);
      case 'snack':
        return const Icon(Icons.cookie, color: Colors.orange);
      case 'spices':
        return const Icon(Icons.energy_savings_leaf, color: Colors.green);
      default:
        return const Icon(Icons.inventory_2_outlined, color: Colors.grey);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0,
        navContext: context,
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: TranslationHelper.t('Search inventory items...', 'انوینٹری کی آئٹمز تلاش کریں...'),
            border: InputBorder.none,
            hintStyle: TextStyle(color: hintColor),
          ),
          style: TextStyle(color: textColor),
          onChanged: (value) {
            // Use fuzzy search for better partial matching
            _performFuzzySearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: hintColor),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search info
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                TranslationHelper.t('Type to search your inventory items', 'اپنی انوینٹری کی آئٹمز تلاش کرنے کے لیے ٹائپ کریں'),
                style: TextStyle(color: hintColor, fontSize: 16),
              ),
            ),
          
          // Loading indicator
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          
          // Search results
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching
                ? Center(
                    child: Text(
                      TranslationHelper.t('No items found', 'کوئی آئٹمز نہیں ملے'),
                      style: TextStyle(color: hintColor, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultItem(_searchResults[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Application Entry Point ---
class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      home: const InventoryCategoriesScreen(),
      routes: {
        '/inventory': (context) {
          final category = ModalRoute.of(context)!.settings.arguments as String? ?? 'All';
          return InventoryScreen(category: category);
        },
      },
    );
  }
}