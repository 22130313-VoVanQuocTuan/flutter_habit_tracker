import 'package:flutter/material.dart';
import 'package:habit_tracker/models/shop_modal.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/shop_viewmodel.dart';
import '../../widgets/loading_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'medicine';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopViewModel>().loadUserData();
      context.read<ShopViewModel>().loadShopItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.backpack, size: 40, color: Colors.amber,),

            onPressed: () {
              Navigator.pushNamed(context, '/inventory');
            },
            tooltip: 'Xem túi đồ',
          ),
        ],
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

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Coins của bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.totalCoins}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryTab('medicine', '💊 Thuốc'),
                        const SizedBox(width: 12),
                        _buildCategoryTab('fertilizer', '🌾 Phân bón'),
                        const SizedBox(width: 12),
                        _buildCategoryTab('special', '✨ Đặc biệt'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: viewModel.getItemsByCategory(_selectedCategory).length,
                    itemBuilder: (context, index) {
                      final items = viewModel.getItemsByCategory(_selectedCategory);
                      final item = items[index];
                      final canAfford = user.totalPoints >= item.cost;
                      final inStock = item.quantity > 0;
                      final ownedQuantity = user.inventory[item.id] ?? 0;

                      return _buildItemCard(context, item, canAfford, inStock, ownedQuantity, viewModel);
                    },
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(String category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context,
      ShopItem item,
      bool canAfford,
      bool inStock,
      int ownedQuantity,
      ShopViewModel viewModel,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  item.icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Text(
              item.description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.cost} Coins',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Text(
                  inStock ? 'Còn: ${item.quantity}' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 12,
                    color: inStock ? Colors.grey[600] : Colors.red,
                  ),
                ),
              ],
            ),
            Text(
              'Sở hữu: $ownedQuantity',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (canAfford && inStock)
                    ? () async {
                  final success = await viewModel.buyItem(item);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã mua ${item.name} thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(viewModel.errorMessage ?? 'Lỗi khi mua vật phẩm'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (canAfford && inStock) ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  inStock ? 'Mua' : 'Hết hàng',
                  style: TextStyle(
                    color: (canAfford && inStock) ? Colors.white : Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}