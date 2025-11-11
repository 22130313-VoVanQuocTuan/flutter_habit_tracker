import 'dart:convert';
import 'package:habit_tracker/models/weather_data.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String apiKey = '50e28d94f9cc85814a17ce5c46a53898';

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí đang tắt. Vui lòng bật GPS 📍');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // 🔹 Nếu quyền bị từ chối, thì xin lại
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Người dùng đã từ chối quyền vị trí ❌');
      }
    }

    // 🔹 Nếu người dùng từ chối vĩnh viễn
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Quyền vị trí bị từ chối vĩnh viễn ❌. Vui lòng bật lại trong phần Cài đặt.');
    }

    // 🔹 Nếu đến đây thì quyền hợp lệ, trả về vị trí hiện tại
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<WeatherData> fetchWeather() async {
    // 🔹 Toạ độ của TP. Hồ Chí Minh
    const double latitude = 10.762622;
    const double longitude = 106.660172;

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
    );

    print('🌍 Gửi request đến: $url');

    final response = await http.get(url);
    print('📡 Status code: ${response.statusCode}');
    print('📦 Raw data: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final weatherData = WeatherData.fromJson(data);

    print('✅ Giải mã JSON thành công: ${weatherData.condition}');
    print('☀️ isDay = ${weatherData.isDay}');

    return weatherData;
  }
}
