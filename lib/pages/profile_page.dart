import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/service_providers.dart';
import '../utils/validators.dart';
import '../providers/posts_provider.dart';
import '../providers/dogs_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_buttons.dart';
import '../models/user_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  String? _userType;

  bool _isEditing = false;
  bool _isLoading = false;
  XFile? _selectedImage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermission = await permissionService.requestStoragePermission();
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied')),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _takePhoto() async {
    final permissionService = ref.read(permissionServiceProvider);
    final hasCameraPermission = await permissionService.requestCameraPermission();
    final hasGalleryPermission = await permissionService.requestStoragePermission();
    
    if (!hasCameraPermission || !hasGalleryPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera or gallery permission denied')),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (photo != null && mounted) {
      setState(() {
        _selectedImage = photo;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current user profile
      final currentProfile = await ref.read(userProfileProvider(user.uid).future);

      String? newProfilePictureUrl;

      // Upload new profile picture if selected
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        newProfilePictureUrl = await storageService.uploadProfilePicture(
          File(_selectedImage!.path),
          user.uid,
        );
      }

      // Create updated user profile
      final updatedProfile = currentProfile.copyWith(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        profilePictureUrl: newProfilePictureUrl ?? currentProfile.profilePictureUrl,
        contactInfo: ContactInfo(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        ),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        userType: _userType ?? currentProfile.userType,
      );

      // Update user profile
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.updateUserProfile(user.uid, updatedProfile.toMap());

      if (mounted) {
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
    });
    
    // Reset form fields to current values
    final user = ref.read(authProvider).value;
    if (user != null) {
      ref.read(userProfileProvider(user.uid)).whenData((profile) {
        if (mounted) {
          _usernameController.text = profile.username;
          _emailController.text = profile.email;
          _phoneController.text = profile.contactInfo.phone;
          _cityController.text = profile.city;
          _areaController.text = profile.area;
          _userType = profile.userType.isNotEmpty ? profile.userType : null;
        }
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear all local app data (sessions, onboarding flags, etc.)
        await ref.read(sessionManagerProvider).clearAll();

        // Sign out
        final authService = ref.read(authServiceProvider);
        await authService.signOut();

        // Invalidate streams and cached providers
        ref.invalidate(postsProvider);
        ref.invalidate(dogsProvider);
        final current = ref.read(authProvider).value;
        if (current != null) {
          ref.invalidate(userProfileProvider(current.uid));
        }

        // Navigate to onboarding
        if (mounted) {
          context.go('/onboarding');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/onboarding');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userProfileAsync = ref.watch(userProfileProvider(user.uid));

    return userProfileAsync.when(
      data: (userProfile) {

        // Initialize form controllers with current values
    if (!_isEditing) {
      _usernameController.text = userProfile.username;
      _emailController.text = userProfile.email;
      _phoneController.text = userProfile.contactInfo.phone;
      _cityController.text = userProfile.city;
      _areaController.text = userProfile.area;
      _userType = userProfile.userType.isNotEmpty ? userProfile.userType : null;
    }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Guardian Profile'),
            centerTitle: true,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEdit,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path))
                            : (userProfile.profilePictureUrl.isNotEmpty
                                ? NetworkImage(userProfile.profilePictureUrl)
                                : null),
                        child: _selectedImage == null && userProfile.profilePictureUrl.isEmpty
                            ? Text(
                                userProfile.username.substring(0, 1).toUpperCase(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20),
                              color: Theme.of(context).colorScheme.onPrimary,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_outlined),
                                        title: const Text('Take Photo'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _takePhoto();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_outlined),
                                        title: const Text('Choose from Gallery'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage();
                                        },
                                      ),
                                      if (_selectedImage != null || userProfile.profilePictureUrl.isNotEmpty)
                                        ListTile(
                                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                                          title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _selectedImage = null;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Username
                  CustomTextField(
                    label: 'Username',
                    controller: _usernameController,
                    validator: (value) => Validators.validateRequired(value, 'Username'),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  CustomTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'City',
                    controller: _cityController,
                    validator: (value) => Validators.validateRequired(value, 'City'),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Area',
                    controller: _areaController,
                    validator: (value) => Validators.validateRequired(value, 'Area'),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _userType,
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
                      DropdownMenuItem(value: 'Feeder', child: Text('Feeder')),
                      DropdownMenuItem(value: 'NGO Member', child: Text('NGO Member')),
                      DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: _isEditing ? (v) => setState(() => _userType = v) : null,
                    validator: (value) => Validators.validateRequired(value, 'User Type'),
                  ),
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Cancel',
                            onPressed: _cancelEdit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            text: 'Save',
                            onPressed: _isLoading ? null : _saveProfile,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/my-dogs');
                            },
                            icon: const Icon(Icons.pets_outlined),
                            label: const Text('My Mitrans'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/my-posts');
                            },
                            icon: const Icon(Icons.post_add_outlined),
                            label: const Text('My Posts'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_outlined),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardian Account',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member Since',
                            value: _formatDate(userProfile.createdAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.update_outlined,
                            label: 'Last Updated',
                            value: _formatDate(userProfile.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading profile: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}