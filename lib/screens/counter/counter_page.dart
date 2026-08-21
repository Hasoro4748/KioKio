import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/screens/counter/pages/order_history_screen.dart';
import 'package:kiosk/screens/counter/pages/pos_screen.dart';
import 'package:kiosk/screens/counter/pages/product_manage_screen.dart';
import 'package:kiosk/screens/counter/pages/settings_screen.dart';
import 'package:kiosk/screens/counter/widgets/draggable_fab.dart';
import 'package:kiosk/screens/counter/widgets/order_detail_dialog.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/pos_network_service.dart';
import 'package:kiosk/utils/pos_network_status.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

import 'pages/order_manage_screen.dart';

class CounterMainScreen extends ConsumerStatefulWidget {
  const CounterMainScreen({super.key});

  @override
  ConsumerState<CounterMainScreen> createState() => _CounterMainScreenState();
}

class _CounterMainScreenState extends ConsumerState<CounterMainScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final orderAsync = ref.watch(orderProvider);
    final networkState = ref.watch(posNetworkServiceProvider);
    final isBroadcasting =
        networkState.status == PosBroadcastStatus.broadcasting;
    final connectedCount = networkState.connectedKiosks;

    final pendingOrders = orderAsync.when(
      data: (orders) {
        final list = orders.where((e) => e.status == '처리중').toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return list;
      },
      loading: () => <OrderModel>[],
      error: (_, __) => <OrderModel>[],
    );

    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 900;

    final isPendingLoading = orderAsync.isLoading;

    final pages = [
      const PosScreen(),
      const OrderManageScreen(),
      const OrderHistoryScreen(),
      const ProductManageScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('POS 모드'),
              backgroundColor: PageColors.themeUnSelect,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () => _showPendingOrders(pendingOrders, rs),
                    icon: Badge(
                      label: Text('${pendingOrders.length}'),
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.notifications_active,
                          color: pendingOrders.isEmpty
                              ? PageColors.textBlue
                              : DefaultColors.yellow),
                    ),
                  ),
                ),
                // 1. 서버 시작/중지 토글 버튼 추가
                IconButton(
                  onPressed: () {
                    if (isBroadcasting) {
                      ref
                          .read(posNetworkServiceProvider.notifier)
                          .stopBroadcast();
                    } else {
                      ref
                          .read(posNetworkServiceProvider.notifier)
                          .startBroadcast();
                    }
                  },
                  icon: Icon(
                    isBroadcasting ? Icons.sensors : Icons.sensors_off,
                    color: isBroadcasting
                        ? (connectedCount > 0
                            ? Colors.blueAccent
                            : Colors.greenAccent)
                        : Colors.white54,
                  ),
                  tooltip: isBroadcasting ? '서버 중지' : '서버 시작',
                ),

                // 2. 연결된 키오스크 숫자 표시 (배지 형태)
                if (connectedCount > 0)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$connectedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 3. 메인화면으로 돌아가기 버튼 (모바일에서도 필요할 경우)
                IconButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ModelSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                ),
              ],
            ),
      body: Stack(
        children: [
          isDesktop
              ? Row(
                  children: [
                    // --- 커스텀 사이드바 시작 ---
                    Container(
                      width: 110,
                      decoration: BoxDecoration(
                        // PageColors.cateBack을 배경으로 사용하여 전체 테마와 통일감 부여
                        color: PageColors.cateBack,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          // 로고 아이콘 색상을 테마의 짙은 남색으로 변경
                          const Icon(Icons.storefront,
                              color: PageColors.textBlue, size: 36),
                          const SizedBox(height: 40),

                          // 메뉴 리스트
                          Expanded(
                            child: Column(
                              children: [
                                _buildNavButton(0, Icons.point_of_sale, 'POS'),
                                _buildNavButton(1, Icons.receipt_long, '주문관리'),
                                _buildNavButton(2, Icons.history, '주문기록'),
                                _buildNavButton(
                                    3, Icons.inventory_2_outlined, '상품관리'),
                                _buildNavButton(4, Icons.settings, '환경설정'),
                              ],
                            ),
                          ),

                          // 하단 시스템 제어 영역
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              // 하단 영역을 살짝 더 어두운 톤으로 구분
                              color: PageColors.theme.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            child: Column(
                              children: [
                                _buildServerControl(
                                    isBroadcasting, connectedCount),
                                const SizedBox(height: 20),
                                _buildSideIconButton(
                                  icon: Icons.home_rounded,
                                  // 기본 텍스트 블루 색상 활용
                                  color: PageColors.textBlue.withOpacity(0.8),
                                  tooltip: '메인화면',
                                  onTap: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ModelSelectionScreen()),
                                      (route) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- 커스텀 사이드바 끝 ---

                    Expanded(
                      child: Container(
                        // 메인 배경을 테마의 가장 밝은 색상으로 설정
                        color: const Color(0xFFFCFDFF),
                        child: pages[currentIndex],
                      ),
                    ),
                  ],
                )
              : pages[currentIndex],
          if (isDesktop)
            DraggableFab(
              initialPosition: Offset(MediaQuery.of(context).size.width - 120,
                  MediaQuery.of(context).size.height - 150),
              child: FloatingActionButton.extended(
                onPressed: () => _showPendingOrders(pendingOrders, rs),
                backgroundColor: pendingOrders.isEmpty || isPendingLoading
                    ? PageColors.themeSelect
                    : Colors.orange,
                icon: const Icon(Icons.notifications_active),
                label: isPendingLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        '${pendingOrders.length} 건',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
        ],
      ),

      //모바일 환경
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale),
                  label: 'POS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: '주문관리',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: '주문기록',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: '상품관리',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '환경설정',
                ),
              ],
            ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showPendingOrders(
      //     pendingOrders,
      //     rs,
      //   ),
      //   backgroundColor: pendingOrders.isEmpty || isPendingLoading
      //       ? PageColors.themeSelect
      //       : Colors.orange,
      //   icon: const Icon(Icons.notifications_active),
      //   label: isPendingLoading
      //       ? const CircularProgressIndicator()
      //       : Text(
      //           '${pendingOrders.length} 건',
      //           style: const TextStyle(
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      // ),
    );
  }

  void _showPendingOrders(
    List<OrderModel> pendingOrders,
    Responsive rs,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 16),

                /// 핸들바
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '결제 대기 주문',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: pendingOrders.isEmpty
                      ? const Center(
                          child: Text(
                            '대기 중인 주문이 없습니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: pendingOrders.length,
                          itemBuilder: (context, index) {
                            final order = pendingOrders[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),

                                /// 주문번호
                                title: Text(
                                  '주문번호 : ${DateFormat('MMdd -').format(order.createdAt)} ${order.id.toString()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                /// 상품 정보
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${order.items.length}개 상품',
                                  ),
                                ),

                                /// 금액
                                trailing: Text(
                                  '${TextUtil.money(order.totalPrice)}원',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                /// 주문 상세 열기
                                onTap: () {
                                  Navigator.pop(context);

                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return OrderDetailDialog(
                                        order: order,
                                        rs: rs,
                                        onDelete: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .deleteOrder(order);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onCancel: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .cancelOrder(order);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onApprove: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .approveOrder(order);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 메뉴 버튼 빌더
  Widget _buildNavButton(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => setState(() => currentIndex = index),
      child: Container(
        width: double.infinity,
        height: 85,
        decoration: BoxDecoration(
          // 선택 시 왼쪽 바를 짙은 남색(cateSelect)으로 표시
          border: isSelected
              ? const Border(
                  left: BorderSide(color: PageColors.cateSelect, width: 5))
              : null,
          // 선택 시 배경을 아주 연한 블루(buttonBack)로 변경
          color: isSelected
              ? PageColors.buttonBack.withOpacity(0.5)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              // 선택 시 짙은 남색, 비선택 시 부드러운 회색빛 블루
              color: isSelected
                  ? PageColors.cateSelect
                  : PageColors.textBlue.withOpacity(0.5),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? PageColors.cateSelect
                    : PageColors.textBlue.withOpacity(0.6),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                fontFamily: 'GmarketSans', // 테마 폰트 적용
              ),
            ),
          ],
        ),
      ),
    );
  }

// 서버 제어 버튼
  Widget _buildServerControl(bool isBroadcasting, int connectedCount) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (isBroadcasting) {
              ref.read(posNetworkServiceProvider.notifier).stopBroadcast();
            } else {
              ref.read(posNetworkServiceProvider.notifier).startBroadcast();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isBroadcasting)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 가동 중일 때 테마의 밝은 남색 활용
                    color: PageColors.themeSelect.withOpacity(0.2),
                  ),
                ),
              Icon(
                isBroadcasting ? Icons.sensors : Icons.sensors_off,
                size: 32,
                color: isBroadcasting
                    ? (connectedCount > 0
                        ? Colors.blueAccent
                        : DefaultColors.green)
                    : PageColors.textBlue.withOpacity(0.3),
              ),
              if (connectedCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: DefaultColors.red, shape: BoxShape.circle),
                    child: Text(
                      '$connectedCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isBroadcasting ? 'ON AIR' : 'OFFLINE',
          style: TextStyle(
            color: isBroadcasting
                ? PageColors.cateSelect
                : PageColors.textBlue.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        )
      ],
    );
  }

// 일반 아이콘 버튼 빌더
  Widget _buildSideIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 28),
      tooltip: tooltip,
    );
  }
}
