import 'package:flutter/material.dart';
import 'weather_safety_screen.dart';
import 'profile_edit_screen.dart';
import 'tourmate_dashboard.dart';
import 'login_screen.dart';

class MoreOptionsScreen extends StatefulWidget {
  final String accessToken;
  final String userName;

  const MoreOptionsScreen({
    super.key,
    required this.accessToken,
    required this.userName,
  });

  @override
  State<MoreOptionsScreen> createState() => _MoreOptionsScreenState();
}
class _MoreOptionsScreenState extends State<MoreOptionsScreen> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More Options',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TourMateDashboard(
                locationPermissionGranted: true,
                userName: widget.userName,
                accessToken: widget.accessToken,
              ),
            ),
            (route) => false,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'Profile',
            subtitle: 'Edit your personal information',
            icon: Icons.person,
            color: Colors.blue,
            onTap: () => _navigateToProfile(context),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Safety & Travel'),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'Weather & Safety',
            subtitle: 'Check weather conditions and travel safety',
            icon: Icons.cloud,
            color: Colors.orange,
            onTap: () => _navigateToWeatherSafety(context),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Support'),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'About',
            subtitle: 'About TourMate app',
            icon: Icons.info,
            color: Colors.purple,
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Legal'),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            icon: Icons.privacy_tip,
            color: Colors.indigo,
            onTap: () => _showComingSoon(context, 'Privacy Policy'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            context,
            title: 'Terms of Service',
            subtitle: 'View our terms of service',
            icon: Icons.description,
            color: Colors.teal,
            onTap: () => _showComingSoon(context, 'Terms of Service'),
          ),
          const SizedBox(height: 32),
          
          _buildLogoutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen(accessToken: widget.accessToken)),
    );
  }

  void _navigateToWeatherSafety(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherSafetyScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TourMate'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TourMate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your trusted travel companion for safe and enjoyable journeys. TourMate helps tourists navigate unfamiliar places with ease, providing essential services and safety features.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text('• Location-based nearby places'),
            Text('• Weather and safety information'),
            Text('• Emergency SOS functionality'),
            Text('• Photo diary for travel memories'),
            Text('• Translation services'),
            SizedBox(height: 16),
            Text(
              '© 2024 TourMate. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate back to login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
