import 'package:flutter/material.dart';
import 'package:habit_tracker/models/shop_modal.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/shop_viewmodel.dart';
import '../../widgets/loading_widget.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Túi Đồ', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Consumer<ShopViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const LoadingWidget();
          }

          final user = viewModel.user;
          if (user == null) {
            return const Center(child: Text('Không thể tải dữ liệu'));
          }

          final inventory = user.inventory;
          if (inventory.isEmpty) {
            return const Center(child: Text('Túi đồ trống! Hãy mua vật phẩm từ cửa hàng.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final itemId = inventory.keys.elementAt(index);
              final quantity = inventory[itemId]!;
              final shopItem = viewModel.shopItems.firstWhere(
                    (item) => item.id == itemId,
                orElse: () => ShopItem(
                  id: itemId,
                  name: 'Unknown Item',
                  description: '',
                  icon: '❓',
                  cost: 0,
                  effectType: '',
                  effectValue: 0,
                  quantity: 0,
                ),
              );

              // Kiểm tra nếu item là thuốc, cây có bệnh tương ứng không
              bool isUsable = true;
              String? unusableReason;
              if (shopItem.effectType.startsWith('cure_')) {
                final diseaseType = shopItem.effectType.replaceFirst('cure_', '');
                if (!user.diseases.contains(diseaseType)) {
                  isUsable = false;
                  unusableReason = 'Cây không bị bệnh ${{
                    'pest': 'Sâu bệnh',
                    'drought': 'Hạn hán',
                    'fungus': 'Nấm mốc',
                  }[diseaseType] ?? diseaseType}!';
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Text(shopItem.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(shopItem.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số lượng: $quantity'),
                      if (!isUsable && unusableReason != null)
                        Text(
                          unusableReason,
                          style: TextStyle(color: Colors.red[600], fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: (quantity > 0 && isUsable)
                        ? () async {
                      final success = await viewModel.useItem(
                        itemId,
                        shopItem.effectType,
                        shopItem.effectValue,
                      );
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sử dụng ${shopItem.name}!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.errorMessage ?? 'Lỗi khi sử dụng vật phẩm'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (quantity > 0 && isUsable) ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Sử dụng'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}