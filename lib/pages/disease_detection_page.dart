import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/prediction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';

class DiseaseDetectionPage extends ConsumerStatefulWidget {
  const DiseaseDetectionPage({super.key});

  @override
  ConsumerState<DiseaseDetectionPage> createState() =>
      _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends ConsumerState<DiseaseDetectionPage> {
  XFile? _selectedImage;
  final List<PredictionModel> _predictions = [];
  bool _isAnalyzing = false;
  bool _hasResults = false;
  bool _apiReady = true;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkHealth);
  }

  Future<void> _pickFromGallery() async {
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
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _selectedImage = image;
        _hasResults = false;
        _predictions.clear();
      });
      debugPrint('detect: gallery image selected ${image.path}');
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
        _selectedImage = photo;
        _hasResults = false;
        _predictions.clear();
      });
      debugPrint('detect: camera image captured ${photo.path}');
    }
  }

  Future<void> _checkHealth() async {
    if (mounted) setState(() { _checkingHealth = true; });
    final ok = await ref.read(diseaseDetectionServiceProvider).checkHealth();
    if (mounted) setState(() { _apiReady = ok; _checkingHealth = false; });
    debugPrint('detect: health ${ok ? 'ok' : 'starting/unavailable'}');
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI service ready')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    if (!_apiReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI service is starting up. Please retry.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _predictions.clear();
    });

    try {
      // Get current user
      final user = ref.read(authProvider).value;
      final userId = user?.uid ?? 'anonymous';

      final file = File(_selectedImage!.path);
      final diseaseService = ref.read(diseaseDetectionServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      debugPrint('detect: analyze start for ${_selectedImage!.path}');

      // Analyze via API (multipart)
      final apiRes = await diseaseService.predict(file);
      final label = apiRes['label']?.toString() ?? 'Unknown';
      final confidence = (apiRes['confidence'] ?? 0).toDouble();
      final title = apiRes['title']?.toString() ?? '';
      final description = apiRes['description']?.toString() ?? '';
      final symptoms = List<String>.from(apiRes['symptoms'] ?? []);
      final treatments = List<String>.from(apiRes['treatments'] ?? []);
      final homecare = List<String>.from(apiRes['homecare'] ?? []);
      final note = apiRes['note']?.toString() ?? '';

      // Upload image to Storage (best-effort)
      String downloadUrl = '';
      try {
        downloadUrl = await storageService.uploadDiseaseScanImage(file, userId);
        debugPrint('detect: storage upload ok');
      } catch (e) {
        debugPrint('detect: storage upload failed: $e');
      }

      

      final model = PredictionModel(
        predictionId: null,
        imageUrl: downloadUrl,
        label: label,
        confidence: confidence,
        title: title,
        description: description,
        symptoms: symptoms,
        treatments: treatments,
        homecare: homecare,
        note: note,
        userId: userId,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _predictions.clear();
          _predictions.add(model);
          _hasResults = true;
          _isAnalyzing = false;
        });
        debugPrint('detect: analysis complete');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
        debugPrint('detect: analyze error: $e');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasResults = false;
      _predictions.clear();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _predictions.clear();
      _hasResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Disease Scan'),
        centerTitle: true,
        actions: [
          if (_selectedImage != null)
            IconButton(icon: const Icon(Icons.clear_all), onPressed: _clearAll),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _checkHealth()),
        ],
      ),
      body: Column(
        children: [
          if (_checkingHealth)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Checking AI service...')),
                ],
              ),
            ),
          if (!_checkingHealth && !_apiReady)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('AI service starting up. Please wait...')),
                  TextButton(onPressed: () => _checkHealth(), child: const Text('Retry')),
                ],
              ),
            ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Take or upload a clear photo of the affected area for a preliminary analysis',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image selection section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.close),
                        label: const Text('Remove'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

          // Add images section
                  Text(
            'Add Image',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),

                  // Analysis results
                  if (_hasResults && _predictions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Analysis Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._predictions.map(
                      (prediction) {
                        final percent = prediction.confidence <= 1
                            ? prediction.confidence * 100
                            : prediction.confidence;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (prediction.title.isNotEmpty)
                                  Text(
                                    prediction.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                Text('${percent.toStringAsFixed(1)}%'),
                                if (prediction.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(prediction.description),
                                  ),
                                if (prediction.symptoms.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Symptoms',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  ...prediction.symptoms.map((s) => Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(s)),
                                        ],
                                      )),
                                ],
                                if (prediction.treatments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Treatments',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  ...prediction.treatments.map((t) => Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(t)),
                                        ],
                                      )),
                                ],
                                if (prediction.homecare.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Home Care',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  ...prediction.homecare.map((h) => Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(h)),
                                        ],
                                      )),
                                ],
                                if (prediction.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(prediction.note),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Disclaimer
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is not a substitute for a vet. Use for preliminary guidance only.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Analyze button
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing || !_apiReady ? null : _analyzeImage,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
