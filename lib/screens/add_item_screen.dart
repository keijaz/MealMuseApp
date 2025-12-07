import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';

// The primary color derived from the selected 'Vegetable' pill in the screenshot
const Color primaryColor = Color(0xFF5B8A8A);
const Color backgroundColor = Color(0xFFFFFFFF);
// The light gray background color for input fields and unselected pills
const Color cardColor = Color(0xFFF0F0F0);

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // State variable to hold the currently selected category (null if none selected)
  String? _selectedCategory;
  
  // State variable to hold the currently selected quantity unit
  String _selectedUnit = 'units';
  
  // Text editing controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _categoryOptions = [
    'Fruit',
    'Protein',
    'Vegetable',
    'Dairy',
    'Grain',
    'Beverage',
    'Snack',
    'Spices',
    'Other'
  ];
  
  // Unit conversion factors (to base unit)
  final Map<String, double> _unitConversionFactors = {
    // Weight units (base: grams)
    'grams': 1.0,
    'g': 1.0,
    'gram': 1.0,
    'kgs': 1000.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'lbs': 453.592,
    'lb': 453.592,
    'pound': 453.592,
    'pounds': 453.592,
    'oz': 28.3495,
    'ounce': 28.3495,
    'ounces': 28.3495,
    
    // Volume units (base: milliliters)
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'liters': 1000.0,
    'liter': 1000.0,
    'l': 1000.0,
    'tablespoon': 14.7868,
    'tbsp': 14.7868,
    'tablespoons': 14.7868,
    'teaspoon': 4.92892,
    'tsp': 4.92892,
    'teaspoons': 4.92892,
    'cups': 236.588,
    'cup': 236.588,
    'fl oz': 29.5735,
    'fluid ounce': 29.5735,
    'fluid ounces': 29.5735,
    
    // Count units (base: units)
    'units': 1.0,
    'unit': 1.0,
    'items': 1.0,
    'item': 1.0,
    'pieces': 1.0,
    'piece': 1.0,
    'pcs': 1.0,
    'pc': 1.0,
    '': 1.0,
  };

  final List<String> _unitOptions = [
    'units',
    'grams',
    'KGs',
    'liters',
    'ml'
    'lbs',
    'tbsp',
    'tsp',
    'cups'
    'oz',
  ];

  // Helper methods for unit conversion
  bool _isWeightUnit(String unit) {
    const weightUnits = {
      'g', 'gram', 'grams', 'kg', 'kgs', 'kilogram', 'kilograms', 
      'oz', 'ounce', 'ounces', 'lb', 'lbs', 'pound', 'pounds'
    };
    return weightUnits.contains(unit.toLowerCase().trim());
  }

  bool _isVolumeUnit(String unit) {
    const volumeUnits = {
      'ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters', 
      'cup', 'cups', 'tsp', 'teaspoon', 'teaspoons', 
      'tbsp', 'tablespoon', 'tablespoons', 
      'fl oz', 'fluid ounce', 'fluid ounces'
    };
    return volumeUnits.contains(unit.toLowerCase().trim());
  }

  bool _isCountUnit(String unit) {
    const countUnits = {
      '', 'item', 'items', 'piece', 'pieces', 'unit', 'units', 
      'pcs', 'pc'
    };
    return countUnits.contains(unit.toLowerCase().trim());
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
    
    // Check if both units belong to the same category
    return (_isWeightUnit(normalized1) && _isWeightUnit(normalized2)) ||
           (_isVolumeUnit(normalized1) && _isVolumeUnit(normalized2)) ||
           (_isCountUnit(normalized1) && _isCountUnit(normalized2));
  }

  // Get unit category
  String _getUnitCategory(String unit) {
    final normalizedUnit = unit.toLowerCase().trim();
    if (_isWeightUnit(normalizedUnit)) return 'weight';
    if (_isVolumeUnit(normalizedUnit)) return 'volume';
    if (_isCountUnit(normalizedUnit)) return 'count';
    return 'count';
  }

  // Base units for each category
  String _getBaseUnit(String unit) {
    final normalizedUnit = unit.toLowerCase().trim();
    
    if (_isWeightUnit(normalizedUnit)) return 'grams';
    if (_isVolumeUnit(normalizedUnit)) return 'ml';
    if (_isCountUnit(normalizedUnit)) return 'units';
    
    return 'units'; // default
  }

  // Convert quantity from one unit to another
  double _convertQuantity(double quantity, String fromUnit, String toUnit) {
    if (fromUnit.toLowerCase().trim() == toUnit.toLowerCase().trim()) {
      return quantity;
    }
    
    final fromFactor = _unitConversionFactors[fromUnit.toLowerCase().trim()] ?? 1.0;
    final toFactor = _unitConversionFactors[toUnit.toLowerCase().trim()] ?? 1.0;
    
    if (fromFactor == 0 || toFactor == 0) return quantity;
    
    // Convert to base unit first, then to target unit
    final baseQuantity = quantity * fromFactor;
    return baseQuantity / toFactor;
  }

  // Format quantity for display (round to reasonable precision)
  String _formatQuantity(double quantity, String unit) {
    if (quantity == quantity.truncateToDouble()) {
      return quantity.toInt().toString();
    }
    
    // For very small quantities, show more decimal places
    if (quantity < 1) {
      return quantity.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    // For larger quantities, show fewer decimal places
    if (quantity < 10) {
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    return quantity.toStringAsFixed(1).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // Choose the best display unit based on quantity
  String _chooseBestDisplayUnit(double baseQuantity, String unitCategory) {
    if (unitCategory == 'weight') {
      if (baseQuantity >= 1000) return 'KGs';
      if (baseQuantity >= 1) return 'grams';
      return 'grams';
    } else if (unitCategory == 'volume') {
      if (baseQuantity >= 1000) return 'liters';
      if (baseQuantity >= 1) return 'ml';
      return 'ml';
    }
    
    return 'units';
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

  // Helper to translate category names
  String _translateCategory(String category) {
    final isUrdu = LocaleProvider().localeNotifier.value?.languageCode == 'ur';
    if (!isUrdu) return category; // Keep English labels in English mode
    const categoryMapUrdu = {
      'Fruit': 'پھل',
      'Protein': 'پروٹین',
      'Vegetable': 'سبزی',
      'Dairy': 'ڈیری',
      'Grain': 'اناج',
      'Beverage': 'مشروب',
      'Snack': 'اسنیکس',
      'Spices': 'مسالے',
      'Other': 'دوسرا',
    };
    return categoryMapUrdu[category] ?? category;
  }

  // Save item to Firebase with duplicate checking and unit conversion
  Future<void> _saveItemToInventory() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog(TranslationHelper.t('Authentication Error', 'توثیق کی خرابی'), TranslationHelper.t('Please log in to add items.', 'براہ کرم اشیاء شامل کرنے کے لیے لاگ ان کریں۔'));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog(TranslationHelper.t('Missing Information', 'معلومات موجود نہیں'), TranslationHelper.t('Item name is required.', 'چیز کا نام ضروری ہے۔'));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final String itemName = _nameController.text.trim().toLowerCase();
      final String originalName = _nameController.text.trim();
      final double newQuantity = _parseQuantity(_quantityController.text.trim());
      final String newUnit = _selectedUnit;
      final String? category = _selectedCategory;
      final String purchaseDate = _purchaseDateController.text.trim();
      final String expiryDate = _expiryDateController.text.trim();
      final String notes = _notesController.text.trim();

      // Check if item already exists in inventory
      final existingItemsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .where('name', isEqualTo: itemName)
          .get();

      if (existingItemsQuery.docs.isNotEmpty) {
        // Item exists - handle unit conversion and merging
        final existingDoc = existingItemsQuery.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final double existingQuantity = _parseQuantity(existingData['quantity'] ?? '1');
        final String existingUnit = (existingData['unit'] ?? '').toString();
        final String existingCategory = existingData['category'] ?? 'Other';
        
        // Check if units are compatible for merging
        if (_areUnitsCompatible(existingUnit, newUnit)) {
          // Convert both quantities to a common base unit and merge
          final String baseUnit = _getBaseUnit(existingUnit);
          final String unitCategory = _getUnitCategory(existingUnit);
          
          // Convert existing quantity to base unit
          final double existingInBase = _convertQuantity(existingQuantity, existingUnit, baseUnit);
          
          // Convert new quantity to base unit
          final double newInBase = _convertQuantity(newQuantity, newUnit, baseUnit);
          
          // Merge quantities in base unit
          final double mergedInBase = existingInBase + newInBase;
          
          // Choose the best display unit for the merged quantity
          final String bestDisplayUnit = _chooseBestDisplayUnit(mergedInBase, unitCategory);
          
          // Convert back to the best display unit
          final double mergedQuantity = _convertQuantity(mergedInBase, baseUnit, bestDisplayUnit);
          final String displayQuantity = _formatQuantity(mergedQuantity, bestDisplayUnit);
          
          // Combine notes if both have notes
          String combinedNotes = existingData['notes'] ?? '';
          if (notes.isNotEmpty) {
            combinedNotes = combinedNotes.isEmpty 
                ? notes 
                : '$combinedNotes\n$notes';
          }

          // Update existing item with merged quantity
          final updateData = {
            'quantity': displayQuantity,
            'unit': bestDisplayUnit,
            'updatedAt': FieldValue.serverTimestamp(),
            'notes': combinedNotes.isNotEmpty ? combinedNotes : null,
          };

          // Only update category if it's not set in existing item
          if (existingCategory == 'Other' && category != null) {
            updateData['category'] = category;
          }

          // Update purchase date if not set in existing item
          if ((existingData['purchaseDate'] == null || existingData['purchaseDate'].toString().isEmpty) && purchaseDate.isNotEmpty) {
            updateData['purchaseDate'] = purchaseDate;
          }

          // Update expiry date if not set in existing item or use the later date
          if (expiryDate.isNotEmpty) {
            final existingExpiry = existingData['expiryDate']?.toString();
            if (existingExpiry == null || existingExpiry.isEmpty) {
              updateData['expiryDate'] = expiryDate;
            } else {
              // Use the later expiry date
              try {
                final existingExpiryDate = DateTime.parse(existingExpiry);
                final newExpiryDate = DateTime.parse(expiryDate);
                if (newExpiryDate.isAfter(existingExpiryDate)) {
                  updateData['expiryDate'] = expiryDate;
                }
              } catch (e) {
                // If date parsing fails, keep existing expiry date
              }
            }
          }

          // Remove null values
          updateData.removeWhere((key, value) => value == null);

          await existingDoc.reference.update(updateData);

          // Dismiss loading indicator
          Navigator.of(context).pop();

          // Show success message with conversion details
          _showSuccessDialog(
            message: '${TranslationHelper.t('Updated', 'اپ ڈیٹ کیا گیا')} $originalName: $existingQuantity $existingUnit + $newQuantity $newUnit = $displayQuantity $bestDisplayUnit'
          );
          
        } else {
          // Units are incompatible - add as new item
          await _addNewItemToInventory(
            name: itemName,
            originalName: originalName,
            quantity: newQuantity.toString(),
            unit: newUnit,
            category: category ?? 'Other',
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            notes: '$notes ${TranslationHelper.t('(Different unit from existing item)', '(موجودہ چیز سے مختلف یونٹ)')}'.trim(),
          );
        }
      } else {
        // Item doesn't exist - add new item
        await _addNewItemToInventory(
          name: itemName,
          originalName: originalName,
          quantity: newQuantity.toString(),
          unit: newUnit,
          category: category ?? 'Other',
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
          notes: notes,
        );
      }
      
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorDialog(TranslationHelper.t('Error', 'خرابی'), '${TranslationHelper.t('Failed to save item', 'چیز کو محفوظ کرنے میں ناکامی')}: $e');
    }
  }

  // Helper method to add new item to inventory
  Future<void> _addNewItemToInventory({
    required String name,
    required String originalName,
    required String quantity,
    required String unit,
    required String? category,
    required String purchaseDate,
    required String expiryDate,
    required String notes,
  }) async {
    final user = _auth.currentUser!;

    // Prepare item data
    final itemData = {
      'name': name,
      'originalName': originalName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'purchaseDate': purchaseDate.isNotEmpty ? purchaseDate : null,
      'expiryDate': expiryDate.isNotEmpty ? expiryDate : null,
      'notes': notes.isNotEmpty ? notes : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
    };

    // Remove null values from the map
    itemData.removeWhere((key, value) => value == null);

    // Save to Firebase
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .add(itemData);

    // TODO: TESTING ONLY - Check notifications for newly added item
    final notificationService = NotificationService();
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (notificationsEnabled) {
      await notificationService.checkExpiringItems();
    }

    // Dismiss loading indicator
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Show success message
    _showSuccessDialog();
  }

  void _showErrorDialog(String title, String content) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Text(content, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
            ),
          ],
        );
      },
    );
  }

  // Updated success dialog to accept custom message
  void _showSuccessDialog({String? message}) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(TranslationHelper.t('Success', 'کامیابی'), style: TextStyle(color: textColor)),
          content: Text(
            message ?? TranslationHelper.t('Item added to inventory successfully!', 'چیز انوینٹری میں کامیابی سے شامل کی گئی!'), 
            style: TextStyle(color: textColor)
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
            ),
          ],
        );
      },
    );
  }

  // Helper to translate field labels
  String _getUrduLabel(String label) {
    const labelMap = {
      'Name': 'نام',
      'Category': 'قسم',
      'Quantity': 'مقدار',
      'Purchase Date': 'خریداری کی تاریخ',
      'Expiry Date': 'میعاد ختم ہونے کی تاریخ',
      'Notes': 'نوٹس',
    };
    return labelMap[label] ?? label;
  }

  // Helper widget to consistently style section titles
  Widget _buildSectionTitle(String title) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          // fontWeight removed due to analyzer constraint
          color: textColor,
        ),
      ),
    );
  }

  // Helper widget for date picker fields
  Widget _buildDatePickerField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(TranslationHelper.t(label, _getUrduLabel(label))),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      onSurface: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black,
                    ),
                    dialogBackgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            
            if (picked != null) {
              setState(() {
                controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: inputBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isEmpty ? hintText : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? hintColor : textColor,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for standard text inputs (Name, Date, Notes)
  Widget _buildCustomTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(TranslationHelper.t(label, _getUrduLabel(label))),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  // fontWeight removed due to analyzer constraint
                  color: Colors.red,
                ),
              ),
          ],
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // Section for category selection (using InkWell and Container for custom styling)
  Widget _buildCategorySection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final unselectedBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final unselectedText = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(TranslationHelper.t('Category', 'قسم')),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _categoryOptions.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : unselectedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _translateCategory(category),
                  style: TextStyle(
                    color: isSelected ? Colors.white : unselectedText,
                    // fontWeight removed due to analyzer constraint
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Section for Quantity (Number input + Unit Dropdown)
  Widget _buildQuantitySection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final dropdownIconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(TranslationHelper.t('Quantity', 'مقدار')),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: inputBorder),
                ),
                child: Row(
                  children: [
                    // Decrement button
                    IconButton(
                      icon: Icon(Icons.remove, color: textColor),
                      onPressed: () {
                        setState(() {
                          int current = int.tryParse(_quantityController.text) ?? 1;
                          if (current > 1) {
                            _quantityController.text = (current - 1).toString();
                          }
                        });
                      },
                    ),
                    // Text field
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: TranslationHelper.t('Amount', 'رقم'),
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          // Ensure minimum value of 1
                          int? num = int.tryParse(value);
                          if (num != null && num < 1) {
                            _quantityController.text = '1';
                          }
                        },
                      ),
                    ),
                    // Increment button
                    IconButton(
                      icon: Icon(Icons.add, color: textColor),
                      onPressed: () {
                        setState(() {
                          int current = int.tryParse(_quantityController.text) ?? 0;
                          _quantityController.text = (current + 1).toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: inputBorder),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _unitOptions.map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(
                        unit,
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedUnit = newValue;
                      });
                    }
                  },
                  style: TextStyle(fontSize: 16, color: textColor),
                  isExpanded: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final bgColor = isDarkMode ? const Color(0xFF121212) : backgroundColor;
    final appBarBg = isDarkMode ? const Color(0xFF1E1E1E) : backgroundColor;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 2,
        navContext: context,
      ),
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          TranslationHelper.t('Add', 'چیز شامل کریں'),
          style: TextStyle(
            color: textColor,
            // fontWeight removed due to analyzer constraint
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildCategorySection(),
              const SizedBox(height: 30),
              _buildCustomTextField(
                label: 'Name',
                hintText: TranslationHelper.t('eg. Apple', 'مثال کے طور پر سیب'),
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 30),
              _buildQuantitySection(),
              const SizedBox(height: 30),
              _buildDatePickerField(
                label: 'Purchase Date',
                hintText: TranslationHelper.t('YYYY-MM-DD', 'سال-ماہ-دن'),
                controller: _purchaseDateController,
              ),
              const SizedBox(height: 30),
              _buildDatePickerField(
                label: 'Expiry Date',
                hintText: TranslationHelper.t('YYYY-MM-DD', 'سال-ماہ-دن'),
                controller: _expiryDateController,
              ),
              const SizedBox(height: 30),
              _buildCustomTextField(
                label: 'Notes',
                hintText: '...',
                controller: _notesController,
                maxLines: 5,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _saveItemToInventory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    TranslationHelper.t('Add', 'شامل کریں'),
                    style: const TextStyle(
                      fontSize: 18,
                      // fontWeight removed due to analyzer constraint
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchaseDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}