import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';
import '../config/api_config.dart';

class WeatherSafetyScreen extends StatefulWidget {
  const WeatherSafetyScreen({super.key});

  @override
  State<WeatherSafetyScreen> createState() => _WeatherSafetyScreenState();
}

class _WeatherSafetyScreenState extends State<WeatherSafetyScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  TouristDestination? _result;
  String _safetyStatus = "";

  Future<void> _searchWeather() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          "${ApiConfig.baseUrl}${ApiConfig.weather}?destination=${Uri.encodeComponent(_searchController.text.trim())}"
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);
      final weather = data['weather'];

      setState(() {
        _result = TouristDestination(
          name: data['destination'],
          distance: 0,
          latitude: 0,
          longitude: 0,
          weather: WeatherCondition(
            temperature: (weather['temperature'] as num).toDouble(),
            condition: weather['condition'],
            humidity: weather['humidity'],
            windSpeed: (weather['windSpeed'] as num).toDouble(),
            rainfall: (weather['rainfall'] as num).toDouble(),
          ),
        );
        _safetyStatus = data['safetyStatus'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🔹 WEATHER GRID CARD
  Widget _weatherInfoCard() {
    if (_result == null) return const SizedBox();
    final w = _result!.weather;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400), // 🔥 LIMIT WIDTH
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Weather at ${_result!.name}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9, // 🔥 compact look
                  ),
                  itemBuilder: (context, index) {
                    final items = [
                      _gridItem(Icons.thermostat, "Temperature", "${w.temperature}°C",
                          Colors.orange.shade100),
                      _gridItem(Icons.wb_sunny, "Condition", w.condition,
                          Colors.blue.shade100),
                      _gridItem(Icons.water_drop, "Humidity", "${w.humidity}%",
                          Colors.teal.shade100),
                      _gridItem(Icons.air, "Wind Speed", "${w.windSpeed} km/h",
                          Colors.grey.shade200),
                      _gridItem(Icons.grain, "Rainfall", "${w.rainfall} mm",
                          Colors.indigo.shade100),
                    ];
                    return items[index];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridItem(
      IconData icon, String title, String value, Color bgColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // 🔹 SAFETY CARD
  Widget _safetyCard() {
    if (_result == null) return const SizedBox();

    final isSafe = _safetyStatus.toLowerCase() == "safe";

    return Card(
      color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          isSafe ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(isSafe ? Icons.check : Icons.warning,
              color: isSafe ? Colors.green : Colors.red),
        ),
        title: Text(
          isSafe ? "Safe to Go" : "Not Safe",
          style: TextStyle(
              color: isSafe ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        subtitle: Text(isSafe
            ? "Weather conditions are favorable for travel"
            : "Weather conditions are not favorable"),
      ),
    );
  }

  // 🔹 RECOMMENDED ACTIONS
  Widget _recommendedActions() {
    if (_result == null) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue),
                SizedBox(width: 8),
                Text("Recommended Actions",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            _ActionItem("Perfect weather for sightseeing"),
            _ActionItem("Great conditions for photography"),
            _ActionItem("Safe for outdoor activities"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text("Weather & Safety"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search destination (e.g., Munnar)",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _searchWeather,
              icon: const Icon(Icons.cloud),
              label: const Text("Get Weather"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading && _result != null) ...[
              _weatherInfoCard(),
              const SizedBox(height: 16),
              _safetyCard(),
              const SizedBox(height: 16),
              _recommendedActions(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String text;
  const _ActionItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}