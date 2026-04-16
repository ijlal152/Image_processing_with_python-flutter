class EnhancementMethod {
  final String id;
  final String name;
  final String description;

  EnhancementMethod({
    required this.id,
    required this.name,
    required this.description,
  });

  factory EnhancementMethod.fromJson(Map<String, dynamic> json) {
    return EnhancementMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}

class ImageMetrics {
  final double? psnr;
  final double? ssim;
  final double? originalSharpness;
  final double? enhancedSharpness;
  final double? sharpnessImprovement;

  ImageMetrics({
    this.psnr,
    this.ssim,
    this.originalSharpness,
    this.enhancedSharpness,
    this.sharpnessImprovement,
  });

  factory ImageMetrics.fromJson(Map<String, dynamic> json) {
    return ImageMetrics(
      psnr: json['psnr']?.toDouble(),
      ssim: json['ssim']?.toDouble(),
      originalSharpness: json['original_sharpness']?.toDouble(),
      enhancedSharpness: json['enhanced_sharpness']?.toDouble(),
      sharpnessImprovement: json['sharpness_improvement']?.toDouble(),
    );
  }
}

class EnhancementResult {
  final String enhancedImageBase64;
  final String originalFilename;
  final String enhancedFilename;
  final String method;
  final ImageMetrics metrics;
  final String timestamp;

  EnhancementResult({
    required this.enhancedImageBase64,
    required this.originalFilename,
    required this.enhancedFilename,
    required this.method,
    required this.metrics,
    required this.timestamp,
  });

  factory EnhancementResult.fromJson(Map<String, dynamic> json) {
    return EnhancementResult(
      enhancedImageBase64: json['enhanced_image'] as String,
      originalFilename: json['original_filename'] as String,
      enhancedFilename: json['enhanced_filename'] as String,
      method: json['method'] as String,
      metrics: ImageMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as String,
    );
  }
}
