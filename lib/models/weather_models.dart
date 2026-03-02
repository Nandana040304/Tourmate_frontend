class WeatherCondition {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final double rainfall;

  WeatherCondition({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
  });
}

class TouristDestination {
  final String name;
  final double distance;
  final double latitude;
  final double longitude;
  final WeatherCondition weather;

  TouristDestination({
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.weather,
  });
}