import 'package:flutter/material.dart';
import 'package:habit_tracker/models/weather_data.dart';
import 'package:lottie/lottie.dart';
import '../../../models/user_model.dart';

class TreeWidget extends StatelessWidget {
  final UserModel? userProfile;
  final bool isLoading;
  final WeatherData? weatherData;

  const TreeWidget({
    super.key,
    this.userProfile,
    this.isLoading = false,
    this.weatherData,
  });


  String _getTreeImagePath() {
    final level = userProfile?.treeLevel ?? 0;

    // Nếu cây chết thì dùng ảnh cây chết
    if (userProfile?.isTreeDead == true) {
      return 'assets/images/trees/tree_dead.png';
    }

    // Nếu có bệnh, ưu tiên kiểm tra từng loại bệnh
    if (userProfile?.diseases.isNotEmpty ?? false) {
      final diseases = userProfile!.diseases;

      if (diseases.contains('drought')) {
        // Hạn hán
        return 'assets/images/trees/tree_level_${level}_${level}.png';
      } else if (diseases.contains('pest')) {
        // Sâu bệnh
        return 'assets/images/trees/tree_level_${level}_${level}_${level}.png';
      } else if (diseases.contains('fungus')) {
        // Nấm mốc
        return 'assets/images/trees/tree_level_${level}_${level}_${level}_${level}.png';
      }
    }

    // Mặc định: cây bình thường
    return 'assets/images/trees/tree_level_$level.png';
  }

  String _getTreeDescription() {
    switch (userProfile?.treeLevel ?? 0) {
      case 0:
        return 'Hạt giống – Hành trình bắt đầu! 🌱';
      case 1:
        return 'Mầm non – Đang vươn mình đón nắng! 🌿';
      case 2:
        return 'Cây non – Bắt đầu xanh tốt! 🌳';
      case 3:
        return 'Cây trưởng thành – Vững vàng và tươi tốt! 🌴';
      case 4:
        return 'Cây ra hoa – Thành quả nở rộ! 🌸';
      default:
        return 'Tiếp tục chăm sóc cây của bạn nhé! 🌾';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userProfile == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[600]!,
            Colors.green[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tree Image
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🌳 Cây chính
                Image.asset(
                  _getTreeImagePath(),
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      ['🌰', '🌱', '🌿', '🌳', '🌲'][userProfile?.treeLevel ?? 0],
                      style: const TextStyle(fontSize: 60),
                    );
                  },
                ),

                // 🌦️ Hiệu ứng thời tiết
                if (weatherData != null)
                  Positioned(
                    top: -5, // khoảng cách từ trên xuống
                    right: -10, // để nằm góc phải; đổi thành left: 10 nếu muốn bên trái
                    child: SizedBox(
                      width: 90,  // kích thước hiệu ứng nhỏ
                      height: 90,
                      child: _buildWeatherEffect(weatherData!),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            _getTreeDescription(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${userProfile!.treeLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${userProfile!.totalPoints} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _calculateProgress(),
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userProfile!.treeLevel < 4
                    ? '${userProfile!.pointsToNextLevel} điểm để lên level tiếp theo'
                    : 'Đã đạt cấp tối đa! 🎉',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildWeatherEffect(WeatherData weather) {
    // Ưu tiên hiển thị hiệu ứng ban đêm
    if (!weather.isDay) {
      return Lottie.asset(
        'assets/lottie/night.json',
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    }

    switch (weather.condition.toLowerCase()) {
      case 'rain':
      case 'rainy':
        return Lottie.asset(
          'assets/lottie/rain.json',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        );
      case 'clear':
      case 'sunny':
        return Lottie.asset(
          'assets/lottie/sunny.json',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        );
      case 'clouds':
      case 'cloudy':
        return Lottie.asset(
          'assets/lottie/cloudy.json',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  double _calculateProgress() {
    if (userProfile == null || userProfile!.treeLevel >= 4) return 1.0;

    const levelThresholds = [0, 100, 300, 600, 1000];
    final currentLevel = userProfile!.treeLevel;
    final currentPoints = userProfile!.totalPoints;
    final currentLevelPoints = levelThresholds[currentLevel];
    final nextLevelPoints = levelThresholds[currentLevel + 1];
    final pointsInLevel = currentPoints - currentLevelPoints;
    final pointsNeeded = nextLevelPoints - currentLevelPoints;

    return (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
  }
}