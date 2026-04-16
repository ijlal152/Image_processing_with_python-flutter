class ApiConfig {
  // Change this to your computer's local IP address when testing on physical device
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use 127.0.0.1 or localhost
  // For Physical Device: use your computer's IP address (e.g., 192.168.1.100)

  // static const String baseUrl = 'http://127.0.0.1:8000'; // For iOS Simulator / Web
  // static const String baseUrl = 'http://10.0.2.2:8000'; // For Android Emulator
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Default - Change to your IP for physical device

  static const String enhanceImageEndpoint = '/enhance_image';
  static const String healthEndpoint = '/health';
  static const String methodsEndpoint = '/methods';

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 60);

  // Maximum image size (in bytes) - 10MB
  static const int maxImageSize = 10 * 1024 * 1024;

  // Compression quality (0-100)
  static const int compressionQuality = 85;
}
