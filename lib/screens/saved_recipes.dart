import 'package:flutter/material.dart';
import 'recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

// --- MAIN APP ENTRY POINT ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCB73)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const SavedRecipesScreen(),
    );
  }
}

// --- SAVED RECIPES SCREEN (STATEFUL) ---
class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ThemeProvider _themeProvider;

  static const Color primaryColor = Color(0xFFFFCB73);
  List<DocumentSnapshot> _filteredRecipes = [];
  List<DocumentSnapshot> _allRecipes = [];

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
    _searchController.addListener(_filterRecipes);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _searchController.removeListener(_filterRecipes);
    _searchController.dispose();
    super.dispose();
  }

  // --- FIREBASE DATA FETCHING ---
  Stream<QuerySnapshot> _getSavedRecipesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // --- SEARCH LOGIC ---
  void _filterRecipes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title']?.toString().toLowerCase() ?? '';
          return title.contains(query);
        }).toList();
      }
    });
  }

  // --- NAVIGATION METHOD ---
  void _navigateToRecipeDetail(Map<String, dynamic> recipeData, String documentId) {
    // Extract recipeId from the recipe data - handle both possible field names
    final recipeId = recipeData['recipeId'] ?? recipeData['recipеId'] ?? recipeData['id'];
    
    if (recipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.t('Recipe ID not found', 'ریسیپی آئی ڈی نہیں ملی')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: recipeData,
          recipeId: recipeId.toString(), // Pass the recipeId explicitly
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSearchBar() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final searchBarBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    const Color accentColor = Color(0xFFFFCB73);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        elevation: 8.0,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(30.0),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: TranslationHelper.t('Search Recipe', 'ریسیپی تلاش کریں'),
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(Icons.search, color: hintColor),
            border: InputBorder.none,
            filled: true,
            fillColor: searchBarBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: searchBarBg, width: 0.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: const BorderSide(color: accentColor, width: 2.0),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSavedRecipesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading recipes: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Update the recipes lists
        _allRecipes = snapshot.data!.docs;
        // Reapply filter with current search query (schedule after build)
        if (_filteredRecipes.isEmpty || _filteredRecipes.length != _allRecipes.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterRecipes();
          });
        }

        // Use _allRecipes directly if no search is active, otherwise use _filteredRecipes
        final recipesToShow = _searchController.text.isEmpty ? _allRecipes : _filteredRecipes;

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: recipesToShow.length,
          itemBuilder: (context, index) {
            final doc = recipesToShow[index];
            final recipeData = doc.data() as Map<String, dynamic>;
            
            return _buildRecipeCard(recipeData, doc.id);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipeData, String documentId) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            recipeData['image'] ?? 'https://via.placeholder.com/60x60',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300],
                child: Icon(Icons.fastfood, color: subtitleColor),
              );
            },
          ),
        ),
        title: Text(
          recipeData['title'] ?? 'Untitled Recipe',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (recipeData['missedIngredientCount'] != null)
            //   Text(
            //     'Missing ingredients: ${recipeData['missedIngredientCount']}',
            //     style: TextStyle(color: subtitleColor, fontSize: 12),
            //   ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subtitleColor),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(TranslationHelper.t('View Recipe', 'ریسیپی دیکھیں')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text(TranslationHelper.t('Remove', 'ہٹائیں')),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _navigateToRecipeDetail(recipeData, documentId);
            } else if (value == 'delete') {
              _deleteRecipe(documentId);
            }
          },
        ),
        onTap: () {
          _navigateToRecipeDetail(recipeData, documentId);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            TranslationHelper.t('Loading your saved recipes...', 'آپ کی محفوظ شدہ ریسیپیز لوڈ کی جا رہی ہیں...'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    final iconColor = isDarkMode ? const Color(0xFF4A4A4A) : Colors.grey[300];
    
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.bookmark_border,
            size: 100,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            TranslationHelper.t('No Saved Recipes', 'کوئی محفوظ ریسیپیز نہیں'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationHelper.t('Save recipes to see them here!', 'ریسیپیز محفوظ کریں تاکہ وہ یہاں دکھیں!'),
            style: TextStyle(color: subtitleColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            TranslationHelper.t('Failed to load recipes', 'ریسیپیز لوڈ کرنے میں ناکامی'),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text(TranslationHelper.t('Retry', 'دوبارہ کوشش کریں')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(String documentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.t('Recipe removed from saved recipes', 'ریسیپی محفوظ شدہ فہرست سے ہٹا دی گئی')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${TranslationHelper.t('Failed to remove recipe', 'ریسیپیز ہٹانے میں ناکامی')}: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final headerBg = primaryColor; // Always use yellow/gold for header
    final headerText = Colors.white;
    
    const double searchBarHeight = 60.0;
    const double headerHeight = 150.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0,
        navContext: context,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // 1. Custom Header Section with Overlapping Search Bar
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Yellow/Gold Header Container with Title and Back Button
                Container(
                  height: headerHeight,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50.0),
                      bottomRight: Radius.circular(50.0),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, left: 15.0, right: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Back Button
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, size: 30, color: headerText),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          // Title
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              TranslationHelper.t('Saved Recipes', 'محفوظ ریسیپیز'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: headerText,
                              ),
                            ),
                          ),
                          // Spacer to balance the back button
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Positioned(
                  bottom: -searchBarHeight / 2,
                  left: 0,
                  right: 0,
                  child: _buildSearchBar(),
                ),
              ],
            ),

            // 2. Main Content Area
            SizedBox(height: searchBarHeight / 2 + 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildRecipeList(),
            ),
          ],
        ),
      ),
    );
  }
}