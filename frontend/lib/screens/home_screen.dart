import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../providers/image_provider.dart' as custom;
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<custom.ImageProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Enhancement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<custom.ImageProvider>(
        builder: (context, imageProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server Status Card
                _buildServerStatusCard(imageProvider),
                const SizedBox(height: 16),

                // Image Preview Card
                if (imageProvider.originalImage != null)
                  _buildImagePreviewCard(imageProvider),

                const SizedBox(height: 16),

                // Enhancement Method Selector
                if (imageProvider.methods.isNotEmpty &&
                    imageProvider.originalImage != null)
                  _buildMethodSelector(imageProvider),

                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(context, imageProvider),

                // Error Message
                if (imageProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildErrorCard(imageProvider),
                  ),

                // Processing Indicator
                if (imageProvider.isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        SpinKitFadingCircle(color: Colors.blue, size: 50.0),
                        SizedBox(height: 16),
                        Text(
                          'Enhancing image...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServerStatusCard(custom.ImageProvider imageProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              imageProvider.isServerOnline
                  ? Icons.check_circle
                  : Icons.error_outline,
              color: imageProvider.isServerOnline ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imageProvider.isServerOnline
                        ? 'Server Online'
                        : 'Server Offline',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageProvider.isServerOnline
                        ? 'Ready to enhance images'
                        : 'Please start Flask backend',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => imageProvider.checkServerStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard(custom.ImageProvider imageProvider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(imageProvider.originalImage!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: imageProvider.clearImages,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(custom.ImageProvider imageProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enhancement Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: imageProvider.selectedMethod,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: imageProvider.methods.map((method) {
                return DropdownMenuItem(
                  value: method.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        method.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Flexible(
                        child: Text(
                          method.description,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  imageProvider.setMethod(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    custom.ImageProvider imageProvider,
  ) {
    return Column(
      children: [
        // Pick from Gallery
        ElevatedButton.icon(
          onPressed: imageProvider.isProcessing
              ? null
              : () => imageProvider.pickImageFromGallery(),
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),

        // Take Photo
        ElevatedButton.icon(
          onPressed: imageProvider.isProcessing
              ? null
              : () => imageProvider.pickImageFromCamera(),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),

        // Enhance Image Button
        if (imageProvider.originalImage != null)
          FilledButton.icon(
            onPressed:
                imageProvider.isProcessing || !imageProvider.isServerOnline
                    ? null
                    : () async {
                        await imageProvider.enhanceImage();

                        if (imageProvider.enhancedImage != null &&
                            context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResultScreen(),
                            ),
                          );
                        }
                      },
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Enhance Image'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorCard(custom.ImageProvider imageProvider) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                imageProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: imageProvider.clearError,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Enhancement App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'This app uses machine learning to enhance and deblur images.',
            ),
            SizedBox(height: 16),
            Text(
              'Make sure the Flask backend is running on:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text('http://127.0.0.1:5000'),
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
}
