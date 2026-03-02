import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tourmate_dashboard.dart';
import '../config/api_config.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _medicalConditionController = TextEditingController();
  final _emergencyContact1Controller = TextEditingController();
  final _emergencyContact2Controller = TextEditingController();

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bloodGroupController.dispose();
    _medicalConditionController.dispose();
    _emergencyContact1Controller.dispose();
    _emergencyContact2Controller.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {

      final response = await http.post(
        Uri.parse(ApiConfig.signup),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": _fullNameController.text.trim(),
          "email": _emailController.text.trim(),
          "mobile": _mobileController.text.trim(),
          "password": _passwordController.text.trim(),
          "confirm_password": _confirmPasswordController.text.trim(),
          "blood_group": _bloodGroupController.text.trim(),
          "medical_condition": _medicalConditionController.text.trim(),
          "emergency_contact1": _emergencyContact1Controller.text.trim(),
          "emergency_contact2": _emergencyContact2Controller.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Successful")),
        );

        // Extract the access token and navigate to the dashboard
        String? accessToken = data['access'];
        if (accessToken != null) {
          _navigateToDashboard(true, accessToken);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup Failed: Access token is null")),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data.toString())),
        );
      }
    }
  }


  // Show location permission dialog
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Block background interaction
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Location Access Required',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'TourMate needs access to your location to show nearby tourist spots, hospitals, police stations, and to provide emergency assistance during SOS situations.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            // Deny button (Secondary)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _navigateToDashboard(false, ""); // Navigate with denied permission
              },
              child: const Text(
                'Deny',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Allow Location button (Primary)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _requestLocationPermission(); // Request permission
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              child: const Text(
                'Allow Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Request location permission from system
  Future<void> _requestLocationPermission() async {
    try {
      // Request location permission
      PermissionStatus status = await Permission.location.request();
      
      if (status.isGranted) {
        // Permission granted - store status and navigate
        await _storePermissionStatus(true);
        _navigateToDashboard(true, "");
      } else if (status.isDenied) {
        // Permission denied - show warning and navigate with limited features
        _showPermissionDeniedWarning();
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied - show settings dialog
        _showOpenSettingsDialog();
      } else {
        // Other cases - navigate with limited features
        await _storePermissionStatus(false);
        _navigateToDashboard(false, "");
      }
    } catch (e) {
      // Handle error - navigate with limited features
      await _storePermissionStatus(false);
      _navigateToDashboard(false, "");
    }
  }

  // Store permission status locally (using SharedPreferences would be ideal, but for now using a simple flag)
  Future<void> _storePermissionStatus(bool granted) async {
    // In a real app, you would use SharedPreferences or another storage method
    // For now, we'll just proceed with the navigation
    // You can implement local storage like this:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('location_permission', granted);
  }

  // Navigate to dashboard with permission status
  void _navigateToDashboard(bool locationGranted, String accessToken) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TourMateDashboard(
          locationPermissionGranted: locationGranted,
          userName: _fullNameController.text,
          accessToken: accessToken,
        ),
      ),
    );
  }

  // Show warning when permission is denied
  void _showPermissionDeniedWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Denied'),
        content: const Text(
          'Some features like finding nearby places and emergency assistance may not work properly without location access. You can enable it later in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToDashboard(false, ""); // Navigate with limited features
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Show dialog to open app settings when permission is permanently denied
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission was permanently denied. Please enable it in your device settings to use all features.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToDashboard(false, ""); // Navigate with limited features
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Open app settings
              // Navigate after settings (user might come back)
              Future.delayed(const Duration(seconds: 1), () {
                _navigateToDashboard(false, "");
              });
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'images/download.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bloodtype),
                      ),
                      value: _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
                      items: _bloodGroups.map((String bloodGroup) {
                        return DropdownMenuItem<String>(
                          value: bloodGroup,
                          child: Text(bloodGroup),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _bloodGroupController.text = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your blood group';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medicalConditionController,
                      decoration: const InputDecoration(
                        labelText: 'Existing Medical Condition (Optional)',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContact1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact 1',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.contact_phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter emergency contact 1';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContact2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact 2',
                        filled: true,
                        fillColor: Colors.white70,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.contact_phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
