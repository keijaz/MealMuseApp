import 'package:flutter/material.dart';
import 'users.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isSmallScreen ? 8.0 : 12.0,
        left: isSmallScreen ? 8.0 : 0,
        right: isSmallScreen ? 8.0 : 0,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        elevation: isSmallScreen ? 2 : 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Container(
            constraints: BoxConstraints(
              minHeight: isSmallScreen ? 60 : 70,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
            child: Row(
              children: [
                // Responsive avatar
                Container(
                  width: isSmallScreen ? 40 : (isLargeScreen ? 56 : 50),
                  height: isSmallScreen ? 40 : (isLargeScreen ? 56 : 50),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8181).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : (isLargeScreen ? 18 : 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5B8181),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                // Flexible content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary info - always visible
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : (isLargeScreen ? 20 : 18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Secondary info - adaptive
                      if (!isSmallScreen) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: isLargeScreen ? 16 : 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Essential contact info
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : (isLargeScreen ? 15 : 14),
                          color: Colors.grey,
                        ),
                        maxLines: isSmallScreen ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Responsive actions
                _buildAdaptiveActions(isSmallScreen, isLargeScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveActions(bool isSmallScreen, bool isLargeScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conditional delete button on small screens
        if (!isSmallScreen) ...[
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.red,
              size: isLargeScreen ? 28 : 24,
            ),
            onPressed: onDelete,
            padding: const EdgeInsets.all(4.0),
            tooltip: 'Delete User',
          ),
          SizedBox(width: isLargeScreen ? 12 : 8),
        ],
        
        // Chevron icon
        Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: isLargeScreen ? 28 : 24,
        ),
        
        // Delete button for small screens (simplified)
        if (isSmallScreen) ...[
          SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }
}