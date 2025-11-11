import 'package:cloud_firestore/cloud_firestore.dart';
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int cost; // coins
  final String effectType; // 'cure_pest', 'cure_drought', 'cure_fungus', 'heal', 'resurrect'
  final int effectValue;
  final int quantity; // Available stock

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.effectType,
    required this.effectValue,
    required this.quantity,
  });

  // Factory to create ShopItem from Firestore document
  factory ShopItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ShopItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      cost: data['cost'] ?? 0,
      effectType: data['effectType'] ?? '',
      effectValue: data['effectValue'] ?? 0,
      quantity: data['quantity'] ?? 0,
    );
  }

  // Convert ShopItem to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'cost': cost,
      'effectType': effectType,
      'effectValue': effectValue,
      'quantity': quantity,
    };
  }

  /// 🪴 Khởi tạo dữ liệu mặc định cho shop_items nếu chưa có
  // static Future<void> initializeShopItems() async {
  //   final items = [
  //     {
  //       'id': 'medicine_pest',
  //       'name': 'Thuốc diệt sâu 🧴',
  //       'description': 'Giết sâu bệnh - Khôi phục +30 health',
  //       'icon': '🧴',
  //       'cost': 50,
  //       'effectType': 'cure_pest',
  //       'effectValue': 30,
  //       'quantity': 10,
  //     },
  //     {
  //       'id': 'medicine_drought',
  //       'name': 'Bình tưới nước 💧',
  //       'description': 'Tưới cây khô - Khôi phục +25 health',
  //       'icon': '🚿',
  //       'cost': 40,
  //       'effectType': 'cure_drought',
  //       'effectValue': 25,
  //       'quantity': 15,
  //     },
  //     {
  //       'id': 'medicine_fungus',
  //       'name': 'Thuốc diệt nấm 🍄',
  //       'description': 'Chữa nấm - Khôi phục +35 health',
  //       'icon': '🧪',
  //       'cost': 60,
  //       'effectType': 'cure_fungus',
  //       'effectValue': 35,
  //       'quantity': 12,
  //     },
  //     {
  //       'id': 'fertilizer_basic',
  //       'name': 'Phân bón cơ bản',
  //       'description': 'Tăng +15 health',
  //       'icon': '🌾',
  //       'cost': 30,
  //       'effectType': 'heal',
  //       'effectValue': 15,
  //       'quantity': 20,
  //     },
  //     {
  //       'id': 'fertilizer_premium',
  //       'name': 'Phân bón cao cấp',
  //       'description': 'Tăng +40 health',
  //       'icon': '🌳',
  //       'cost': 80,
  //       'effectType': 'heal',
  //       'effectValue': 40,
  //       'quantity': 8,
  //     },
  //     {
  //       'id': 'water_emergency',
  //       'name': 'Nước cấp cứu',
  //       'description': 'Khôi phục +50 health',
  //       'icon': '💦',
  //       'cost': 100,
  //       'effectType': 'heal',
  //       'effectValue': 50,
  //       'quantity': 5,
  //     },
  //     {
  //       'id': 'life_elixir',
  //       'name': 'Bảo Linh Công Tước ✨',
  //       'description': 'Hồi sinh cây chết',
  //       'icon': '✨',
  //       'cost': 400,
  //       'effectType': 'resurrect',
  //       'effectValue': 0,
  //       'quantity': 3,
  //     },
  //   ];
  //
  //   final batch = FirebaseFirestore.instance.batch();
  //   final shopRef = FirebaseFirestore.instance.collection('shop_items');
  //
  //   for (var item in items) {
  //     final docRef = shopRef.doc(item['id'] as String);
  //     batch.set(docRef, item);
  //   }
  //
  //   await batch.commit();
  // }
}