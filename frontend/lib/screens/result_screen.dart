import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/image_provider.dart' as custom;

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhancement Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Consumer<custom.ImageProvider>(
        builder: (context, imageProvider, child) {
          if (imageProvider.enhancedImage == null) {
            return const Center(child: Text('No enhanced image available'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Comparison View
                _buildComparisonView(imageProvider),

                // Metrics Card
                if (imageProvider.enhancementResult != null)
                  _buildMetricsCard(imageProvider),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          // TODO: Implement save functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Save feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Enhanced Image'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          imageProvider.clearImages();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Enhance Another Image'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
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

  Widget _buildComparisonView(custom.ImageProvider imageProvider) {
    return Column(
      children: [
        // Before/After Toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Swipe to compare',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.compare, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),

        // Original Image
        _buildImageSection(
          title: 'Original',
          image: Image.file(imageProvider.originalImage!, fit: BoxFit.contain),
        ),

        const Divider(height: 32, thickness: 2),

        // Enhanced Image
        _buildImageSection(
          title: 'Enhanced',
          image: Image.memory(
            imageProvider.enhancedImage!,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection({required String title, required Widget image}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: image,
        ),
      ],
    );
  }

  Widget _buildMetricsCard(custom.ImageProvider imageProvider) {
    final result = imageProvider.enhancementResult!;
    final metrics = result.metrics;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Quality Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Method Used
              _buildMetricRow(
                'Method',
                result.method.toUpperCase(),
                icon: Icons.tune,
              ),

              const Divider(height: 24),

              // PSNR
              if (metrics.psnr != null)
                _buildMetricRow(
                  'PSNR',
                  '${metrics.psnr!.toStringAsFixed(2)} dB',
                  subtitle: 'Peak Signal-to-Noise Ratio',
                ),

              // SSIM
              if (metrics.ssim != null)
                _buildMetricRow(
                  'SSIM',
                  metrics.ssim!.toStringAsFixed(4),
                  subtitle: 'Structural Similarity Index',
                ),

              // Sharpness Improvement
              if (metrics.sharpnessImprovement != null)
                _buildMetricRow(
                  'Sharpness Improvement',
                  '${metrics.sharpnessImprovement! > 0 ? '+' : ''}${metrics.sharpnessImprovement!.toStringAsFixed(1)}%',
                  subtitle: 'Change in image sharpness',
                  valueColor: metrics.sharpnessImprovement! > 0
                      ? Colors.green
                      : Colors.orange,
                ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Higher PSNR and SSIM values indicate better quality',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    String? subtitle,
    IconData? icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
