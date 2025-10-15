// lib/config/api_config.dart
class ApiConfig {
  // OpenAI API Key - Replace with your actual key
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  
  // Geoapify API Key - Replace with your actual key
  static const String geoapifyApiKey = 'YOUR_GEOAPIFY_API_KEY_HERE';
  
  // Weather API Key - Replace with your actual key
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY_HERE';
  
  // Check if API keys are configured
  static bool get isOpenAiConfigured => openAiApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  static bool get isGeoapifyConfigured => geoapifyApiKey != 'YOUR_GEOAPIFY_API_KEY_HERE';
  static bool get isWeatherConfigured => weatherApiKey != 'YOUR_WEATHER_API_KEY_HERE';
  
  // Get API key with fallback
  static String getOpenAiKey() {
    if (isOpenAiConfigured) return openAiApiKey;
    return ''; // Return empty string if not configured
  }
  
  static String getGeoapifyKey() {
    if (isGeoapifyConfigured) return geoapifyApiKey;
    return ''; // Return empty string if not configured
  }
  
  static String getWeatherKey() {
    if (isWeatherConfigured) return weatherApiKey;
    return ''; // Return empty string if not configured
  }
}
