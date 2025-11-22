import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_buttons.dart';

class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  
  File? _profileImage;
  String? _selectedUserType;
  bool _isSaving = false;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final PermissionService _permissionService = PermissionService();

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      bool hasPermission = false;
      
      if (source == ImageSource.camera) {
        hasPermission = await _permissionService.requestCameraPermission();
      } else {
        hasPermission = await _permissionService.requestStoragePermission();
      }
      
      if (!hasPermission) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check username uniqueness
      final isUsernameAvailable = await _firestoreService.isUsernameAvailable(
        _usernameController.text.trim(),
      );
      
      if (!isUsernameAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken')),
        );
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Create user model per PRD
      final userModel = UserModel(
        userId: user.uid,
        email: user.email ?? '',
        username: _usernameController.text.trim(),
        profilePictureUrl: '',
        contactInfo: ContactInfo(
          phone: _phoneController.text.trim(),
          email: user.email ?? '',
        ),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        userType: _selectedUserType ?? 'Citizen',
        postIds: [],
        dogIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.createUserProfile(userModel);

      // Upload profile picture bytes after document creation and update URL
      if (_profileImage != null) {
        try {
          final bytes = await _profileImage!.readAsBytes();
          final imageUrl = await _storageService.uploadProfilePictureBytes(bytes, user.uid);
          await _firestoreService.updateUserProfile(user.uid, {
            'profilePictureUrl': imageUrl,
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile picture upload failed: $e. You can add it later.')),
            );
          }
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Guardian Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "This is how you'll be known in the Mitran community. Your contact info will only be shared when you list a dog for adoption.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: _profileImage != null 
                          ? FileImage(_profileImage!)
                          : null,
                        child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _showImagePickerOptions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Information Form
                CustomTextField(
                  label: 'Public Username *',
                  hint: 'Choose a unique username',
                  controller: _usernameController,
                  validator: Validators.validateUsername,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Phone Number *',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final requiredErr = Validators.validateRequired(value, 'Phone Number');
                    if (requiredErr != null) return requiredErr;
                    return Validators.validatePhone(value);
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'City *',
                  hint: 'Enter your city',
                  controller: _cityController,
                  validator: (value) => Validators.validateRequired(value, 'City'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Area *',
                  hint: 'Enter your area/locality',
                  controller: _areaController,
                  validator: (value) => Validators.validateRequired(value, 'Area'),
                ),
                const SizedBox(height: 16),

                CustomDropdown<String>(
                  label: 'User Type *',
                  hint: 'Select user type',
                  value: _selectedUserType,
                  items: const ['Volunteer', 'Feeder', 'NGO Member', 'Citizen', 'Other'],
                  itemLabel: (s) => s,
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a user type';
                    }
                    return null;
                  },
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 32),

                // Form Actions
                PrimaryButton(
                  text: 'Become a Guardian',
                  onPressed: _isSaving ? null : _saveProfile,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}