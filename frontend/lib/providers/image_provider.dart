import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/enhancement_models.dart';
import '../services/api_service.dart';

class ImageProvider extends ChangeNotifier {
  File? _originalImage;
  Uint8List? _enhancedImage;
  EnhancementResult? _enhancementResult;
  List<EnhancementMethod> _methods = [];
  String _selectedMethod = 'auto';
  bool _isProcessing = false;
  bool _isServerOnline = false;
  String? _errorMessage;

  // Getters
  File? get originalImage => _originalImage;
  Uint8List? get enhancedImage => _enhancedImage;
  EnhancementResult? get enhancementResult => _enhancementResult;
  List<EnhancementMethod> get methods => _methods;
  String get selectedMethod => _selectedMethod;
  bool get isProcessing => _isProcessing;
  bool get isServerOnline => _isServerOnline;
  String? get errorMessage => _errorMessage;
  bool get hasImages => _originalImage != null;

  final ImagePicker _picker = ImagePicker();

  // Initialize - check server status and load methods
  Future<void> initialize() async {
    await checkServerStatus();
    if (_isServerOnline) {
      await loadEnhancementMethods();
    }
  }

  // Check if Flask server is online
  Future<void> checkServerStatus() async {
    try {
      _isServerOnline = await ApiService.checkHealth();
      _errorMessage = _isServerOnline ? null : 'Server is offline';
    } catch (e) {
      _isServerOnline = false;
      _errorMessage = 'Cannot connect to server';
    }
    notifyListeners();
  }

  // Load available enhancement methods from backend
  Future<void> loadEnhancementMethods() async {
    try {
      _methods = await ApiService.getEnhancementMethods();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load enhancement methods';
      notifyListeners();
    }
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (image != null) {
        _originalImage = File(image.path);
        _enhancedImage = null;
        _enhancementResult = null;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (image != null) {
        _originalImage = File(image.path);
        _enhancedImage = null;
        _enhancementResult = null;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  // Set enhancement method
  void setMethod(String method) {
    _selectedMethod = method;
    notifyListeners();
  }

  // Enhance the current image
  Future<void> enhanceImage() async {
    if (_originalImage == null) {
      _errorMessage = 'No image selected';
      notifyListeners();
      return;
    }

    if (!_isServerOnline) {
      _errorMessage = 'Server is not available';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.enhanceImage(
        imageFile: _originalImage!,
        method: _selectedMethod,
      );

      _enhancementResult = result;
      _enhancedImage = ApiService.decodeBase64Image(result.enhancedImageBase64);

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      _enhancedImage = null;
      _enhancementResult = null;
      notifyListeners();
    }
  }

  // Clear all images
  void clearImages() {
    _originalImage = null;
    _enhancedImage = null;
    _enhancementResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Reset error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
