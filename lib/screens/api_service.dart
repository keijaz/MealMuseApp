// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String _baseUrl = 'https://api.spoonacular.com';
  static const String _apiKey = '6d495b2ad5f74b1b8fb8536e2d5beeca';
  // static const String _apiKey = 'ed8a53e2f8484d7f8daebe22b7e613bc';
  // static String get _apiKey {
  //   return dotenv.get('SPOONACULAR_API_KEY');
  // }
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('api.spoonacular.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Get inventory ingredients for current user
  static Future<List<String>> getInventoryIngredients() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final ingredients = querySnapshot.docs
          .map((doc) => doc.data()['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .map((name) => name!.toLowerCase())
          .toList();

      print('Found inventory ingredients: $ingredients');
      return ingredients;
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  // Add this method to ApiService class
  static Future<Set<String>> getPantryIngredientNames() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final ingredientNames = querySnapshot.docs
          .map((doc) => doc.data()['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .map((name) => name!.toLowerCase().trim())
          .toSet();

      print('Found pantry ingredient names: $ingredientNames');
      return ingredientNames;
    } catch (e) {
      print('Error fetching pantry ingredient names: $e');
      return {};
    }
  }

  // Fetch recipes using complexSearch with filters
  static Future<List<dynamic>> fetchRecipesWithComplexSearch({
  required String sort,
  List<String> diets = const [],
  List<String> intolerances = const [],
  int number = 10,
}) async {
  try {
    // Check internet connection first
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network settings.');
    }

    // Get ingredients from inventory for query
    final ingredients = await getInventoryIngredients();
    
    // Build query parameters
    final params = <String, String>{
      'number': number.toString(),
      'apiKey': _apiKey,
      'sort': sort,
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'ranking': '2', // Maximize used ingredients
    };

    // Add diet filter if selected
    if (diets.isNotEmpty) {
      params['diet'] = diets.first;
      print('Applied diet filter: ${diets.first}');
    }

    // Add intolerance filter if selected
    if (intolerances.isNotEmpty) {
      params['intolerances'] = intolerances.join(',');
      print('Applied intolerances: ${intolerances.join(',')}');
    }

    // STRATEGY 1: Try with inventory ingredients first
    if (ingredients.isNotEmpty) {
      // Use a reasonable number of ingredients
      final uniqueIngredients = ingredients.toSet().take(8).toList();
      params['includeIngredients'] = uniqueIngredients.join(',');
      print('Trying with inventory ingredients: ${uniqueIngredients.join(', ')}');
    }

    // Build the URL
    final url = Uri.parse('$_baseUrl/recipes/complexSearch').replace(
      queryParameters: params,
    );

    print('ComplexSearch API Request URL: ${url.toString()}');

    // Make the API call with timeout
    final response = await http.get(url).timeout(const Duration(seconds: 30));

    print('ComplexSearch API Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> recipes = data['results'] ?? [];
      final int totalResults = data['totalResults'] ?? 0;
      
      print('Received ${recipes.length} recipes from complexSearch (Total available: $totalResults)');
      
      // FALLBACK: If no recipes found with inventory, try without inventory (just filters)
      if (recipes.isEmpty && ingredients.isNotEmpty) {
        print('No recipes found with inventory ingredients. Falling back to filters only...');
        return await _fallbackToFiltersOnly(
          sort: sort,
          diets: diets,
          intolerances: intolerances,
          number: number,
        );
      }
      
      return recipes;
    } else {
      print('ComplexSearch API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching recipes with complexSearch: $e');
    throw e;
  }
}

// Fallback method that uses only filters (no inventory ingredients)
  static Future<List<dynamic>> _fallbackToFiltersOnly({
    required String sort,
    required List<String> diets,
    required List<String> intolerances,
    required int number,
  }) async {
    try {
      print('Trying fallback: Using only filters without inventory ingredients');
      
      // Build query parameters WITHOUT includeIngredients
      final params = <String, String>{
        'number': number.toString(),
        'apiKey': _apiKey,
        'sort': sort,
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
      };

      // Add diet filter if selected
      if (diets.isNotEmpty) {
        params['diet'] = diets.first;
        print('Fallback - Applied diet filter: ${diets.first}');
      }

      // Add intolerance filter if selected
      if (intolerances.isNotEmpty) {
        params['intolerances'] = intolerances.join(',');
        print('Fallback - Applied intolerances: ${intolerances.join(',')}');
      }

      // Build the URL
      final url = Uri.parse('$_baseUrl/recipes/complexSearch').replace(
        queryParameters: params,
      );

      print('Fallback API Request URL: ${url.toString()}');

      // Make the API call with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      print('Fallback API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> recipes = data['results'] ?? [];
        final int totalResults = data['totalResults'] ?? 0;
        
        print('Fallback received ${recipes.length} recipes (Total available: $totalResults)');
        
        if (recipes.isNotEmpty) {
          print('Fallback successful! Found recipes using only filters');
        } else {
          print('No recipes found even with filters only');
        }
        
        return recipes;
      } else {
        print('Fallback API Error: ${response.statusCode} - ${response.body}');
        return []; // Return empty rather than throwing error in fallback
      }
    } catch (e) {
      print('Error in fallback: $e');
      return []; // Return empty rather than throwing error in fallback
    }
  }
  // Fetch detailed recipe information by ID
  // Update the fetchRecipeDetails method in ApiService class
  static Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      // Build the URL for recipe details WITH nutrition data
      final url = Uri.parse(
          '$_baseUrl/recipes/$recipeId/information?'
          'includeNutrition=true&'  // Changed from false to true
          'apiKey=$_apiKey'
        );

        print('Recipe Details API Request URL: $url');

        // Make the API call with timeout
        final response = await http.get(url).timeout(const Duration(seconds: 30));

        print('Recipe Details API Response Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> recipeDetails = json.decode(response.body);
          print('Received detailed recipe information with nutrition data');
          
          // Debug: Check if nutrition data exists
          if (recipeDetails.containsKey('nutrition')) {
            print('Nutrition data found: ${recipeDetails['nutrition']}');
          } else {
            print('No nutrition data in response');
          }
          
          return recipeDetails;
        } else {
          print('Recipe Details API Error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to load recipe details: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching recipe details: $e');
        throw e;
      }
    }

  // Fetch recipe instructions by ID
  static Future<List<dynamic>> fetchRecipeInstructions(int recipeId) async {
    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      // Build the URL for recipe instructions
      final url = Uri.parse(
        '$_baseUrl/recipes/$recipeId/analyzedInstructions?'
        'apiKey=$_apiKey'
      );

      print('Recipe Instructions API Request URL: $url');

      // Make the API call with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      print('Recipe Instructions API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> instructions = json.decode(response.body);
        print('Received recipe instructions');
        return instructions;
      } else {
        print('Recipe Instructions API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipe instructions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe instructions: $e');
      throw e;
    }
  }

  // Fetch recipes by ingredients
  static Future<List<dynamic>> fetchRecipesByIngredients({
    int number = 10,
    int ranking = 1,
    bool ignorePantry = false,
  }) async {
    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      // Get ingredients from inventory
      final ingredients = await getInventoryIngredients();
      
      if (ingredients.isEmpty) {
        print('No ingredients found in inventory');
        return [];
      }

      // Convert ingredients list to comma-separated string
      final ingredientsString = ingredients.join(',');
      print('Ingredients for API: $ingredientsString');

      // Build the URL with parameters
      final url = Uri.parse(
        '$_baseUrl/recipes/findByIngredients?'
        'ingredients=$ingredientsString&'
        'number=$number&'
        'ranking=$ranking&'
        'ignorePantry=$ignorePantry&'
        'apiKey=$_apiKey'
      );

      print('API Request URL: $url');

      // Make the API call with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> recipes = json.decode(response.body);
        print('Received ${recipes.length} recipes');
        return recipes;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw e;
    }
  }
}