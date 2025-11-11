import 'package:flutter/material.dart';
import 'package:habit_tracker/models/shop_modal.dart';
import 'package:habit_tracker/models/user_model.dart';
import 'package:habit_tracker/models/weather_data.dart';
import 'package:habit_tracker/services/tree_health_service.dart';
import 'package:habit_tracker/services/weather_service.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/checkin_viewmodel.dart';
import '../../viewmodels/habit_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/shop_viewmodel.dart';
import 'widgets/habit_card.dart';
import 'widgets/tree_widget.dart';
import 'widgets/stats_overview.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weatherData;
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitViewModel>().loadHabits();
      context.read<ProfileViewModel>().loadProfile();
      context.read<CheckinViewModel>().getTotalCheckinsCount();
      context.read<ShopViewModel>().loadShopItems();
      _updateTreeHealth();
      _loadWeather();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ShopViewModel>(context, listen: false).loadUserData();
      });
    });
  }
  Future<void> _loadWeather() async {
    try {
      final weather = await WeatherService().fetchWeather();
      setState(() => _weatherData = weather);
      print('🌤️ Thời tiết hiện tại: ${weather.condition}');
    } catch (e) {

      print('❌ Lỗi khi lấy dữ liệu thời tiết: $e');
    }
  }
  Future<void> _updateTreeHealth() async {
    final profileVM = context.read<ProfileViewModel>();
    final treeHealthService = TreeHealthService();
    final user = profileVM.userProfile;
    if (user != null) {
      try {
        final updatedUser = await treeHealthService.checkAndUpdateTreeHealth(user);
        await profileVM.updateProfile(updatedUser); // Cập nhật profile để phản ánh bệnh mới
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật sức khỏe cây: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Hàm xử lý khi chọn tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      // Điều hướng đến ReadingChallengeScreen
      Navigator.pushNamed(
        context,
        '/reading-challenge',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thói Quen Của Tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Stack(
        children: [
          // FloatingActionButton cho cửa hàng
          Positioned(
            bottom: 16,
            right: 0,
            child: Consumer<ProfileViewModel>(
              builder: (context, profileVM, child) {
                final user = profileVM.userProfile;
                final bool needsAttention = user != null &&
                    (user.treeHealth < 60 || user.isTreeDead || user.diseases.isNotEmpty);
                return FloatingActionButton.extended(
                  heroTag: 'shop_fab', // Thêm heroTag duy nhất
                  onPressed: () {
                    Navigator.pushNamed(context, '/shop', arguments: needsAttention ? 'medicine' : null);
                  },
                  backgroundColor: needsAttention ? const Color(0xD0FF0000) : const Color(
                      0xA54CAF50),
                  icon: Image.asset(
                    "assets/images/shop.png",
                    width: 40,
                    height: 24,
                  ),
                  label: Text(
                    needsAttention ? 'Cứu Cây!' : 'Cửa Hàng',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  tooltip: 'Mua vật phẩm để chăm sóc cây',
                );
              },
            ),
          ),
          // FloatingActionButton cho đọc sách
          Positioned(
            bottom: 80,
            right:0,
            child: FloatingActionButton.extended(
              heroTag: 'reading_fab', // Thêm heroTag duy nhất
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/reading-challenge',
                );
              },
              backgroundColor: Color(0x770080FF),
              icon:  Icon(Icons.book),

              tooltip: 'Thử thách đọc sách',
              label: Text("Thử thách đọc sách",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // FloatingActionButton cho Cổng Tương Lai
          Positioned(
            bottom: 160, // Dịch lên thêm để tránh chồng lấn
            right: 0,
            child: FloatingActionButton.extended(
              heroTag: 'future_portal_fab',
              onPressed: () {
                final now = DateTime.now();
                if (now.weekday == DateTime.sunday && now.hour >= 12) {
                  Navigator.pushNamed(
                    context,
                    '/future-portal', // Đảm bảo route này được định nghĩa
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cổng Tương Lai chỉ mở vào chiều Chủ Nhật!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              backgroundColor: const Color(0x9D4CAF50), // Màu xanh lá để phân biệt
              icon: const Icon(Icons.star), // Icon phù hợp với "Tương Lai"
              tooltip: 'Cổng Tương Lai',
              label: const Text(
                'Cổng Tương Lai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HabitViewModel>().loadHabits();
          await context.read<ProfileViewModel>().loadProfile();
          await context.read<CheckinViewModel>().getTotalCheckinsCount();
          await context.read<ShopViewModel>().loadShopItems();
          await _updateTreeHealth();
        },
        color: Colors.green[600],
        child: Consumer3<HabitViewModel, ProfileViewModel, ShopViewModel>(
          builder: (context, habitVM, profileVM, shopVM, child) {
            if (habitVM.isLoading && habitVM.habits.isEmpty) {
              return const LoadingWidget();
            }

            final user = profileVM.userProfile;

            return CustomScrollView(
              slivers: [
                // Tree Widget Header with Disease Info
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      TreeWidget(
                        userProfile: user,
                        isLoading: profileVM.isLoading,
                        weatherData: _weatherData,
                      ),
                      if (user != null && (user.diseases.isNotEmpty || user.isTreeDead))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildTreeHealthWarning(context, user, shopVM),
                        ),
                    ],
                  ),
                ),

                // Stats Overview
                SliverToBoxAdapter(
                  child: StatsOverview(
                    totalPoints: user?.totalPoints ?? 0,
                    currentStreak: user?.currentStreak ?? 0,
                    totalHabits: habitVM.activeHabitsCount,
                    checkedInToday: habitVM.totalCheckinsCount,
                    treeHealth: user?.treeHealth ?? 100,
                    diseases: user?.diseases ?? [],
                    inventory: user?.inventory ?? {},
                    shopItems: shopVM.shopItems,
                    onUseItem: (itemId, effectType, effectValue) async {
                      final success = await shopVM.useItem(itemId, effectType, effectValue);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sử dụng vật phẩm thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await profileVM.loadProfile();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(shopVM.errorMessage ?? 'Lỗi khi sử dụng vật phẩm'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thói quen hôm nay',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (habitVM.habits.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${habitVM.habits.length} thói quen',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Habits List
                if (habitVM.habits.isEmpty)
                  SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.eco_outlined,
                      title: 'Chưa có thói quen nào',
                      message: 'Tạo thói quen đầu tiên của bạn!',
                      actionText: 'Tạo thói quen',
                      onActionPressed: () {
                        Navigator.pushNamed(context, '/add-habit');
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final habit = habitVM.habits[index];
                          final isCheckedIn = habitVM.isCheckedInToday(habit.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HabitCard(
                              habit: habit,
                              isCheckedIn: isCheckedIn,
                              onCheckIn: () async {
                                final success = await habitVM.checkInHabit(habit.id);
                                if (success && mounted) {
                                  try {
                                    await profileVM.loadProfile();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text('${habit.title} đã hoàn thành! +10 coins'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green[600],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: $e'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else if (habitVM.errorMessage != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(habitVM.errorMessage!),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/habit-detail',
                                  arguments: habit.id,
                                );
                              },
                            ),
                          );
                        },
                        childCount: habitVM.habits.length,
                      ),
                    ),
                  ),

                // Bottom spacing for nav bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTreeHealthWarning(BuildContext context, UserModel user, ShopViewModel shopVM) {
    final diseaseMessages = user.diseases.map((disease) {
      final item = shopVM.shopItems.firstWhere(
            (item) => item.effectType == 'cure_$disease',
        orElse: () => ShopItem(
          id: '',
          name: 'Thuốc',
          description: '',
          icon: '🧪',
          cost: 0,
          effectType: '',
          effectValue: 0,
          quantity: 0,
        ),
      );
      final ownedQuantity = user.inventory[item.id] ?? 0;
      final diseaseEmoji = {
        'pest': '🐛 Sâu bệnh',
        'drought': '🏜️ Hạn hán',
        'fungus': '🍄 Nấm mốc',
      }[disease] ?? '🦠 Bệnh';
      return {
        'message': 'Cây bị $diseaseEmoji!',
        'item': item,
        'ownedQuantity': ownedQuantity,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.treeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.getTreeStatusMessage(),
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...diseaseMessages.map((disease) {
            final item = disease['item'] as ShopItem;
            final ownedQuantity = disease['ownedQuantity'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      disease['message'] as String,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                  if (ownedQuantity > 0)
                    ElevatedButton(
                      onPressed: () async {
                        final success = await shopVM.useItem(
                          item.id,
                          item.effectType,
                          item.effectValue,
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sử dụng ${item.name}!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await context.read<ProfileViewModel>().loadProfile();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(shopVM.errorMessage ?? 'Lỗi khi sử dụng vật phẩm'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Sử dụng ${item.name} ($ownedQuantity)'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/shop', arguments: 'medicine');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Mua Thuốc'),
                    ),
                ],
              ),
            );
          }),
          if (user.isTreeDead)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Cây đã chết! 💀',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/shop', arguments: 'special');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Mua Elixir'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}