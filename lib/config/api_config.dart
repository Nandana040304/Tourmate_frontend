import 'package:http/http.dart' as http;
class ApiConfig {
  static const String baseUrl = "http://192.168.1.7:8000";

  static const String profile = "$baseUrl/api/profile/";
  static const String sendSOS = "$baseUrl/api/sos/send-sos/";
  static const String forgotPassword = "$baseUrl/api/forgot-password/";
  static const String login = "$baseUrl/api/login/";
  static const String nearbyPlaces = "$baseUrl/api/nearby/";
  static const String resetPassword = "$baseUrl/api/reset-password/";
  static const String signup = "$baseUrl/api/signup/";
  static const String getPhotos =
      "$baseUrl/api/photodiary/my-photos/";

  static const String uploadPhoto =
      "$baseUrl/api/photodiary/upload/";

  static const String deletePhoto =
      "$baseUrl/api/photodiary/delete/";
  static const String weather = "/api/weather/";

}
class ApiService {
  static Future<http.Response> get(String endpoint, String token) {
    return http.get(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }
}