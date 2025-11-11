import 'package:flutter/material.dart';
import 'package:habit_tracker/models/shop_modal.dart';

class StatsOverview extends StatelessWidget {
  final int totalPoints;
  final int currentStreak;
  final int totalHabits;
  final int checkedInToday;
  final int treeHealth;
  final List<String> diseases;
  final Map<String, int> inventory;
  final List<ShopItem> shopItems;
  final Function(String, String, int) onUseItem;

  const StatsOverview({
    super.key,
    required this.totalPoints,
    required this.currentStreak,
    required this.totalHabits,
    required this.checkedInToday,
    required this.treeHealth,
    required this.diseases,
    required this.inventory,
    required this.shopItems,
    required this.onUseItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            context,
            icon: Icons.stars,
            value: totalPoints.toString(),
            label: 'Điểm',
            color: Colors.amber,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            icon: Icons.local_fire_department,
            value: currentStreak.toString(),
            label: 'Chuỗi',
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildHealthCard(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color color,
      }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context) {
    final healthColor = Color(
      int.parse(
        treeHealth >= 80
            ? 'FF4CAF50'
            : treeHealth >= 60
            ? 'FF8BC34A'
            : treeHealth >= 40
            ? 'FFFFC107'
            : treeHealth >= 20
            ? 'FFFF9800'
            : 'FFF44336',
        radix: 16,
      ),
    );

    // Map diseases to user-friendly names and emojis
    final diseaseDisplay = diseases.map((d) {
      return {
        'name': {
          'pest': 'Sâu bệnh 🐛',
          'drought': 'Hạn hán 🏜️',
          'fungus': 'Nấm mốc 🍄',
        }[d] ?? 'Bệnh không xác định 🦠',
        'effectType': 'cure_$d',
      };
    }).toList();

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: healthColor, size: 28),
              const SizedBox(height: 8),
              Text(
                '$treeHealth/100',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sức khỏe cây',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (shopItems.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Đang tải vật phẩm...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if (diseases.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  diseaseDisplay.map((d) => d['name'] as String).join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ...diseaseDisplay.map((disease) {
                  final effectType = disease['effectType'] as String;
                  final item = shopItems.firstWhere(
                        (item) => item.effectType == effectType,
                    orElse: () => ShopItem(
                      id: '',
                      name: 'Thuốc không xác định',
                      description: 'Không tìm thấy thuốc',
                      icon: '🧪',
                      cost: 0,
                      effectType: effectType,
                      effectValue: 0,
                      quantity: 0,
                    ),
                  );
                  final ownedQuantity = inventory[item.id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ElevatedButton(
                      onPressed: ownedQuantity > 0
                          ? () => onUseItem(item.id, item.effectType, item.effectValue)
                          : () => Navigator.pushNamed(context, '/shop', arguments: 'medicine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ownedQuantity > 0 ? Colors.green : Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Text(
                        ownedQuantity > 0
                            ? 'Dùng ${item.name} ($ownedQuantity)'
                            : 'Mua ${item.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }),
              ] else if (treeHealth < 80) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/shop', arguments: 'fertilizer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Mua phân bón',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}