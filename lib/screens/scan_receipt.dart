import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Accent color
const Color accentColor = Color(0xFF5C8A94);

// Currency symbols with PKR as default
const Map<String, String> _currencySymbols = {
  'PKR': 'Rs ',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'CAD': 'C\$',
  'AUD': 'A\$',
  'JPY': '¥',
  'INR': '₹',
  'SAR': 'ر.س',
};

String getCurrencySymbol(String currencyCode) {
  return _currencySymbols[currencyCode] ?? currencyCode;
}

void main() {
  runApp(ScanRec());
}

class ScanRec extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light().copyWith(
          primary: accentColor,
          secondary: accentColor,
        ),
        useMaterial3: true,
      ),
      home: ReceiptScannerScreen(),
    );
  }
}

class ReceiptItem {
  String name;
  double quantity;
  double price;
  String category;
  String? unit;
  String? expiryDate;
  String? notes;
  
  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    this.unit,
    this.expiryDate,
    this.notes,
  });
  
  // Parse unit from item name
  String detectUnit() {
    final lowerName = name.toLowerCase();
    
    final unitPatterns = {
      'KGs': RegExp(r'(\d+(\.\d+)?)\s*(kg|kgs|kilogram|kilograms)\b', caseSensitive: false),
      'grams': RegExp(r'(\d+(\.\d+)?)\s*(g|gram|grams)\b', caseSensitive: false),
      'lbs': RegExp(r'(\d+(\.\d+)?)\s*(lb|lbs|pound|pounds)\b', caseSensitive: false),
      'oz': RegExp(r'(\d+(\.\d+)?)\s*(oz|ounce|ounces)\b', caseSensitive: false),
      'liters': RegExp(r'(\d+(\.\d+)?)\s*(l|liter|liters)\b', caseSensitive: false),
      'ml': RegExp(r'(\d+(\.\d+)?)\s*(ml|milliliter|milliliters)\b', caseSensitive: false),
      'cups': RegExp(r'(\d+(\.\d+)?)\s*(cup|cups)\b', caseSensitive: false),
      'tbsp': RegExp(r'(\d+(\.\d+)?)\s*(tbsp|tablespoon|tablespoons)\b', caseSensitive: false),
      'tsp': RegExp(r'(\d+(\.\d+)?)\s*(tsp|teaspoon|teaspoons)\b', caseSensitive: false),
    };
    
    for (var entry in unitPatterns.entries) {
      if (entry.value.hasMatch(lowerName)) {
        return entry.key;
      }
    }
    
    if (quantity % 1 != 0) {
      if (category == 'Vegetable' || category == 'Fruit') {
        if (quantity < 10) return 'KGs';
        if (quantity < 100) return 'grams';
      }
      return 'grams';
    }
    
    if (category == 'Beverage') return 'liters';
    if (category == 'Spices') return 'tsp';
    if (category == 'Dairy') {
      if (lowerName.contains('milk') || lowerName.contains('yogurt')) return 'liters';
      return 'units';
    }
    
    return 'units';
  }
  
  Map<String, dynamic> toMap({String currency = 'PKR'}) {
    // Add currency info to notes
    String finalNotes = notes ?? '';
    if (finalNotes.isNotEmpty) {
      finalNotes += ' | Currency: $currency';
    } else {
      finalNotes = 'Currency: $currency';
    }
    
    return {
      'name': name,
      'quantity': quantity.toString(),
      'price': price.toStringAsFixed(2),
      'category': category,
      'unit': unit ?? detectUnit(),
      'expiryDate': expiryDate ?? _calculateDefaultExpiryDate(),
      'notes': finalNotes,
    };
  }
  
  String _calculateDefaultExpiryDate() {
    final now = DateTime.now();
    final expiryDays = {
      'Vegetable': 10,
      'Fruit': 7,
      'Protein': 5,
      'Dairy': 14,
      'Grain': 30,
      'Beverage': 30,
      'Snack': 60,
      'Spices': 180,
      'Other': 30,
    };
    final days = expiryDays[category] ?? 30;
    return now.add(Duration(days: days)).toIso8601String().split('T')[0];
  }
  
  @override
  String toString() {
    return '$name (${quantity}x) - Rs ${price.toStringAsFixed(2)}';
  }
}

class VeryfiService {
  static const String _baseUrl = 'https://api.veryfi.com/api/v8';
  
  String get _clientId => '';
  String get _username => '';
  String get _apiKey => '';
  
  Future<List<ReceiptItem>> scanReceipt(File imageFile) async {
    print("Starting receipt scan...");
    
    final bool hasValidKeys = _clientId.isNotEmpty && 
                             _username.isNotEmpty && 
                             _apiKey.isNotEmpty;
    
    if (!hasValidKeys) {
      print("API keys not configured. Cannot scan receipt.");
      throw Exception('API keys not configured. Please add your Veryfi API credentials.');
    }
    
    print("Using Veryfi API with configured keys");
    
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'CLIENT-ID': _clientId,
        'AUTHORIZATION': 'apikey $_username:$_apiKey',
      };
      
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/partner/documents/'));
      request.headers.addAll(headers);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      request.fields.addAll({
        'auto_delete': 'true',
        'boost_mode': 'true',
      });
      
      print("Sending request to Veryfi API...");
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final items = _parseReceiptItems(data);
        print("Successfully parsed ${items.length} items");
        return items;
      } else {
        print("API Error ${response.statusCode}: $responseBody");
        throw Exception('API Error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      print('Veryfi API Error: $e');
      throw Exception('Failed to scan receipt: $e');
    }
  }
  
  List<ReceiptItem> _parseReceiptItems(Map<String, dynamic> response) {
    final List<ReceiptItem> items = [];
    
    // Extract currency from response (default to PKR)
    final String receiptCurrency = response['currency_code']?.toString() ?? 'PKR';
    
    if (response.containsKey('line_items')) {
      final lineItems = response['line_items'] as List;
      
      for (var item in lineItems) {
        String name = _cleanItemName(item['description']?.toString() ?? 'Unknown Item');
        double quantity = (item['quantity'] ?? 1).toDouble();
        double price = (item['total'] ?? 0.0).toDouble();
        
        if (_isValidGroceryItem(name) && price > 0) {
          items.add(ReceiptItem(
            name: name,
            quantity: quantity,
            price: price,
            category: _categorizeItem(name),
            notes: 'Currency: $receiptCurrency', // Store currency in notes
          ));
        }
      }
    }
    
    return items;
  }
  
  String _cleanItemName(String rawName) {
    final junkWords = ['tax', 'total', 'subtotal', 'vat', 'gst', 'balance', 'change', 'amount'];
    String cleaned = rawName.toLowerCase();
    
    for (var word in junkWords) {
      cleaned = cleaned.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (cleaned.isEmpty) return 'Unknown Item';
    
    return cleaned.split(' ').map((word) {
      if (word.length > 1) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word.toUpperCase();
    }).join(' ');
  }
  
  bool _isValidGroceryItem(String name) {
    if (name.isEmpty || name.length < 2) return false;
    
    final junkPatterns = [
      RegExp(r'^(total|subtotal|tax|vat|gst|balance|change|amount|card|cash|debit|credit|tip)', caseSensitive: false),
      RegExp(r'^\d+\.?\d*$'),
      RegExp(r'^[^a-zA-Z]+$'),
    ];
    
    for (var pattern in junkPatterns) {
      if (pattern.hasMatch(name.trim())) return false;
    }
    
    return true;
  }
  
  String _categorizeItem(String itemName) {
    final categories = {
      'Fruit': ['apple', 'banana', 'orange', 'grape', 'berry', 'mango', 'pineapple', 'watermelon', 'zuchinni'],
      'Vegetable': ['tomato', 'potato', 'onion', 'carrot', 'lettuce', 'broccoli', 'spinach', 'cabbage', 'zucchini'],
      'Protein': ['chicken', 'beef', 'fish', 'pork', 'meat', 'steak', 'bacon', 'egg'],
      'Dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'curd', 'paneer'],
      'Grain': ['bread', 'cake', 'pastry', 'cookie', 'biscuit', 'croissant', 'pasta', 'rice'],
      'Beverage': ['water', 'juice', 'soda', 'coffee', 'tea', 'drink'],
      'Snack': ['chips', 'candy', 'chocolate', 'cookies', 'nuts'],
      'Spices': ['salt', 'pepper', 'spice', 'herb', 'cumin', 'turmeric'],
    };
    
    final lowerName = itemName.toLowerCase();
    
    for (var category in categories.entries) {
      for (var keyword in category.value) {
        if (lowerName.contains(keyword)) {
          return category.key;
        }
      }
    }
    
    return 'Other';
  }
}

class ReceiptScannerScreen extends StatefulWidget {
  @override
  _ReceiptScannerScreenState createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final VeryfiService _veryfiService = VeryfiService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  List<ReceiptItem> _scannedItems = [];
  bool _isLoading = false;
  double _totalAmount = 0.0;
  String _receiptCurrency = 'PKR'; // Default to PKR

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    final buttonWidth = screenWidth * (isPortrait ? 0.9 : 0.4);
    final imageSize = screenWidth * (isPortrait ? 0.8 : 0.35);
    final fontSizeTitle = screenWidth * 0.06;
    final fontSizeNormal = screenWidth * 0.045;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receipt Scanner',
          style: TextStyle(fontSize: fontSizeTitle.clamp(18, 24)),
        ),
        centerTitle: true,
        backgroundColor: accentColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight * 0.8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Section: Image Preview and Scan Button
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (_selectedImage != null) ...[
                        Container(
                          height: imageSize,
                          width: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Receipt Preview',
                          style: TextStyle(
                            fontSize: fontSizeNormal.clamp(14, 18),
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: imageSize,
                          width: imageSize,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: screenWidth * 0.15,
                                color: Colors.grey[500],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'No receipt selected',
                                style: TextStyle(
                                  fontSize: fontSizeNormal.clamp(14, 16),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: screenHeight * 0.03),
                      
                      Wrap(
                        spacing: screenWidth * 0.03,
                        runSpacing: screenHeight * 0.015,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.camera_alt,
                            label: 'Take Photo',
                            width: buttonWidth,
                            onPressed: _takePhoto,
                            color: accentColor,
                          ),
                          _buildActionButton(
                            icon: Icons.photo_library,
                            label: 'Choose from Gallery',
                            width: buttonWidth,
                            onPressed: _pickImage,
                            color: accentColor,
                          ),
                          if (_selectedImage != null)
                            _buildActionButton(
                              icon: Icons.close,
                              label: 'Clear',
                              width: buttonWidth * 0.45,
                              onPressed: _clearImage,
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                if (_selectedImage != null && !_isLoading)
                  SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.scanner, size: screenWidth * 0.06),
                      label: Text(
                        'SCAN RECEIPT',
                        style: TextStyle(fontSize: fontSizeNormal.clamp(14, 18)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: _scanReceipt,
                    ),
                  ),
                
                SizedBox(height: screenHeight * 0.02),
                
                if (_isLoading)
                  Column(
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'Scanning receipt...',
                        style: TextStyle(
                          fontSize: fontSizeNormal.clamp(14, 16),
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                
                SizedBox(height: screenHeight * 0.03),
                
                if (_scannedItems.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Scanned Items (${_scannedItems.length})',
                                style: TextStyle(
                                  fontSize: fontSizeTitle.clamp(16, 22),
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Chip(
                                label: Text(
                                  'Total: ${getCurrencySymbol(_receiptCurrency)}${_totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: fontSizeNormal.clamp(14, 16),
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                backgroundColor: accentColor,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        ..._scannedItems.map((item) {
                          final unit = item.detectUnit();
                          // Extract currency from notes if available
                          String currencySymbol = getCurrencySymbol(_receiptCurrency);
                          if (item.notes != null && item.notes!.contains('Currency:')) {
                            final currencyMatch = RegExp(r'Currency:\s*(\w+)').firstMatch(item.notes!);
                            if (currencyMatch != null) {
                              currencySymbol = getCurrencySymbol(currencyMatch.group(1)!);
                            }
                          }
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: fontSizeNormal.clamp(14, 18),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '$currencySymbol${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: fontSizeNormal.clamp(14, 18),
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: screenHeight * 0.005),
                                
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: fontSizeNormal.clamp(11, 13),
                                        ),
                                      ),
                                      backgroundColor: accentColor.withOpacity(0.2),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Chip(
                                      label: Text(
                                        '$unit',
                                        style: TextStyle(
                                          fontSize: fontSizeNormal.clamp(11, 13),
                                        ),
                                      ),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Flexible(
                                      child: Text(
                                        '${item.quantity.toStringAsFixed(3)} $unit',
                                        style: TextStyle(
                                          fontSize: fontSizeNormal.clamp(12, 14),
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.edit_note, size: screenWidth * 0.06),
                      label: Text(
                        'EDIT & ADD TO INVENTORY',
                        style: TextStyle(fontSize: fontSizeNormal.clamp(14, 18)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: _navigateToEditScreen,
                    ),
                  ),
                ],
                
                if (_scannedItems.isEmpty && !_isLoading && _selectedImage == null)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt,
                          size: screenWidth * 0.2,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Start by taking a photo of your receipt',
                          style: TextStyle(
                            fontSize: fontSizeNormal.clamp(14, 18),
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'or choose one from your gallery',
                          style: TextStyle(
                            fontSize: fontSizeNormal.clamp(12, 16),
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required double width,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: screenWidth * 0.05),
        label: Text(
          label,
          style: TextStyle(fontSize: screenWidth * 0.035),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.035,
            horizontal: screenWidth * 0.04,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _scannedItems.clear();
        _totalAmount = 0.0;
        _receiptCurrency = 'PKR';
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _scannedItems.clear();
        _totalAmount = 0.0;
        _receiptCurrency = 'PKR';
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _scannedItems.clear();
      _totalAmount = 0.0;
      _receiptCurrency = 'PKR';
    });
  }

  Future<void> _scanReceipt() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _scannedItems.clear();
      _totalAmount = 0.0;
      _receiptCurrency = 'PKR';
    });
    
    try {
      final items = await _veryfiService.scanReceipt(_selectedImage!);
      
      double total = 0;
      String detectedCurrency = 'PKR';
      
      // Try to detect currency from first item's notes
      if (items.isNotEmpty) {
        for (var item in items) {
          total += item.price;
          
          // Extract currency from notes
          if (item.notes != null && item.notes!.contains('Currency:')) {
            final currencyMatch = RegExp(r'Currency:\s*(\w+)').firstMatch(item.notes!);
            if (currencyMatch != null) {
              detectedCurrency = currencyMatch.group(1)!;
            }
          }
        }
        
        setState(() {
          _scannedItems = items;
          _totalAmount = total;
          _receiptCurrency = detectedCurrency;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No items found on receipt'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error scanning receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReceiptItemsScreen(
          items: _scannedItems,
          receiptCurrency: _receiptCurrency,
          onSave: (editedItems) async {
            await _saveItemsToFirebase(editedItems, _receiptCurrency);
            Navigator.pop(context);
            _clearImage();
          },
        ),
      ),
    );
  }

Future<void> _saveItemsToFirebase(List<ReceiptItem> items, String currency) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to save items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = currentUser.uid;
    final batch = FirebaseFirestore.instance.batch();
    
    // First, get existing inventory items
    final inventorySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    
    final existingItems = inventorySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name']?.toString() ?? '',
        'quantity': double.tryParse(data['quantity']?.toString() ?? '0') ?? 0,
        'unit': data['unit']?.toString() ?? 'units',
        'category': data['category']?.toString() ?? 'Other',
        'notes': data['notes']?.toString() ?? '',
      };
    }).toList();
    
    final Map<String, double> unitConversionFactors = {
      'grams': 1.0, 'g': 1.0, 'gram': 1.0,
      'kgs': 1000.0, 'kg': 1000.0, 'kilogram': 1000.0, 'kilograms': 1000.0,
      'lbs': 453.592, 'lb': 453.592, 'pound': 453.592, 'pounds': 453.592,
      'oz': 28.3495, 'ounce': 28.3495, 'ounces': 28.3495,
      'ml': 1.0, 'milliliter': 1.0, 'milliliters': 1.0,
      'liters': 1000.0, 'liter': 1000.0, 'l': 1000.0,
      'tablespoon': 14.7868, 'tbsp': 14.7868, 'tablespoons': 14.7868,
      'teaspoon': 4.92892, 'tsp': 4.92892, 'teaspoons': 4.92892,
      'cups': 236.588, 'cup': 236.588,
      'fl oz': 29.5735, 'fluid ounce': 29.5735, 'fluid ounces': 29.5735,
      'units': 1.0, 'unit': 1.0, 'items': 1.0, 'item': 1.0,
      'pieces': 1.0, 'piece': 1.0, 'pcs': 1.0, 'pc': 1.0, '': 1.0,
    };

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

    bool _areUnitsCompatible(String unit1, String unit2) {
      final normalized1 = unit1.toLowerCase().trim();
      final normalized2 = unit2.toLowerCase().trim();
      if (normalized1 == normalized2) return true;
      if (normalized1.isEmpty || normalized2.isEmpty) return true;
      return (_isWeightUnit(normalized1) && _isWeightUnit(normalized2)) ||
             (_isVolumeUnit(normalized1) && _isVolumeUnit(normalized2)) ||
             (_isCountUnit(normalized1) && _isCountUnit(normalized2));
    }

    double _convertQuantity(double quantity, String fromUnit, String toUnit) {
      if (fromUnit.toLowerCase().trim() == toUnit.toLowerCase().trim()) {
        return quantity;
      }
      
      final fromFactor = unitConversionFactors[fromUnit.toLowerCase().trim()] ?? 1.0;
      final toFactor = unitConversionFactors[toUnit.toLowerCase().trim()] ?? 1.0;
      
      final baseQuantity = quantity * fromFactor;
      return baseQuantity / toFactor;
    }

    List<Map<String, dynamic>> itemsToAdd = [];
    List<Map<String, dynamic>> itemsToUpdate = [];
    
    for (var newItem in items) {
      final newItemUnit = newItem.unit ?? newItem.detectUnit();
      bool itemMerged = false;
      
      // Try to find existing item to merge with
      for (var existingItem in existingItems) {
        final existingName = existingItem['name'] as String;
        final existingCategory = existingItem['category'] as String;
        final existingUnit = existingItem['unit'] as String;
        final existingNotes = existingItem['notes'] as String;
        
        // Check if same item (by name and category)
        if (newItem.name.toLowerCase() == existingName.toLowerCase() && 
            newItem.category == existingCategory) {
          
          // REMOVED CURRENCY CHECK - Merge regardless of currency
          if (_areUnitsCompatible(newItemUnit, existingUnit)) {
            
            double existingQuantity = existingItem['quantity'] as double;
            String existingId = existingItem['id'] as String;
            
            // Convert new item quantity to existing item's unit
            double convertedNewQuantity;
            if (newItemUnit.toLowerCase() != existingUnit.toLowerCase()) {
              convertedNewQuantity = _convertQuantity(
                newItem.quantity, 
                newItemUnit, 
                existingUnit
              );
            } else {
              convertedNewQuantity = newItem.quantity;
            }
            
            // Calculate total quantity
            double totalQuantity = existingQuantity + convertedNewQuantity;
            
            // Keep existing currency info or add new currency info
            String mergedNotes;
            if (newItem.notes != null && newItem.notes!.contains('Currency:')) {
              // Extract currency from new item
              final currencyMatch = RegExp(r'Currency:\s*(\w+)').firstMatch(newItem.notes!);
              if (currencyMatch != null) {
                String newCurrency = currencyMatch.group(1)!;
                mergedNotes = 'Merged with receipt scan | Currency: $newCurrency';
              } else {
                mergedNotes = 'Merged with receipt scan';
              }
            } else {
              mergedNotes = 'Merged with receipt scan';
            }
            
            itemsToUpdate.add({
              'id': existingId,
              'name': existingName,
              'quantity': totalQuantity,
              'unit': existingUnit,
              'category': existingCategory,
              'notes': mergedNotes,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            itemMerged = true;
            break;
          }
        }
      }
      
      // If no matching item found, add as new
      if (!itemMerged) {
        itemsToAdd.add({
          'name': newItem.name,
          'quantity': newItem.quantity.toString(),
          'unit': newItemUnit,
          'category': newItem.category,
          'purchaseDate': DateTime.now().toIso8601String().split('T')[0],
          'expiryDate': newItem.expiryDate ?? DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0],
          'notes': newItem.notes ?? 'Currency: $currency',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });
      }
    }
    
    // Process updates to existing items
    for (var updateData in itemsToUpdate) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .doc(updateData['id'] as String);
      
      batch.update(docRef, {
        'quantity': updateData['quantity'].toString(),
        'notes': updateData['notes'],
        'updatedAt': updateData['updatedAt'],
      });
    }
    
    // Process new items to add
    for (var addData in itemsToAdd) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .doc();
      
      batch.set(docRef, addData);
    }
    
    await batch.commit();
    
    // Show summary
    final mergedCount = itemsToUpdate.length;
    final addedCount = itemsToAdd.length;
    String message;
    
    if (mergedCount > 0 && addedCount > 0) {
      message = '$mergedCount items merged, $addedCount new items added to inventory';
    } else if (mergedCount > 0) {
      message = '$mergedCount items merged with existing inventory';
    } else {
      message = '$addedCount items added to inventory';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
        duration: Duration(seconds: 3),
      ),
    );
    
  } catch (e) {
    print('Error saving to Firebase: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to save items: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


}

class EditReceiptItemsScreen extends StatefulWidget {
  final List<ReceiptItem> items;
  final String receiptCurrency;
  final Function(List<ReceiptItem>) onSave;
  
  EditReceiptItemsScreen({
    required this.items,
    required this.receiptCurrency,
    required this.onSave,
  });
  
  @override
  _EditReceiptItemsScreenState createState() => _EditReceiptItemsScreenState();
}

class _EditReceiptItemsScreenState extends State<EditReceiptItemsScreen> {
  late List<ReceiptItem> _editableItems;
  final List<String> _categories = [
    'Vegetable',
    'Fruit',
    'Protein',
    'Dairy',
    'Grain',
    'Beverage',
    'Snack',
    'Spices',
    'Other'
  ];

  final List<String> _unitOptions = [
    'units',
    'grams',
    'KGs',
    'liters',
    'lbs',
    'tbsp',
    'tsp',
    'cups',
    'oz',
    'ml'
  ];

  @override
  void initState() {
    super.initState();
    _editableItems = widget.items.map((item) {
      final detectedUnit = item.detectUnit();
      
      return ReceiptItem(
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        category: item.category,
        unit: detectedUnit,
        expiryDate: item.expiryDate,
        notes: item.notes,
      );
    }).toList();
  }

  bool _isDecimalQuantity(double quantity) {
    return quantity % 1 != 0;
  }

  bool _isCountUnit(String unit) {
    const countUnits = {
      '', 'item', 'items', 'piece', 'pieces', 'unit', 'units', 
      'pcs', 'pc'
    };
    return countUnits.contains(unit.toLowerCase().trim());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Items Before Saving'),
        backgroundColor: accentColor,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => widget.onSave(_editableItems),
            tooltip: 'Save All Items',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Text(
                  'Review and edit the scanned items before saving to your inventory',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth * 0.02),
                // Chip(
                //   label: Text(
                //     'Currency: ${widget.receiptCurrency} (${getCurrencySymbol(widget.receiptCurrency)})',
                //     style: TextStyle(
                //       fontSize: screenWidth * 0.035,
                //       color: Colors.white,
                //     ),
                //   ),
                //   backgroundColor: accentColor,
                // ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.02),
              itemCount: _editableItems.length,
              itemBuilder: (context, index) {
                final item = _editableItems[index];
                return _buildEditableItemCard(item, index, screenWidth);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onSave(_editableItems),
        icon: Icon(Icons.save),
        label: Text('Save All Items'),
        backgroundColor: accentColor,
      ),
    );
  }

  Widget _buildEditableItemCard(ReceiptItem item, int index, double screenWidth) {
    final currentUnit = item.unit ?? item.detectUnit();
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.015,
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  tooltip: 'Remove Item',
                ),
              ],
            ),
            
            SizedBox(height: screenWidth * 0.03),
            
            // Quantity Editor
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenWidth * 0.02,
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final parsed = double.tryParse(value) ?? item.quantity;
                      setState(() {
                        _editableItems[index].quantity = parsed;
                      });
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: currentUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenWidth * 0.02,
                          ),
                        ),
                        items: _unitOptions.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _editableItems[index].unit = value;
                          });
                        },
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      if (_isDecimalQuantity(item.quantity) && 
                          _isCountUnit(currentUnit))
                        Text(
                          '⚠️ Decimal quantity with count unit',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenWidth * 0.03),
            
            // Category Editor
            DropdownButtonFormField<String>(
              value: item.category,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.02,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _editableItems[index].category = value!;
                });
              },
            ),
            
            SizedBox(height: screenWidth * 0.03),
            
            // Expiry Date Editor
            GestureDetector(
              onTap: () => _selectExpiryDate(index),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: item.expiryDate ?? 'Select expiry date',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenWidth * 0.02,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: screenWidth * 0.03),
            
            // Notes Editor
            TextFormField(
              initialValue: item.notes ?? '',
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.02,
                ),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _editableItems[index].notes = value;
                });
              },
            ),
            
            SizedBox(height: screenWidth * 0.02),
            
            // Price Display
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  'Price: ${getCurrencySymbol(widget.receiptCurrency)}${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _editableItems[index].expiryDate = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
    
    if (_editableItems.isEmpty) {
      Navigator.pop(context);
    }
  }
}