import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import 'home.dart';
import 'api_service.dart';

// The main screen widget containing the recipe details
class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final String recipeId;
  
  const RecipeDetailScreen({
    super.key, 
    required this.recipe,
    required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? _recipeDetails;
  List<dynamic>? _recipeInstructions;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Set<String>? _pantryIngredients;
  Map<String, bool> _ingredientStatus = {};
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _loadPantryIngredients();
    _checkIfRecipeSaved();
  }

  Future<void> _loadPantryIngredients() async {
    try {
      final pantryIngredients = await ApiService.getPantryIngredientNames();
      setState(() {
        _pantryIngredients = pantryIngredients;
      });
    } catch (e) {
      print('Error loading pantry ingredients: $e');
    }
  }

  Future<void> _checkIfRecipeSaved() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check both 'id' (from API) and 'recipeId' (from saved recipes)
      final recipeId = widget.recipe['id'] ?? widget.recipe['recipeId'];
      if (recipeId == null) return;

      final existingRecipeQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .where('recipeId', isEqualTo: recipeId)
          .get();

      setState(() {
        _isSaved = existingRecipeQuery.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking if recipe is saved: $e');
    }
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      // Use the recipeId from the constructor
      final recipeId = widget.recipeId;
      if (recipeId.isEmpty) {
        throw Exception('Recipe ID not found');
      }

      // Convert String to int for the API calls
      final int recipeIdInt = int.tryParse(recipeId) ?? 0;
      if (recipeIdInt == 0) {
        throw Exception('Invalid Recipe ID: $recipeId');
      }

      // Fetch recipe details and instructions
      final details = await ApiService.fetchRecipeDetails(recipeIdInt);
      final instructions = await ApiService.fetchRecipeInstructions(recipeIdInt);

      // Calculate ingredient status
      _calculateIngredientStatus(details['extendedIngredients'] ?? []);

      setState(() {
        _recipeDetails = details;
        _recipeInstructions = instructions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _calculateIngredientStatus(List<dynamic> ingredients) {
    final statusMap = <String, bool>{};
    
    for (final ingredient in ingredients) {
      final ingredientName = (ingredient['nameClean']?.toString() ?? 
                             ingredient['name']?.toString() ?? 
                             ingredient['original']?.toString() ?? '')
                             .toLowerCase().trim();
      
      if (ingredientName.isNotEmpty && _pantryIngredients != null) {
        final isInPantry = _pantryIngredients!.any((pantryIngredient) =>
          pantryIngredient.contains(ingredientName) || 
          ingredientName.contains(pantryIngredient)
        );
        statusMap[ingredientName] = isInPantry;
      } else {
        statusMap[ingredientName] = false;
      }
    }
    
    setState(() {
      _ingredientStatus = statusMap;
    });
  }

  // Helper method to get ingredients from recipe details
  List<dynamic> get _ingredients {
    return _recipeDetails?['extendedIngredients'] ?? [];
  }

  // Helper method to get recipe instructions
  List<dynamic> get _instructions {
    if (_recipeInstructions == null || _recipeInstructions!.isEmpty) {
      return [];
    }
    return _recipeInstructions!.first['steps'] ?? [];
  }

  // Helper method to get cooking time
  int get _cookingTime {
    return _recipeDetails?['readyInMinutes'] ?? 0;
  }

  // Helper method to get servings
  int get _servings {
    return _recipeDetails?['servings'] ?? 0;
  }

  // Helper method to get nutrition information
  Map<String, dynamic>? get _nutrition {
    return _recipeDetails?['nutrition'];
  }

  // Helper method to get specific nutrient value
  double _getNutrientValue(String nutrientName) {
    if (_nutrition == null) return 0.0;
    
    final List<dynamic> nutrients = _nutrition!['nutrients'] ?? [];
    for (final nutrient in nutrients) {
      if (nutrient['name']?.toString().toLowerCase().contains(nutrientName.toLowerCase()) == true) {
        return (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to check if ingredient is in pantry
  bool _isIngredientInPantry(dynamic ingredient) {
    final ingredientName = (ingredient['nameClean']?.toString() ?? 
                           ingredient['name']?.toString() ?? 
                           ingredient['original']?.toString() ?? '')
                           .toLowerCase().trim();
    
    return _ingredientStatus[ingredientName] ?? false;
  }

  // Helper method to get missing ingredients
  List<dynamic> _getMissingIngredients() {
    final List<dynamic> missingIngredients = [];
    
    for (final ingredient in _ingredients) {
      if (!_isIngredientInPantry(ingredient)) {
        missingIngredients.add(ingredient);
      }
    }
    
    return missingIngredients;
  }

  // Method to add missing ingredients to grocery list with duplicate checking
  void _addMissingIngredientsToGroceryList(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items to grocery list'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get missing ingredients
      final List<dynamic> missingIngredients = _getMissingIngredients();
      
      if (missingIngredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No missing ingredients to add!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Get existing grocery items
      final existingItemsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .where('isChecked', isEqualTo: false)
          .get();

      final Map<String, DocumentSnapshot> existingItemsMap = {};
      for (final doc in existingItemsQuery.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase().trim();
        existingItemsMap[name] = doc;
      }

      int addedCount = 0;
      int updatedCount = 0;
      final batch = FirebaseFirestore.instance.batch();
      
      for (final ingredient in missingIngredients) {
        final ingredientName = (ingredient['nameClean'] ?? ingredient['name'] ?? ingredient['original'] ?? 'Unknown')
            .toString().toLowerCase().trim();
        final double newAmount = (ingredient['amount'] as num?)?.toDouble() ?? 1.0;
        final String newUnit = (ingredient['unit'] ?? '').toString().toLowerCase().trim();
        
        // Check if item already exists in grocery list
        if (existingItemsMap.containsKey(ingredientName)) {
          // Item exists - update quantity
          final existingDoc = existingItemsMap[ingredientName]!;
          final existingData = existingDoc.data() as Map<String, dynamic>;
          final double existingAmount = _parseQuantity(existingData['amount'] ?? '1');
          final String existingUnit = (existingData['unit'] ?? '').toString().toLowerCase().trim();
          
          // Check if units are compatible for merging
          if (_areUnitsCompatible(existingUnit, newUnit)) {
            // Merge quantities
            final double mergedAmount = existingAmount + newAmount;
            final String displayUnit = existingUnit.isNotEmpty ? existingUnit : newUnit;
            
            batch.update(existingDoc.reference, {
              'amount': mergedAmount.toString(),
              'unit': displayUnit,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            updatedCount++;
          } else {
            // Units are incompatible - add as new item with note
            final groceryDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('grocery_list')
                .doc();
            
            batch.set(groceryDoc, {
              'name': ingredientName,
              'originalName': ingredientName.capitalize(),
              'amount': newAmount.toString(),
              'unit': newUnit,
              'recipeSource': '${widget.recipe['title'] ?? 'Unknown Recipe'} (different unit)',
              'recipeId': widget.recipeId,
              'category': _categorizeIngredient(ingredientName),
              'isChecked': false,
              'createdAt': FieldValue.serverTimestamp(),
              'userId': user.uid,
            });
            addedCount++;
          }
        } else {
          // Item doesn't exist - add new item
          final groceryDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('grocery_list')
              .doc();
          
          batch.set(groceryDoc, {
            'name': ingredientName,
            'originalName': ingredientName.capitalize(),
            'amount': newAmount.toString(),
            'unit': newUnit,
            'recipeSource': widget.recipe['title'] ?? 'Unknown Recipe',
            'recipeId': widget.recipeId,
            'category': _categorizeIngredient(ingredientName),
            'isChecked': false,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
          addedCount++;
        }
      }

      await batch.commit();

      // Show appropriate success message
      String message = '';
      if (addedCount > 0 && updatedCount > 0) {
        message = 'Added $addedCount new items and updated $updatedCount existing items!';
      } else if (addedCount > 0) {
        message = 'Added $addedCount items to grocery list!';
      } else if (updatedCount > 0) {
        message = 'Updated quantities for $updatedCount existing items!';
      }

      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error adding to grocery list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add items: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Helper method to parse quantity from string to double
  double _parseQuantity(dynamic quantity) {
    if (quantity == null) return 1.0;
    if (quantity is num) return quantity.toDouble();
    if (quantity is String) {
      return double.tryParse(quantity) ?? 1.0;
    }
    return 1.0;
  }

  // Helper method to check if units are compatible for merging
  bool _areUnitsCompatible(String unit1, String unit2) {
    // Normalize units
    final normalized1 = unit1.toLowerCase().trim();
    final normalized2 = unit2.toLowerCase().trim();
    
    // If both units are empty or same, they're compatible
    if (normalized1 == normalized2) return true;
    
    // If one unit is empty, consider them compatible (assume same unit)
    if (normalized1.isEmpty || normalized2.isEmpty) return true;
    
    // Define compatible unit groups
    const weightUnits = {'g', 'gram', 'grams', 'kg', 'kilogram', 'kilograms', 'oz', 'ounce', 'ounces', 'lb', 'pound', 'pounds'};
    const volumeUnits = {'ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters', 'cup', 'cups', 'tsp', 'teaspoon', 'teaspoons', 'tbsp', 'tablespoon', 'tablespoons'};
    const countUnits = {'', 'item', 'items', 'piece', 'pieces', 'unit', 'units'};
    
    // Check if both units belong to the same category
    final isUnit1Weight = weightUnits.contains(normalized1);
    final isUnit2Weight = weightUnits.contains(normalized2);
    final isUnit1Volume = volumeUnits.contains(normalized1);
    final isUnit2Volume = volumeUnits.contains(normalized2);
    final isUnit1Count = countUnits.contains(normalized1);
    final isUnit2Count = countUnits.contains(normalized2);
    
    // Units are compatible if they belong to the same category
    return (isUnit1Weight && isUnit2Weight) ||
           (isUnit1Volume && isUnit2Volume) ||
           (isUnit1Count && isUnit2Count);
  }

  // Helper method to categorize ingredients
  String _categorizeIngredient(String ingredientName) {
    final name = ingredientName.toLowerCase();
    
    if (name.contains('apple') || name.contains('banana') || name.contains('orange') || 
        name.contains('berry') || name.contains('fruit') || name.contains('mango') ||
        name.contains('grape') || name.contains('pineapple') || name.contains('watermelon')) {
      return 'Fruits';
    } else if (name.contains('carrot') || name.contains('broccoli') || name.contains('spinach') || 
               name.contains('vegetable') || name.contains('lettuce') || name.contains('tomato') ||
               name.contains('potato') || name.contains('onion') || name.contains('garlic') ||
               name.contains('pepper') || name.contains('cucumber')) {
      return 'Vegetables';
    } else if (name.contains('chicken') || name.contains('beef') || name.contains('pork') || 
               name.contains('meat') || name.contains('fish') || name.contains('shrimp') ||
               name.contains('salmon') || name.contains('turkey') || name.contains('lamb') ||
               name.contains('protein')) {
      return 'Protein';
    } else if (name.contains('milk') || name.contains('cheese') || name.contains('yogurt') || 
               name.contains('dairy') || name.contains('egg') || name.contains('butter') ||
               name.contains('cream')) {
      return 'Dairy';
    } else if (name.contains('pasta') || name.contains('rice') || name.contains('bread') || 
               name.contains('flour') || name.contains('grain') || name.contains('oat') ||
               name.contains('cereal') || name.contains('quinoa')) {
      return 'Grains';
    } else if (name.contains('oil') || name.contains('vinegar') || name.contains('sauce') || 
               name.contains('spice') || name.contains('herb') || name.contains('salt') ||
               name.contains('pepper') || name.contains('sugar') || name.contains('honey')) {
      return 'Spices';
    } else if (name.contains('water') || name.contains('juice') || name.contains('soda') ||
               name.contains('coffee') || name.contains('tea')) {
      return 'Beverages';
    } else if (name.contains('chocolate') || name.contains('chip') || name.contains('cookie') ||
               name.contains('cracker') || name.contains('popcorn')) {
      return 'Snacks';
    } else {
      return 'Other';
    }
  }

  // Helper widget to build ingredient rows with status
  Widget _buildIngredientItemWithStatus(dynamic ingredient) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final presentColor = Colors.green[700];
    final missingColor = Colors.red[700];
    
    final name = ingredient['nameClean'] ?? ingredient['original'] ?? 'Unknown ingredient';
    final amount = ingredient['amount'] ?? '';
    final unit = ingredient['unit'] ?? '';
    final isInPantry = _isIngredientInPantry(ingredient);
  
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isInPantry ? Icons.check_circle : Icons.remove_circle,
            size: 16,
            color: isInPantry ? presentColor : missingColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${amount.toString()} $unit ${name.toString().capitalize()}',
              style: TextStyle(
                fontSize: 16.0, 
                height: 1.5, 
                color: textColor,
                fontWeight: isInPantry ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isInPantry 
                  ? presentColor!.withOpacity(0.1) 
                  : missingColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isInPantry ? presentColor! : missingColor!,
                width: 1,
              ),
            ),
            child: Text(
              isInPantry ? 'In Pantry' : 'Missing',
              style: TextStyle(
                fontSize: 10,
                color: isInPantry ? presentColor! : missingColor!,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build recipe steps
  Widget _buildRecipeStep(dynamic step) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    final stepNumber = step['number'] ?? 0;
    final stepText = step['step'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $stepNumber:',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stepText,
            style: TextStyle(fontSize: 16.0, height: 1.5, color: textColor),
          ),
        ],
      ),
    );
  }

  // Widget to build nutrition information section
  Widget _buildNutritionSection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700];
    
    // Get nutrient values
    final calories = _getNutrientValue('calories');
    final protein = _getNutrientValue('protein');
    final fat = _getNutrientValue('fat');
    final carbs = _getNutrientValue('carbohydrates');
    final fiber = _getNutrientValue('fiber');
    final sugar = _getNutrientValue('sugar');

    // If no nutrition data available, return empty container
    if (calories == 0.0 && protein == 0.0 && fat == 0.0 && carbs == 0.0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Facts',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nutrition Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Calories - Highlighted
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C8A94).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5C8A94).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Per Serving',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${calories.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5C8A94),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Macronutrients Grid
              Row(
                children: [
                  _buildMacronutrientCard(
                    'Protein',
                    '${protein.toStringAsFixed(1)}g',
                    Icons.fitness_center,
                    const Color(0xFF4CAF50),
                    isDarkMode,
                  ),
                  const SizedBox(width: 12),
                  _buildMacronutrientCard(
                    'Carbs',
                    '${carbs.toStringAsFixed(1)}g',
                    Icons.grain,
                    const Color(0xFF2196F3),
                    isDarkMode,
                  ),
                  const SizedBox(width: 12),
                  _buildMacronutrientCard(
                    'Fat',
                    '${fat.toStringAsFixed(1)}g',
                    Icons.water_drop,
                    const Color(0xFFFF9800),
                    isDarkMode,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Additional Nutrients
              if (fiber > 0 || sugar > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (fiber > 0)
                        _buildMicroNutrientItem('Fiber', '${fiber.toStringAsFixed(1)}g', isDarkMode),
                      if (fiber > 0 && sugar > 0)
                        Container(
                          width: 1,
                          height: 30,
                          color: isDarkMode ? const Color(0xFF404040) : Colors.grey[300],
                        ),
                      if (sugar > 0)
                        _buildMicroNutrientItem('Sugar', '${sugar.toStringAsFixed(1)}g', isDarkMode),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // Helper widget for macronutrient cards
  Widget _buildMacronutrientCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for micro nutrient items
  Widget _buildMicroNutrientItem(String title, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Loading widget
  Widget _buildLoadingState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5C8A94)),
          const SizedBox(height: 20),
          Text(
            'Loading recipe details...',
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  // Error widget
  Widget _buildErrorState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Failed to load recipe details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchRecipeDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5C8A94),
              ),
              child: Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecipe(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to save recipes'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check both 'id' (from API) and 'recipeId' (from saved recipes)
      final recipeId = widget.recipe['id'] ?? widget.recipe['recipeId'];
      if (recipeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe ID not found'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if recipe already exists in saved recipes
      final existingRecipeQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .where('recipeId', isEqualTo: recipeId)
          .get();

      if (existingRecipeQuery.docs.isNotEmpty) {
        // Recipe already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe is already in your saved collection!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      // Recipe doesn't exist - save to Firebase Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .add({
        'recipeId': recipeId,
        'title': widget.recipe['title'] ?? 'Untitled Recipe',
        'image': widget.recipe['image'] ?? '',
        'likes': widget.recipe['likes'] ?? 0,
        'missedIngredientCount': widget.recipe['missedIngredientCount'] ?? 0,
        'usedIngredientCount': widget.recipe['usedIngredientCount'] ?? 0,
        'savedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe saved to your collection!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recipe: $e'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = Color(0xFF5C8A94);
    final bool hasMissingIngredients = _getMissingIngredients().isNotEmpty;

    if (_isLoading) {
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
      final iconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildLoadingState(),
      );
    }

    if (_hasError) {
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
      final iconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildErrorState(),
      );
    }

    // Use data from the original recipe card as fallback
    final String recipeTitle = _recipeDetails?['title'] ?? widget.recipe['title'] ?? 'Delicious Recipe';
    final String recipeImage = _recipeDetails?['image'] ?? widget.recipe['image'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1780&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    final int likes = widget.recipe['likes'] ?? 0;

    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scrollable Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Image Section (Rectangular Full Width)
                  Container(
                    width: double.infinity,
                    height: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        recipeImage,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(color: buttonColor),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // 2. Title
                  Text(
                    recipeTitle,
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Metadata
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Likes: $likes',
                        style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready in: $_cookingTime minutes',
                        style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Servings: $_servings',
                        style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                      ),
                    ],
                  ),
                  
                  Divider(height: 32, thickness: 1, color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                  
                  // --- Nutrition Section ---
                  _buildNutritionSection(),
                  
                  // --- Ingredients Section ---
                  Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_ingredients.isNotEmpty)
                    ..._ingredients.map(_buildIngredientItemWithStatus)
                  else
                    Text(
                      'No ingredient information available',
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),

                  const SizedBox(height: 32),

                  // --- Recipe Instructions Section ---
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  if (_instructions.isNotEmpty)
                    ..._instructions.map(_buildRecipeStep)
                  else
                    Text(
                      'No instruction information available',
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),

                  // Add bottom padding to ensure content doesn't get hidden behind buttons
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed Bottom Buttons Area
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add to Grocery List Button
            if (hasMissingIngredients)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => _addMissingIngredientsToGroceryList(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5C8A94),
                    side: const BorderSide(color: Color(0xFF5C8A94), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Missing Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5C8A94),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (hasMissingIngredients) const SizedBox(height: 12),
            
            // Save Recipe Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaved ? null : () {
                  _saveRecipe(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? Colors.grey : buttonColor,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _isSaved ? 'Saved' : 'Save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}