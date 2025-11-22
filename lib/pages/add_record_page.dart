import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/dog_model.dart';
import '../services/firestore_service.dart';
import '../providers/service_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';

class AddRecordPage extends ConsumerStatefulWidget {
  final String? qrCodeId;
  const AddRecordPage({super.key, this.qrCodeId});

  @override
  ConsumerState<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends ConsumerState<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _temperamentController = TextEditingController();
  final _healthNotesController = TextEditingController();

  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  bool _vaccinated = false;
  bool _sterilized = false;
  bool _readyForAdoption = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _temperamentController.dispose();
    _healthNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
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
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (images.isNotEmpty && mounted) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  Future<void> _takePhoto() async {
    final permissionService = ref.read(permissionServiceProvider);
    final hasCameraPermission = await permissionService
        .requestCameraPermission();
    final hasGalleryPermission = await permissionService
        .requestStoragePermission();

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
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (photo != null && mounted) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
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

      // Prevent duplicate records for same QR code ID
      final qrId = widget.qrCodeId?.trim();
      if (qrId != null && qrId.isNotEmpty) {
        final qrService = ref.read(qrServiceProvider);
        final existing = await qrService.getDogByQRCode(qrId);
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A record already exists for this ID')),
            );
            // Navigate to existing dog profile
            context.push('/directory/${existing.dogId}');
          }
          return;
        }
      }

      // Get user profile
      final userProfile = await ref.read(userProfileProvider(user.uid).future);

      // Create initial dog record
      final firestoreService = FirestoreService();
      final dog = DogModel(
        dogId: '',
        qrCodeId: widget.qrCodeId,
        name: _nameController.text.trim(),
        photos: const [],
        mainPhotoUrl: '',
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        vaccinationStatus: _vaccinated,
        sterilizationStatus: _sterilized,
        readyForAdoption: _readyForAdoption,
        temperament: _temperamentController.text.trim(),
        healthNotes: _healthNotesController.text.trim(),
        addedBy: DogAddedBy(
          userId: user.uid,
          username: userProfile.username,
          contactInfo: userProfile.contactInfo,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dogId = await firestoreService.createDogRecord(dog, user.uid);

      // Upload images and update record
      final storageService = ref.read(storageServiceProvider);
      final List<String> imageUrls = [];
      for (final entry in _selectedImages.asMap().entries) {
        final index = entry.key;
        final file = File(entry.value.path);
        try {
          final url = await storageService.uploadDogPhoto(file, dogId, index, user.uid);
          imageUrls.add(url);
        } catch (_) {}
      }

      // Enforce at least one uploaded photo; delete record if none
      if (imageUrls.isEmpty) {
        await firestoreService.deleteDogRecord(dogId, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('At least one image is required. Record not saved.')),
          );
        }
        return;
      }

      await firestoreService.updateDogRecord(dogId, {
        'photos': imageUrls,
        'mainPhotoUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog record created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating record: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Mitran Record'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.qrCodeId != null && widget.qrCodeId!.isNotEmpty) ...[
                Text(
                  'Mitran ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: widget.qrCodeId,
                  decoration: const InputDecoration(
                    labelText: 'Mitran ID',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
              ],
              // Photos section
              Text(
                'Photos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add photo button
                    InkWell(
                      onTap: () => _showImagePickerOptions(),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selected images
                    ..._selectedImages.map(
                      (image) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.remove(image);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic information
              Text(
                'Basic Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter dog name',
                  prefixIcon: Icon(Icons.pets_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'Name'),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area *',
                  hintText: 'Enter locality/area',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'Area'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'Enter city',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'City'),
              ),
              const SizedBox(height: 24),

              // Additional information
              Text(
                'Additional Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Temperament
              TextFormField(
                controller: _temperamentController,
                decoration: const InputDecoration(
                  labelText: 'Temperament',
                  hintText: 'e.g., Friendly, Shy, Playful, Aggressive',
                  prefixIcon: Icon(Icons.psychology_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Health Notes
              TextFormField(
                controller: _healthNotesController,
                decoration: const InputDecoration(
                  labelText: 'Health Notes',
                  hintText: 'Optional health notes',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 300,
              ),
              const SizedBox(height: 16),
              // Status checkboxes
              CheckboxListTile(
                value: _vaccinated,
                onChanged: (v) => setState(() => _vaccinated = v ?? false),
                title: const Text('Vaccinated'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _sterilized,
                onChanged: (v) => setState(() => _sterilized = v ?? false),
                title: const Text('Sterilized'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _readyForAdoption,
                onChanged: (v) =>
                    setState(() => _readyForAdoption = v ?? false),
                title: const Text('Ready for Adoption'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
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
              _pickImages();
            },
          ),
          if (_selectedImages.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Remove All Photos',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedImages.clear();
                });
              },
            ),
        ],
      ),
    );
  }
}
