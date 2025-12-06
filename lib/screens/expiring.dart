import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

// --- Data Model for a single expiring item ---
class ExpiringItem {
  final String id;
  final String name;
  final double count;
  final String unit;
  final String expiry;
  final IconData icon;
  final DateTime expiryDate;

  const ExpiringItem({
    required this.id,
    required this.name,
    required this.count,
    required this.unit,
    required this.expiry,
    required this.icon,
    required this.expiryDate,
  });
}

class ExpiringItemsScreen extends StatefulWidget {
  const ExpiringItemsScreen({super.key});

  @override
  State<ExpiringItemsScreen> createState() => _ExpiringItemsScreenState();
}

class _ExpiringItemsScreenState extends State<ExpiringItemsScreen> {
  // --- Color Palette ---
  static const Color _primaryRed = Color(0xFFBC0805);
  static const Color _primaryWhite = Colors.white;
  static const Color _primaryBlack = Colors.black;

  List<ExpiringItem> _expiringItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpiringItems();
  }

  DateTime? _parseDate(String dateStr) {
  // Clean the input
  String cleaned = dateStr.trim();
  
  // Remove any time portion if present
  if (cleaned.contains(' ')) {
    cleaned = cleaned.split(' ')[0];
  }
  
  // Replace common separators with dashes
  cleaned = cleaned.replaceAll('/', '-').replaceAll('.', '-');
  
  try {
    // Try direct parsing first
    return DateTime.parse(cleaned);
  } catch (e) {
    // Try manual parsing for common formats
    final parts = cleaned.split('-');
    
    if (parts.length == 3) {
      try {
        int? year, month, day;
        
        // Analyze the parts to determine format
        for (int i = 0; i < parts.length; i++) {
          final part = parts[i];
          final num = int.tryParse(part);
          
          if (num == null) continue;
          
          if (part.length == 4) {
            // This is likely the year
            year = num;
          } else if (num > 31) {
            // Number > 31 is likely the year (for 2-digit years > 31)
            year = num > 1000 ? num : 2000 + num;
          } else if (month == null && num <= 12) {
            // First number <= 12 is likely month
            month = num;
          } else {
            // Remaining number is day
            day = num;
          }
        }
        
        // If we couldn't determine, try common formats
        if (year == null || month == null || day == null) {
          // Try DD-MM-YYYY
          if (parts[0].length <= 2 && parts[1].length <= 2 && parts[2].length == 4) {
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
            year = int.parse(parts[2]);
          }
          // Try MM-DD-YYYY  
          else if (parts[0].length <= 2 && parts[1].length <= 2 && parts[2].length == 4) {
            month = int.parse(parts[0]);
            day = int.parse(parts[1]);
            year = int.parse(parts[2]);
          }
          // Try YYYY-MM-DD
          else if (parts[0].length == 4 && parts[1].length <= 2 && parts[2].length <= 2) {
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          }
        }
        
        if (year != null && month != null && day != null) {
          // Basic validation
          if (year >= 2000 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        return null;
      }
    }
  }
  
  return null;
}

  // Method to load expiring items from Firebase
 Future<void> _loadExpiringItems() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = TranslationHelper.t('User not logged in', 'صارف لاگ ان نہیں ہے');
        _isLoading = false;
      });
      return;
    }

    final inventorySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .get();

    final List<ExpiringItem> items = [];
    int totalItems = 0;
    int itemsWithExpiry = 0;
    int itemsProcessed = 0;
    int itemsSkipped = 0;

    for (final doc in inventorySnapshot.docs) {
      totalItems++;
      final data = doc.data();
      final expiryDateStr = data['expiryDate']?.toString(); // Use toString() to handle any type

      // Skip items without expiry date
      if (expiryDateStr == null || expiryDateStr.isEmpty || expiryDateStr == 'null') {
        continue;
      }
      itemsWithExpiry++;

      print('🔍 Processing: ${data['name']} - Expiry: "$expiryDateStr"');

      try {
        // Use the robust date parser
        final expiryDate = _parseDate(expiryDateStr);
        
        if (expiryDate == null) {
          print('❌ Could not parse date: $expiryDateStr');
          itemsSkipped++;
          continue;
        }

        final now = DateTime.now();
        final difference = expiryDate.difference(now);

        // Calculate days until expiry
        final daysUntilExpiry = difference.inDays;
        String expiryText;

        if (daysUntilExpiry < 0) {
          expiryText = TranslationHelper.t('Expired', 'ختم شدہ');
        } else if (daysUntilExpiry == 0) {
          expiryText = TranslationHelper.t('Today', 'آج');
        } else if (daysUntilExpiry == 1) {
          expiryText = TranslationHelper.t('1 Day', '1 دن');
        } else if (daysUntilExpiry < 7) {
          expiryText = '$daysUntilExpiry ${TranslationHelper.t('Days', 'دن')}';
        } else if (daysUntilExpiry < 30) {
          final weeks = (daysUntilExpiry / 7).ceil();
          expiryText = weeks == 1 ? TranslationHelper.t('1 Week', '1 ہفتہ') : '$weeks ${TranslationHelper.t('Weeks', 'ہفتے')}';
        } else {
          final months = (daysUntilExpiry / 30).ceil();
          expiryText = months == 1 ? TranslationHelper.t('1 Month', '1 ماہ') : '$months ${TranslationHelper.t('Months', 'مہینے')}';
        }

        // Get appropriate icon based on category
        final category = data['category'] as String? ?? 'Other';
        final icon = _getIconForCategory(category);

        // Handle both string and numeric quantity
        double quantity;
        final quantityData = data['quantity'];
        if (quantityData is String) {
          quantity = double.tryParse(quantityData) ?? 0.0;
        } else if (quantityData is int) {
          quantity = quantityData.toDouble();
        } else if (quantityData is double) {
          quantity = quantityData;
        } else {
          quantity = 0.0;
        }

        final unit = data['unit'] as String? ?? TranslationHelper.t('pcs', 'عدد');

        items.add(ExpiringItem(
          id: doc.id,
          name: data['name'] as String? ?? TranslationHelper.t('Unknown Item', 'نامعلوم آئٹم'),
          count: quantity,
          unit: unit,
          expiry: expiryText,
          icon: icon,
          expiryDate: expiryDate,
        ));
        
        itemsProcessed++;
        print('✅ Successfully added: ${data['name']} - Expires: $expiryText');

      } catch (e) {
        itemsSkipped++;
        print('❌ Error processing ${data['name']}: $e');
        continue;
      }
    }

    // Sort items by expiry date (earliest first)
    items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    // Debug summary
    print('📊 Summary:');
    print('   Total items: $totalItems');
    print('   Items with expiry: $itemsWithExpiry');
    print('   Successfully processed: $itemsProcessed');
    print('   Skipped: $itemsSkipped');
    print('   Final list: ${items.length} items');

    setState(() {
      _expiringItems = items;
      _isLoading = false;
    });
  } catch (e) {
    print('🔥 Fatal error in _loadExpiringItems: $e');
    setState(() {
      _errorMessage = "${TranslationHelper.t('Error loading expiring items', 'ختم ہونے والی اشیاء لوڈ کرنے میں خرابی')}: $e";
      _isLoading = false;
    });
  }
}

  // Helper method to get icon based on category
  // Delete item function
  Future<void> _deleteItem(ExpiringItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(item.id)
          .delete();
      
      // Remove from local list
      setState(() {
        _expiringItems.removeWhere((i) => i.id == item.id);
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} ${TranslationHelper.t('deleted successfully', 'کامیابی سے حذف ہو گیا')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.t('Error deleting', 'حذف کرتے وقت خرابی')} ${item.name}: $e'),
            backgroundColor: _primaryRed,
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(ExpiringItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final secondaryTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black87;
    final cancelButtonBg = isDarkMode ? const Color(0xFF404040) : Colors.grey[200];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            TranslationHelper.t('Delete Item', 'آئٹم حذف کریں'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            TranslationHelper.t('Are you sure you want to delete ${item.name}?', 'کیا آپ یقینی ہیں کہ آپ ${item.name} کو حذف کرنا چاہتے ہیں؟'),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: cancelButtonBg,
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        TranslationHelper.t('Cancel', 'منسوخ'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteItem(item);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        TranslationHelper.t('Delete', 'حذف'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Icons.local_florist_outlined;
      case 'vegetable':
        return Icons.spa_outlined;
      case 'dairy':
        return Icons.local_cafe_outlined;
      case 'meat':
        return Icons.fastfood_outlined;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grain':
        return Icons.grass_outlined;
      case 'beverage':
        return Icons.local_drink_outlined;
      default:
        return Icons.shopping_basket_outlined;
    }
  }

  // Reusable widget for the item card in the list - SIMPLIFIED VERSION
  // Reusable widget for the item card in the list - SIMPLIFIED VERSION
Widget _buildItemCard(ExpiringItem item) {
  final themeProvider = ThemeProvider();
  final isDarkMode = themeProvider.darkModeEnabled;
  final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : _primaryWhite;
  final textColor = isDarkMode ? const Color(0xFFE1E1E1) : _primaryBlack;
  final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
  
  // Calculate if item is expiring in 3 weeks or less (including expired items)
  final now = DateTime.now();
  final daysUntilExpiry = item.expiryDate.difference(now).inDays;
  final showWarning = daysUntilExpiry <= 14; // 2 weeks
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Reduced horizontal padding
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: _primaryBlack.withOpacity(isDarkMode ? 0.1 : 0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item details - takes most of the space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2, // Allow wrapping to 2 lines
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Quantity and expiry - now in separate rows for better wrapping
                Text(
                  '${item.count == item.count.toInt() ? item.count.toInt() : item.count.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Expiry information
                Text(
                  '${TranslationHelper.t('Expires In', 'میعاد باقی')}: ${item.expiry}',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Warning icon and menu button
          Column(
            children: [
              if (showWarning)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: _primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (showWarning) const SizedBox(height: 4),
              // Three-dot menu button
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey, size: 20),
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(item);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Color.fromARGB(255, 144, 11, 9)),
                        const SizedBox(width: 8),
                        Text(
                          TranslationHelper.t('Delete', 'حذف'),
                          style: TextStyle(color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _handleNavToMainShell(BuildContext context, int index) {
    if (index != 3) {
      Navigator.pop(context);
    }
  }

  Widget _buildContent() {
    final themeProvider = ThemeProvider();
    final isDarkMode = themeProvider.darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : _primaryBlack;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: _primaryRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: subtitleColor),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExpiringItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: _primaryWhite,
              ),
              child: Text(TranslationHelper.t('Retry', 'دوبارہ کوشش کریں')),
            ),
          ],
        ),
      );
    }

    if (_expiringItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: _primaryRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                TranslationHelper.t('No expiring items found', 'کوئی ختم ہونے والی اشیاء نہیں ملیں'),
                style: TextStyle(fontSize: 18, color: textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                TranslationHelper.t('Add expiry dates to your inventory items to see them here', 'اپنی انوینٹری آئٹمز میں میعاد ختم ہونے کی تاریخیں شامل کریں تاکہ یہاں دکھائی دیں'),
                style: TextStyle(fontSize: 14, color: subtitleColor),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildItemCard(_expiringItems[index]);
        },
        childCount: _expiringItems.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void onTabTappedCallback(int index) {
      _handleNavToMainShell(context, index);
    }

    final themeProvider = ThemeProvider();
    final isDarkMode = themeProvider.darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Fixed AppBar Section - Removed overflow ---
          SliverAppBar(
            expandedHeight: 100.0, // Reduced height to prevent overflow
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
              ),
              child: ValueListenableBuilder<Locale?>(
                valueListenable: LocaleProvider().localeNotifier,
                builder: (context, locale, _) {
                  return FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(bottom: 16.0), // Adjusted padding
                    centerTitle: true,
                    title: Container(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        TranslationHelper.t('Expiring Soon', 'جلد ختم ہونے والی اشیاء'),
                        style: const TextStyle(
                          color: _primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Add some top padding to the list
          const SliverToBoxAdapter(
            child: SizedBox(height: 16.0),
          ),

          // --- Dynamic Content ---
          _isLoading || _errorMessage != null || _expiringItems.isEmpty
              ? SliverFillRemaining(
                  child: _buildContent(),
                )
              : _buildContent(),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: onTabTappedCallback,
        currentIndex: 3,
        navContext: context,
      ),
    );
  }
}