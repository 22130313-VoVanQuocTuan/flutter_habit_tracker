class WeatherData {
  final String condition; // ví dụ: "Rain", "Clear", "Clouds"
  final bool isDay;
  final double temperature;
  final String cityName;

  WeatherData({
    required this.condition,
    required this.isDay,
    required this.temperature,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather']?[0]?['main'] ?? 'Clear') as String;
    final icon = (json['weather']?[0]?['icon'] ?? '') as String;

    // Xác định là ban ngày hay ban đêm dựa vào icon hoặc thời gian
    bool isDay;
    if (icon.isNotEmpty) {
      isDay = icon.endsWith('d');
    } else {
      final dt = json['dt'] ?? 0;
      final sunrise = json['sys']?['sunrise'] ?? 0;
      final sunset = json['sys']?['sunset'] ?? 0;
      isDay = dt > sunrise && dt < sunset;
    }

    return WeatherData(
      condition: weather.toLowerCase(),
      isDay: isDay,
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      cityName: json['name'] ?? '',
    );
  }
}
