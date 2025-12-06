// dishes.dart
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'home.dart';
import 'api_service.dart';
import 'recipe.dart';
import 'navbar.dart';

// Define the primary color based on the hex code #5C8A94
const Color _primaryColor = Color(0xFF5C8A94);
const Color _primaryColor30 = Color(0x4D5C8A94); // 30% opacity of #5C8A94 (0x4D is 30% of 0xFF)

// --- Main Application Entry Point ---
void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipes App',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
            .copyWith(primary: _primaryColor),
      ),
      home: const RecipesScreen(),
    );
  }
}

// --- 1. The Filter Screen (Updated with Diet and Intolerance) ---
class FilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  
  const FilterScreen({super.key, required this.onFiltersApplied});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Data for the filter categories
  final List<String> sortOptions = [
    'popularity',
    'healthiness',
    'time',
    'random'
  ];
  
  // Diet options
  final List<String> dietOptions = [
    'glutenFree',
    'ketogenic',
    'vegetarian',
    'lacto-vegetarian',
    'ovo-vegetarian',
    'vegan',
    'pescetarian',
    'paleo',
    'primal',
    'whole30'
  ];
  
  // Intolerance options
  final List<String> intoleranceOptions = [
    'dairy',
    'egg',
    'gluten',
    'grain',
    'peanut',
    'seafood',
    'sesame',
    'shellfish',
    'soy',
    'sulfite',
    'treeNut',
    'wheat'
  ];

  // State to track selected items
  String selectedSort = 'popularity';
  Set<String> selectedDiets = {};
  Set<String> selectedIntolerances = {};

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

  bool get _isUrdu => LocaleProvider().localeNotifier.value?.languageCode == 'ur';

  String _translateSort(String value) {
    if (!_isUrdu) return value;
    switch (value) {
      case 'popularity': return 'مقبولیت';
      case 'healthiness': return 'صحت';
      case 'time': return 'وقت';
      case 'random': return 'بے ترتیب';
      default: return value;
    }
  }

  String _translateDiet(String value) {
    if (!_isUrdu) return value;
    switch (value) {
      case 'glutenFree': return 'گلوٹین فری';
      case 'ketogenic': return 'کیٹوجینک';
      case 'vegetarian': return 'سبزی خور';
      case 'lacto-vegetarian': return 'ڈیری سبزی خور';
      case 'ovo-vegetarian': return 'انڈے سبزی خور';
      case 'vegan': return 'وگن';
      case 'pescetarian': return 'مچھلی خور';
      case 'paleo': return 'پیلیو';
      case 'primal': return 'پرائمل';
      case 'whole30': return 'ہول 30';
      default: return value;
    }
  }

  String _translateIntolerance(String value) {
    if (!_isUrdu) return value;
    switch (value) {
      case 'dairy': return 'ڈیری';
      case 'egg': return 'انڈہ';
      case 'gluten': return 'گلوٹین';
      case 'grain': return 'اناج';
      case 'peanut': return 'مونگ پھلی';
      case 'seafood': return 'سی فوڈ';
      case 'sesame': return 'تل';
      case 'shellfish': return 'شیل فش';
      case 'soy': return 'سویا';
      case 'sulfite': return 'سلفائٹ';
      case 'treeNut': return 'ٹری نٹ';
      case 'wheat': return 'گندم';
      default: return value;
    }
  }

  void _applyFilters() {
    final filters = {
      'sort': selectedSort,
      'diets': selectedDiets.toList(),
      'intolerances': selectedIntolerances.toList(),
    };
    widget.onFiltersApplied(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedSort = 'popularity';
      selectedDiets.clear();
      selectedIntolerances.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final filterTitle = TranslationHelper.t('Filter', 'فلٹر');
    final sortByLabel = TranslationHelper.t('Sort By', 'ترتیب دیں');
    final dietLabel = TranslationHelper.t('Diet', 'خوراک');
    final intoleranceLabel = TranslationHelper.t('Intolerances', 'عدم رواداری');
    final resetLabel = TranslationHelper.t('Reset', 'دوبارہ سیٹ کریں');
    final applyFiltersLabel = TranslationHelper.t('Apply Filters', 'فلٹر لاگو کریں');

    // Dark / light adaptive colors
    final background = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final headerBackground = isDarkMode ? const Color(0xFF1E1E1E) : _primaryColor30;
    final primaryText = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final chipUnselected = isDarkMode ? const Color(0xFF2A2A2A) : _primaryColor30;
    final chipSelectedText = Colors.white;
    final chipUnselectedText = primaryText;
    final resetBtnBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[300];
    final resetBtnFg = isDarkMode ? primaryText : Colors.black;
    final applyBtnBg = _primaryColor;
    final applyBtnFg = Colors.white;

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0,
        navContext: context,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: headerBackground,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: primaryText),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48.0),
                      child: Text(
                        filterTitle,
                        style: TextStyle(
                          fontSize: 28.0,
                          color: primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sort Section
            _buildFilterSectionWithColors(sortByLabel, sortOptions, true, chipSelectedText, chipUnselectedText, chipUnselected),
            const SizedBox(height: 10.0),
            
            // Diet Section
            _buildFilterSectionWithColors(dietLabel, dietOptions, false, chipSelectedText, chipUnselectedText, chipUnselected, isDiet: true),
            const SizedBox(height: 10.0),
            
            // Intolerance Section
            _buildFilterSectionWithColors(intoleranceLabel, intoleranceOptions, false, chipSelectedText, chipUnselectedText, chipUnselected, isIntolerance: true),
            
            // Apply and Reset Buttons
            const SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resetBtnBg,
                      foregroundColor: resetBtnFg,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(resetLabel),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: applyBtnBg,
                      foregroundColor: applyBtnFg,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(applyFiltersLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Updated wrapper to handle different filter types
  Widget _buildFilterSectionWithColors(
    String title, 
    List<String> items, 
    bool isSingleSelection,
    Color selectedTextColor, 
    Color unselectedTextColor, 
    Color unselectedBgColor, {
    bool isDiet = false,
    bool isIntolerance = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24.0,
              color: unselectedTextColor,
            ),
          ),
        ),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final isSelected = isSingleSelection 
                ? selectedSort == item 
                : isDiet 
                    ? selectedDiets.contains(item)
                    : selectedIntolerances.contains(item);
                    
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSingleSelection) {
                    selectedSort = item;
                  } else if (isDiet) {
                    if (isSelected) {
                      selectedDiets.remove(item);
                    } else {
                      selectedDiets.add(item);
                    }
                  } else if (isIntolerance) {
                    if (isSelected) {
                      selectedIntolerances.remove(item);
                    } else {
                      selectedIntolerances.add(item);
                    }
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : unselectedBgColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  _getTranslatedText(item, isSingleSelection, isDiet, isIntolerance),
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  String _getTranslatedText(String item, bool isSingleSelection, bool isDiet, bool isIntolerance) {
    if (isSingleSelection) {
      return _translateSort(item);
    } else if (isDiet) {
      return _translateDiet(item);
    } else if (isIntolerance) {
      return _translateIntolerance(item);
    }
    return item;
  }
}

// --- 2. The Main Screen (Recipes Screen) - UPDATED ---
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filter state - UPDATED
  Map<String, dynamic> _currentFilters = {
    'sort': 'popularity',
    'diets': [],
    'intolerances': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
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

  Future<void> _fetchRecipes({Map<String, dynamic>? filters}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<dynamic> recipes;
      
      // Check if any filters are applied (diets or intolerances)
      if (filters != null && (
          (filters['diets'] as List).isNotEmpty || 
          (filters['intolerances'] as List).isNotEmpty)) {
        print('Using complexSearch with filters: $filters');
        // Use complexSearch API when filters are applied
        recipes = await ApiService.fetchRecipesWithComplexSearch(
          sort: filters['sort'] ?? 'popularity',
          diets: List<String>.from(filters['diets'] ?? []),
          intolerances: List<String>.from(filters['intolerances'] ?? []),
          number: 10,
        );
      } else {
        print('Using findByIngredients (no diet/intolerance filters)');
        // Use findByIngredients API when no diet/intolerance filters
        recipes = await ApiService.fetchRecipesByIngredients(
          number: 10,
          ranking: 2,
          ignorePantry: false,
        );
      }
      
      print('Final result: Received ${recipes.length} recipes');
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
        if (filters != null) {
          _currentFilters = filters;
        }
      });
    } catch (e) {
      print('Error in _fetchRecipes: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          onFiltersApplied: (filters) {
            _fetchRecipes(filters: filters);
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    _fetchRecipes(filters: {
      'sort': 'popularity',
      'diets': [],
      'intolerances': [],
    });
  }

  void _navigateToRecipeDetail(Map<String, dynamic> recipe) {
    final recipeId = recipe['id']?.toString() ?? '';
    
    if (recipeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe ID not found'),
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
          recipe: recipe,
          recipeId: recipeId,
        ),
      ),
    );
  }

  // Helper method to check pantry status for complexSearch recipes
Future<Map<String, int>> _getPantryStatus(List<dynamic> extendedIngredients) async {
  try {
    final pantryIngredients = await ApiService.getPantryIngredientNames();
    if (pantryIngredients.isEmpty) {
      return {'presentCount': 0, 'totalCount': extendedIngredients.length};
    }
    
    int presentCount = 0;
    
    for (final ingredient in extendedIngredients) {
      final ingredientName = (ingredient['name']?.toString() ?? 
                            ingredient['nameClean']?.toString() ?? 
                            '').toLowerCase().trim();
      if (ingredientName.isNotEmpty) {
        final isPresent = pantryIngredients.any((pantryIngredient) =>
          pantryIngredient.toLowerCase().contains(ingredientName) || 
          ingredientName.contains(pantryIngredient.toLowerCase())
        );
        if (isPresent) presentCount++;
      }
    }
    
    return {
      'presentCount': presentCount,
      'totalCount': extendedIngredients.length,
    };
  } catch (e) {
    print('Error checking pantry status: $e');
    return {'presentCount': 0, 'totalCount': extendedIngredients.length};
  }
}

Widget _buildRecipeCard(Map<String, dynamic> recipe) {
  final isDarkMode = ThemeProvider().darkModeEnabled;
  final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
  final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
  final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
  final presentColor = isDarkMode ? const Color(0xFF4CAF50) : Colors.green[700];
  final missingColor = isDarkMode ? const Color(0xFFF44336) : Colors.red[700];
  
  // Get screen size for responsive design
  final screenWidth = MediaQuery.of(context).size.width;
  
  // Responsive sizing based on screen width
  final imageSize = screenWidth < 350 ? 70.0 : 80.0;
  final titleFontSize = screenWidth < 350 ? 14.0 : 16.0;
  final metadataFontSize = screenWidth < 350 ? 10.0 : 12.0;
  final chipFontSize = screenWidth < 350 ? 10.0 : 11.0;
  final horizontalPadding = screenWidth < 350 ? 8.0 : 12.0;
  final verticalPadding = screenWidth < 350 ? 8.0 : 12.0;
  final spacing = screenWidth < 350 ? 8.0 : 12.0;

  // Handle different response formats with type-safe parsing
  final String recipeTitle = recipe['title']?.toString() ?? 'Untitled Recipe';
  final String imageUrl = recipe['image']?.toString() ?? 'https://via.placeholder.com/100x100';
  
  // Safely parse numeric values with type conversion
  final int? missedIngredientCount = _safeParseInt(recipe['missedIngredientCount']);
  final int? usedIngredientCount = _safeParseInt(recipe['usedIngredientCount']);
  final int? readyInMinutes = _safeParseInt(recipe['readyInMinutes']);
  final int? healthScore = _safeParseInt(recipe['healthScore']);
  final int? aggregateLikes = _safeParseInt(recipe['aggregateLikes']);
  
  // Extract ingredients information
  final List<dynamic> usedIngredients = recipe['usedIngredients'] ?? [];
  final List<dynamic> missedIngredients = recipe['missedIngredients'] ?? [];
  final List<dynamic> extendedIngredients = recipe['extendedIngredients'] ?? [];

  return Card(
    color: cardBg,
    elevation: 2,
    margin: EdgeInsets.symmetric(
      vertical: 8,
      horizontal: screenWidth < 350 ? 12.0 : 16.0,
    ),
    child: GestureDetector(
      onTap: () => _navigateToRecipeDetail(recipe),
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image - Responsive size
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[300],
                    child: Icon(Icons.fastfood, 
                      color: Colors.grey,
                      size: imageSize * 0.4,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: spacing),
            // Recipe Details - Expanded to fill available space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Title - Responsive font size
                  Text(
                    recipeTitle,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenWidth < 350 ? 6 : 8),
                  
                  // UPDATED: Ingredients Status Section with pantry check for all recipe types
                  FutureBuilder<Map<String, int>>(
                    future: extendedIngredients.isNotEmpty ? _getPantryStatus(extendedIngredients) : 
                            Future.value({'presentCount': usedIngredientCount ?? 0, 'totalCount': (usedIngredientCount ?? 0) + (missedIngredientCount ?? 0)}),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildIngredientStatus(
                          'Checking pantry...', 
                          Colors.grey,
                          fontSize: chipFontSize,
                        );
                      }
                      
                      if (snapshot.hasData) {
                        final pantryData = snapshot.data!;
                        final presentCount = pantryData['presentCount'] ?? 0;
                        final totalCount = pantryData['totalCount'] ?? 0;
                        
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (presentCount > 0)
                              _buildIngredientStatus(
                                'In Pantry: $presentCount', 
                                presentColor!,
                                fontSize: chipFontSize,
                              ),
                            if (totalCount > presentCount)
                              _buildIngredientStatus(
                                'Missing: ${totalCount - presentCount}', 
                                missingColor!,
                                fontSize: chipFontSize,
                              ),
                          ],
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  SizedBox(height: screenWidth < 350 ? 6 : 8),
                  
                  // Recipe Metadata - Compact responsive layout
                  _buildRecipeMetadata(
                    readyInMinutes: readyInMinutes,
                    healthScore: healthScore,
                    aggregateLikes: aggregateLikes,
                    subtitleColor: subtitleColor,
                    usedIngredientCount: usedIngredientCount,
                    missedIngredientCount: missedIngredientCount,
                    metadataFontSize: metadataFontSize,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper method to build ingredients status section
Widget _buildIngredientsStatusSection({
  required int? usedIngredientCount,
  required int? missedIngredientCount,
  required List<dynamic> extendedIngredients,
  required Color? presentColor,
  required Color? missingColor,
  required double chipFontSize,
}) {
  // If we have direct counts from findByIngredients API
  if (usedIngredientCount != null || missedIngredientCount != null) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (usedIngredientCount != null && usedIngredientCount > 0)
          _buildIngredientStatus(
            'In Pantry: $usedIngredientCount', 
            presentColor!,
            fontSize: chipFontSize,
          ),
        if (missedIngredientCount != null && missedIngredientCount > 0)
          _buildIngredientStatus(
            'Missing: $missedIngredientCount', 
            missingColor!,
            fontSize: chipFontSize,
          ),
      ],
    );
  }
  
  // For complexSearch results, use FutureBuilder to check against pantry
  if (extendedIngredients.isNotEmpty) {
    return FutureBuilder<Set<String>>(
      future: ApiService.getPantryIngredientNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildIngredientStatus(
            'Checking...', 
            Colors.grey,
            fontSize: chipFontSize,
          );
        }
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final pantryIngredients = snapshot.data!;
          int presentCount = 0;
          final int totalCount = extendedIngredients.length;
          
          for (final ingredient in extendedIngredients) {
            final ingredientName = (ingredient['name']?.toString() ?? 
                                  ingredient['nameClean']?.toString() ?? 
                                  '').toLowerCase().trim();
            if (ingredientName.isNotEmpty) {
              final isPresent = pantryIngredients.any((pantryIngredient) =>
                pantryIngredient.contains(ingredientName) || 
                ingredientName.contains(pantryIngredient)
              );
              if (isPresent) presentCount++;
            }
          }
          
          final missingCount = totalCount - presentCount;
          
          return Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (presentCount > 0)
                _buildIngredientStatus(
                  'In Pantry: $presentCount', 
                  presentColor!,
                  fontSize: chipFontSize,
                ),
              if (missingCount > 0)
                _buildIngredientStatus(
                  'Missing: $missingCount', 
                  missingColor!,
                  fontSize: chipFontSize,
                ),
            ],
          );
        }
        
        return _buildIngredientStatus(
          'Ingredients: ${extendedIngredients.length}', 
          Colors.grey,
          fontSize: chipFontSize,
        );
      },
    );
  }
  
  return const SizedBox.shrink();
}

// Helper method to build recipe metadata in a compact layout
Widget _buildRecipeMetadata({
  required int? readyInMinutes,
  required int? healthScore,
  required int? aggregateLikes,
  required Color? subtitleColor,
  required int? usedIngredientCount,
  required int? missedIngredientCount,
  required double metadataFontSize,
  required double screenWidth,
}) {
  final metadataItems = <Widget>[];
  
  // Add time if available - use shorter text on small screens
  if (readyInMinutes != null && readyInMinutes > 0) {
    final timeText = screenWidth < 350 ? '$readyInMinutes min' : 'Ready: $readyInMinutes min';
    metadataItems.add(
      Flexible(
        child: Text(
          timeText,
          style: TextStyle(
            fontSize: metadataFontSize,
            color: subtitleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  
  // Add health score if available - use shorter text on small screens
  // if (healthScore != null && healthScore > 0) {
  //   if (metadataItems.isNotEmpty) {
  //     metadataItems.add(SizedBox(width: screenWidth < 350 ? 6 : 8));
  //   }
  //   final healthText = screenWidth < 350 ? 'Health: $healthScore' : 'Health: $healthScore';
  //   metadataItems.add(
  //     Flexible(
  //       child: Text(
  //         healthText,
  //         style: TextStyle(
  //           fontSize: metadataFontSize,
  //           color: subtitleColor,
  //         ),
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //     ),
  //   );
  // }
  
  // Fallback if no metadata available
  if (metadataItems.isEmpty && 
      (usedIngredientCount == null || usedIngredientCount == 0) && 
      (missedIngredientCount == null || missedIngredientCount == 0)) {
    metadataItems.add(
      Text(
        'Tap for details',
        style: TextStyle(
          fontSize: metadataFontSize,
          color: subtitleColor,
        ),
      ),
    );
  }
  
  // Use Row with Flexible widgets for better control on small screens
  if (screenWidth < 350) {
    return Row(
      children: metadataItems,
    );
  }
  
  return Wrap(
    spacing: 8,
    runSpacing: 4,
    children: metadataItems,
  );
}

// Updated ingredient status chip with responsive sizing
Widget _buildIngredientStatus(String text, Color color, {required double fontSize}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// Helper method to safely parse numeric values from API response
int? _safeParseInt(dynamic value) {
  if (value == null) return null;
  
  try {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.round();
    } else if (value is String) {
      return int.tryParse(value);
    } else {
      return null;
    }
  } catch (e) {
    print('Error parsing integer value: $value, error: $e');
    return null;
  }
}

  // UPDATED: Fixed overflow issue by using Wrap and proper responsive design
  Widget _buildFilterChip() {
    final hasDietFilters = (_currentFilters['diets'] as List).isNotEmpty;
    final hasIntoleranceFilters = (_currentFilters['intolerances'] as List).isNotEmpty;
    final hasActiveFilters = hasDietFilters || hasIntoleranceFilters;
    
    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final chipSpacing = isSmallScreen ? 6.0 : 8.0;
    final chipFontSize = isSmallScreen ? 12.0 : 14.0;
    final sortTextFontSize = isSmallScreen ? 12.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 16.0, 
        vertical: 8.0
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips in a Wrap to prevent overflow
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: [
              if (hasDietFilters)
                Chip(
                  label: Text(
                    '${(_currentFilters['diets'] as List).length} ${isSmallScreen ? 'diet' : 'diet(s)'}',
                    style: TextStyle(fontSize: chipFontSize),
                  ),
                  backgroundColor: _primaryColor30,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: _clearFilters,
                ),
              if (hasIntoleranceFilters)
                Chip(
                  label: Text(
                    '${(_currentFilters['intolerances'] as List).length} ${isSmallScreen ? 'intol.' : 'intolerance(s)'}',
                    style: TextStyle(fontSize: chipFontSize),
                  ),
                  backgroundColor: _primaryColor30,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: _clearFilters,
                ),
            ],
          ),
          
          // Sort information on a new line for better readability
          Padding(
            padding: EdgeInsets.only(top: isSmallScreen ? 6.0 : 8.0),
            child: Text(
              '${TranslationHelper.t('Sorted by', 'ترتیب دیں')}: ${_currentFilters['sort']}',
              style: TextStyle(
                fontSize: sortTextFontSize,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    final iconColor = isDarkMode ? const Color(0xFF4A4A4A) : Colors.grey[300]!;
    
    final noRecipesFoundLabel = TranslationHelper.t('No Recipes Found', 'کوئی ریسیپیز نہیں ملیں');
    final tryAdjustingLabel = TranslationHelper.t('Try adjusting your filters or adding items to your inventory', 'اپنی فلٹرز کو ایڈجسٹ کرنے یا اپنی انوینٹری میں آئٹمز شامل کرنے کی کوشش کریں');
    final clearFiltersLabel = TranslationHelper.t('Clear Filters', 'فلٹرز صاف کریں');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search,
              size: 150.0,
              color: iconColor,
            ),
            const SizedBox(height: 30.0),
            Text(
              noRecipesFoundLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                color: textColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              tryAdjustingLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(clearFiltersLabel),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorLoadingLabel = TranslationHelper.t('Error Loading Recipes', 'ریسیپیز لوڈ کرنے میں خرابی');
    final retryLabel = TranslationHelper.t('Retry', 'دوبارہ کوشش کریں');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 150.0,
              color: Colors.red[300],
            ),
            const SizedBox(height: 30.0),
            Text(
              errorLoadingLabel,
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _fetchRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: Text(retryLabel),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final findingRecipesLabel = TranslationHelper.t('Finding recipes based on your inventory...', 'آپ کی انوینٹری کی بنیاد پر ریسیپیز تلاش کی جا رہی ہے...');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              findingRecipesLabel, 
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    final recipesTitle = TranslationHelper.t('Recipes', 'ریسیپیز');
    
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
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainHomeScreen()),
            );
          },
        ),
        title: Text(recipesTitle, style: TextStyle(color: textColor)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.filter_list, size: 28.0, color: textColor),
            onPressed: () => _navigateToFilterScreen(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 28.0, color: textColor),
            onPressed: _fetchRecipes,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChip(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _hasError
                    ? _buildErrorState()
                    : _recipes.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _fetchRecipes(),
                            child: ListView.builder(
                              itemCount: _recipes.length,
                              itemBuilder: (context, index) {
                                return _buildRecipeCard(_recipes[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}