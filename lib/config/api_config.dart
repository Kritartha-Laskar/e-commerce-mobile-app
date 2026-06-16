class ApiConfig {
  // 🔥 Switch between environments by uncommenting the one you need:

  // 🖥️ Local browser testing (Chrome / web)
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static const String storageUrl = "http://127.0.0.1:8000/storage";

  // Android emulator
  // static const String baseUrl = "http://10.0.2.2:8000/api";
  // static const String storageUrl = "http://10.0.2.2:8000/storage";

  // 🌐 Ngrok (physical device / APK) — tunnel is currently OFFLINE
  // static const String baseUrl = "https://punctuate-vision-spinner.ngrok-free.dev/api";
  // static const String storageUrl = "https://punctuate-vision-spinner.ngrok-free.dev/storage";
}
