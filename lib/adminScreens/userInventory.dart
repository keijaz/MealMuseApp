import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users.dart';
import '../providers/theme_provider.dart';

class UserInventory extends StatefulWidget {
  final User user;

  const UserInventory({super.key, required this.user});

  @override
  State<UserInventory> createState() => _UserInventoryState();
}

class _UserInventoryState extends State<UserInventory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Force light mode for admin screens
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // User info card
          _buildUserInfoCard(),
          const SizedBox(height: 16),
          // Tab indicator
          _buildTabIndicator(),
          const SizedBox(height: 16),
          // Content based on selected tab
          Expanded(
            child: _getCurrentTabContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5C8A94),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Grocery',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return '${widget.user.username}\'s Inventory';
      case 1:
        return '${widget.user.username}\'s Saved';
      case 2:
        return '${widget.user.username}\'s Grocery';
      default:
        return '${widget.user.username}\'s Inventory';
    }
  }

  Widget _getCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildInventoryList();
      case 1:
        return _buildSavedRecipesList();
      case 2:
        return _buildGroceryList();
      default:
        return _buildInventoryList();
    }
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C8A94).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.user.initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C8A94),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined: ${widget.user.formattedCreatedAt}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildTabIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _currentIndex == 0 
                      ? const Color(0xFF5C8A94) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentIndex == 0 ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _currentIndex == 1 
                      ? const Color(0xFF5C8A94) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentIndex == 1 ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _currentIndex == 2 
                      ? const Color(0xFF5C8A94) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Grocery',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentIndex == 2 ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroceryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('grocery_list')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading grocery list: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C8A94)),
            ),
          );
        }

        final groceryItems = snapshot.data?.docs ?? [];

        if (groceryItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No grocery items found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User hasn\'t added any items to their grocery list',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: groceryItems.length,
          itemBuilder: (context, index) {
            final item = groceryItems[index];
            final data = item.data() as Map<String, dynamic>;
            
            return _buildGroceryItemCard(item.id, data);
          },
        );
      },
    );
  }

  Widget _buildGroceryItemCard(String itemId, Map<String, dynamic> data) {
    final isChecked = data['isChecked'] ?? false;
    
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Checkbox for item completion
            // Container(
            //   width: 40,
            //   height: 40,
            //   decoration: BoxDecoration(
            //     color: isChecked ? Colors.green.shade100 : Colors.grey.shade100,
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   child: Center(
            //     child: Icon(
            //       isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            //       color: isChecked ? Colors.green : Colors.grey,
            //       size: 24,
            //     ),
            //   ),
            // ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? data['originalName'] ?? 'Unnamed Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (data['amount'] != null && data['unit'] != null)
                    Text(
                      '${data['amount']} ${data['unit']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (data['category'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (data['recipeSource'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'From: ${data['recipeSource']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (data['createdAt'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Added: ${_formatDate(data['createdAt'])}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Delete button for grocery item
            IconButton(
              onPressed: () => _showDeleteGroceryItemDialog(itemId, data['name'] ?? data['originalName'] ?? 'this item'),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              tooltip: 'Delete item',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

void _showDeleteGroceryItemDialog(String itemId, String itemName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: const Text(
        'Delete Grocery Item',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Text(
          'Are you sure you want to delete "$itemName" from ${widget.user.username}\'s grocery list?',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
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
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _deleteGroceryItem(itemId, itemName);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C8A94),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
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
    ),
  );
}

  Future<void> _deleteGroceryItem(String itemId, String itemName) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Deleting "$itemName"...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('grocery_list')
          .doc(itemId)
          .delete();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted "$itemName"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting item: ${e.toString()}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (date is String) {
      return date;
    }
    return 'Unknown date';
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading inventory: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C8A94)),
            ),
          );
        }

        final inventoryItems = snapshot.data?.docs ?? [];

        if (inventoryItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No inventory items found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User hasn\'t added any items to their inventory',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: inventoryItems.length,
          itemBuilder: (context, index) {
            final item = inventoryItems[index];
            final data = item.data() as Map<String, dynamic>;
            
            return _buildInventoryItemCard(item.id, data);
          },
        );
      },
    );
  }

  Widget _buildInventoryItemCard(String itemId, Map<String, dynamic> data) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Item icon based on category
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(data['category'] ?? 'Other'),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getCategoryIcon(data['category'] ?? 'Other'),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unnamed Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['quantity'] ?? '0'} ${data['unit'] ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data['category'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (data['expiryDate'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Expires: ${data['expiryDate']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Delete button for inventory item
            IconButton(
              onPressed: () => _showDeleteInventoryItemDialog(itemId, data['name'] ?? 'this item'),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              tooltip: 'Delete item',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRecipesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('saved_recipes')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading saved recipes: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C8A94)),
            ),
          );
        }

        final savedRecipes = snapshot.data?.docs ?? [];

        if (savedRecipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved recipes found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User hasn\'t saved any recipes yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: savedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = savedRecipes[index];
            final data = recipe.data() as Map<String, dynamic>;
            
            return _buildRecipeCard(recipe.id, data);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(String recipeId, Map<String, dynamic> data) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image - smaller on mobile
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: data['image'] != null && data['image'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(data['image'] ?? ''),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: data['image'] == null ? Colors.grey[200] : null,
              ),
              child: data['image'] == null
                  ? const Icon(Icons.fastfood, color: Colors.grey, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Untitled Recipe',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Recipe info in a more compact layout
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildRecipeInfo(
                        Icons.favorite,
                        '${data['likes'] ?? 0}',
                      ),
                      _buildRecipeInfo(
                        Icons.check_circle,
                        '${data['usedIngredientCount'] ?? 0} used',
                      ),
                      _buildRecipeInfo(
                        Icons.cancel,
                        '${data['missedIngredientCount'] ?? 0} missing',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (data['savedAt'] != null) 
                    Text(
                      'Saved: ${_formatSavedDate(data['savedAt'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Delete button for saved recipe
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton(
                onPressed: () => _showDeleteSavedRecipeDialog(recipeId, data['title'] ?? 'this recipe'),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                tooltip: 'Delete saved recipe',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteInventoryItemDialog(String itemId, String itemName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: const Text(
        'Delete Inventory Item',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Text(
          'Are you sure you want to delete "$itemName" from ${widget.user.username}\'s inventory?',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
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
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _deleteInventoryItem(itemId, itemName);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C8A94),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
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
    ),
  );
}

  void _showDeleteSavedRecipeDialog(String recipeId, String recipeTitle) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: const Text(
        'Delete Saved Recipe',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Text(
          'Are you sure you want to remove "$recipeTitle" from ${widget.user.username}\'s saved recipes?',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
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
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _deleteSavedRecipe(recipeId, recipeTitle);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C8A94),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
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
    ),
  );
}

  Future<void> _deleteInventoryItem(String itemId, String itemName) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Deleting "$itemName"...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('inventory')
          .doc(itemId)
          .delete();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted "$itemName"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting item: ${e.toString()}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSavedRecipe(String recipeId, String recipeTitle) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Removing "$recipeTitle"...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('saved_recipes')
          .doc(recipeId)
          .delete();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully removed "$recipeTitle"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error removing recipe: ${e.toString()}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Colors.red.shade400;
      case 'vegetable':
        return Colors.green.shade400;
      case 'meat':
        return Colors.orange.shade400;
      case 'dairy':
        return Colors.yellow.shade700;
      case 'grain':
        return Colors.brown.shade400;
      case 'beverage':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Icons.apple;
      case 'vegetable':
        return Icons.eco;
      case 'meat':
        return Icons.set_meal;
      case 'dairy':
        return Icons.local_drink;
      case 'grain':
        return Icons.grain;
      case 'beverage':
        return Icons.local_cafe;
      default:
        return Icons.inventory_2;
    }
  }

  String _formatSavedDate(dynamic savedAt) {
    if (savedAt is Timestamp) {
      final date = savedAt.toDate();
      return '${date.month}/${date.day}/${date.year}';
    } else if (savedAt is String) {
      return savedAt;
    }
    return 'Unknown date';
  }
}