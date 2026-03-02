import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';


class ProfileEditScreen extends StatefulWidget {
  final String accessToken;

  const ProfileEditScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}


class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedBloodGroup;
  String _profileImagePath = '';
  bool _isLoading = false;
  bool _hasChanges = false;

  // Blood group options
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Add listeners to detect changes
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _emergencyContactController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  // Load user data (mock implementation)
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          "Authorization": "Bearer ${widget.accessToken}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['mobile'] ?? '';
          _emergencyContactController.text =
              data['emergency_contact1'] ?? '';
          String? backendBloodGroup = data['blood_group'];

          if (_bloodGroups.contains(backendBloodGroup)) {
            _selectedBloodGroup = backendBloodGroup;
          } else {
            _selectedBloodGroup = null;
          }
          _profileImagePath = data['profile_image'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar("Failed to load profile");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Error: $e");
    }
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  // Save profile data
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'PUT',
        Uri.parse(ApiConfig.profile),
    );
    request.headers['Authorization'] = "Bearer ${widget.accessToken}";
    request.fields['full_name'] = _nameController.text;
    request.fields['mobile'] = _phoneController.text;
    if (_selectedBloodGroup != null) {
      request.fields['blood_group'] = _selectedBloodGroup!;
    }
    request.fields['emergency_contact1'] =
        _emergencyContactController.text;

    if (_profileImagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          _profileImagePath,
        ),
      );
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      _showSuccessSnackBar("Profile updated successfully!");
    } else {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar("Update failed");
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileForm(),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(),
            const SizedBox(height: 24),

            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 24),

            // Medical Information Section
            _buildSectionHeader('Medical Information'),
            const SizedBox(height: 16),
            _buildBloodGroupField(),
            const SizedBox(height: 24),

            // Emergency Information Section
            _buildSectionHeader('Emergency Information'),
            const SizedBox(height: 16),
            _buildEmergencyContactField(),
            const SizedBox(height: 16),
            _buildLocationField(),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(
                  color: const Color(0xFF2196F3),
                  width: 3,
                ),
              ),
              child: _profileImagePath.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  "${ApiConfig.baseUrl}$_profileImagePath",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultProfileIcon();
                  },
                ),
              )
                  : _buildDefaultProfileIcon(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change photo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDefaultProfileIcon() {
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.grey,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your full name';
        }
        if (value.trim().length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email address',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your phone number';
        }
        if (!RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(value.replaceAll(' ', ''))) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildBloodGroupField() {
    return DropdownButtonFormField<String>(
      value: _bloodGroups.contains(_selectedBloodGroup)
          ? _selectedBloodGroup
          : null,
      decoration: InputDecoration(
        labelText: 'Blood Group',
        prefixIcon: const Icon(Icons.opacity),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _bloodGroups.map((bloodGroup) {
        return DropdownMenuItem(
          value: bloodGroup,
          child: Text(bloodGroup),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBloodGroup = value;
          _hasChanges = true;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your blood group';
        }
        return null;
      },
    );
  }

  Widget _buildEmergencyContactField() {
    return TextFormField(
      controller: _emergencyContactController,
      decoration: InputDecoration(
        labelText: 'Emergency Contact',
        hintText: 'Enter emergency contact number',
        prefixIcon: const Icon(Icons.contact_phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter emergency contact number';
        }
        if (!RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(value.replaceAll(' ', ''))) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location',
        hintText: 'Enter your location',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: _getCurrentLocation,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your location';
        }
        return null;
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    // In a real app, this would use geolocator to get current location
    setState(() {
      _locationController.text = 'Current Location (GPS)';
      _hasChanges = true;
    });
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfile();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
