import 'package:flutter/material.dart';
import 'users.dart'; 
import 'userInventory.dart';
import 'userCard.dart';
import '../providers/theme_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService(); // Use UserService instead of FirestoreService
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryContentColor = Color(0xFF5C8A94);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Users',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 16.0),
          Expanded( // Use Expanded instead of fixed height
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryContentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildUserList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by username',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
        style: const TextStyle(color: Colors.black),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<User>>(
      stream: _userService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Error loading users: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        final users = snapshot.data ?? [];
        
        // Filter out admin@mealmuse.com
        final filteredUsers = users.where((user) => 
          user.email.toLowerCase().trim() != 'admin@mealmuse.com'
        ).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty 
                        ? 'No regular users found' 
                        : 'No users match "$_searchQuery"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
          padding: const EdgeInsets.only(bottom: 16.0), // Reduced bottom padding
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0), // Add spacing between cards
              child: UserCard(
                user: user,
                onTap: () {
                  _navigateToUserInventory(context, user);
                },
                onDelete: () {
                  _showDeleteConfirmationDialog(context, user);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToUserInventory(BuildContext context, User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInventory(user: user),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, User user) {
  final isDarkMode = ThemeProvider().darkModeEnabled;
  final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
  final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
  final secondaryTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black87;
  final cancelButtonBg = isDarkMode ? const Color(0xFF404040) : Colors.grey[200];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Text(
        'Delete User',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Text(
          'Are you sure you want to delete ${user.username}? '
          'This will also delete all their inventory and saved recipes. '
          'This action cannot be undone.',
          style: TextStyle(
            color: secondaryTextColor,
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
                    backgroundColor: cancelButtonBg,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
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
                    await _deleteUser(context, user);
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

  Future<void> _deleteUser(BuildContext context, User user) async {
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
              Expanded( // Make snackbar text wrap properly
                child: Text(
                  'Deleting ${user.username}...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      await _userService.deleteUser(user.uid);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted ${user.username}'),
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
              'Error deleting user: ${e.toString()}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}