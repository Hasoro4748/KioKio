import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/screens/counter/pages/order_total_screen.dart';
import 'package:kiosk/screens/counter/pages/pos_screen.dart';
import 'package:kiosk/screens/counter/pages/product_manage_screen.dart';
import 'package:kiosk/screens/counter/pages/product_settlement_screen.dart';
import 'package:kiosk/screens/counter/pages/settings_screen.dart';
import 'package:kiosk/screens/counter/widgets/draggable_fab.dart';
import 'package:kiosk/screens/counter/widgets/order_detail_dialog.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/network/pos_network_status.dart';
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
      const OrderTotalScreen(),
      const ProductSettlementScreen(),
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
                        color: PageColors.cateBack,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(2, 0))
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 30), // 상단 여백 축소 (40 -> 30)
                          const Icon(Icons.storefront,
                              color: PageColors.textBlue, size: 32), // 로고 크기 축소
                          const SizedBox(height: 30),

                          // 1. 메뉴 리스트를 스크롤 가능하게 감쌉니다.
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildNavButton(
                                      0, Icons.point_of_sale, 'POS'),
                                  _buildNavButton(
                                      1, Icons.receipt_long, '주문관리'),
                                  _buildNavButton(
                                      2, Icons.analytics_outlined, '주문통계'),
                                  _buildNavButton(
                                      3, Icons.assessment_outlined, '판매정산'),
                                  _buildNavButton(
                                      4, Icons.inventory_2_outlined, '상품관리'),
                                  _buildNavButton(5, Icons.settings, '환경설정'),
                                ],
                              ),
                            ),
                          ),

                          // 2. 하단 시스템 제어 영역 (최소한의 공간만 차지하도록 수정)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: PageColors.theme.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // 추가
                              children: [
                                _buildServerControl(
                                    isBroadcasting, connectedCount),
                                const SizedBox(height: 12), // 간격 축소 (20 -> 12)
                                _buildSideIconButton(
                                  icon: Icons.home_rounded,
                                  color: PageColors.textBlue.withOpacity(0.8),
                                  tooltip: '메인화면',
                                  onTap: () {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ModelSelectionScreen()),
                                        (route) => false);
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
              onTap: (index) => setState(() => currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.point_of_sale), label: 'POS'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long), label: '주문관리'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined), label: '주문통계'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assessment_outlined), label: '판매정산'), // 추가
                BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2_outlined), label: '상품관리'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: '설정'),
              ],
            ),
    );
  }

  void _showPendingOrders(List<OrderModel> pendingOrders, Responsive rs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 투명하게 설정하여 커스텀 컨테이너 사용
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 상단 핸들바
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('결제 대기 주문',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: PageColors.textBlue)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('총 ${pendingOrders.length}건',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: pendingOrders.isEmpty
                    ? _buildEmptyPendingState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = pendingOrders[index];
                          final timeDiff = DateTime.now()
                              .difference(order.createdAt)
                              .inMinutes;

                          return _buildPendingOrderCard(order, timeDiff, rs);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPendingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('현재 대기 중인 주문이 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  // 개별 주문 카드 UI
  Widget _buildPendingOrderCard(
      OrderModel order, int minutesAgo, Responsive rs) {
    String firstItemName =
        order.items.isNotEmpty ? order.items.first.name : "상품 없음";
    int otherItemsCount = order.items.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => _openOrderDetail(order, rs), // 상세 다이얼로그 호출 헬퍼
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 왼쪽: 시간 표시 배지
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: minutesAgo > 10 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(minutesAgo.toString(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: minutesAgo > 10 ? Colors.red : Colors.blue)),
                    Text('분 전',
                        style: TextStyle(
                            fontSize: 10,
                            color: minutesAgo > 10 ? Colors.red : Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 중간: 주문 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주문번호 #${order.id}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      otherItemsCount > 0
                          ? '$firstItemName 외 $otherItemsCount건'
                          : firstItemName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormat('HH:mm:ss').format(order.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),

              // 오른쪽: 금액 및 화살표
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${TextUtil.money(order.totalPrice)}원',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: PageColors.price)),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrderDetail(OrderModel order, Responsive rs) {
    Navigator.pop(context); // 바텀시트 닫기
    showDialog(
      context: context,
      builder: (ctx) => OrderDetailDialog(
        order: order,
        rs: rs,
        onDelete: () async {
          await ref.read(orderProvider.notifier).deleteOrder(order);
          if (ctx.mounted) Navigator.pop(ctx); // ★ 다이얼로그 닫기
        },
        onCancel: () async {
          await ref.read(orderProvider.notifier).cancelOrder(order);
          if (ctx.mounted) Navigator.pop(ctx); // ★ 다이얼로그 닫기
        },
        onApprove: () async {
          await ref.read(orderProvider.notifier).approveOrder(order);
          if (ctx.mounted) Navigator.pop(ctx); // ★ 다이얼로그 닫기
        },
      ),
    );
  }

  // 메뉴 버튼 빌더
  Widget _buildNavButton(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => setState(() => currentIndex = index),
      child: Container(
        width: double.infinity,
        height: 75, // 버튼 높이 축소 (85 -> 75)
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  left: BorderSide(color: PageColors.cateSelect, width: 5))
              : null,
          color: isSelected
              ? PageColors.buttonBack.withOpacity(0.5)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? PageColors.cateSelect
                  : PageColors.textBlue.withOpacity(0.5),
              size: 24, // 아이콘 크기 축소 (28 -> 24)
            ),
            const SizedBox(height: 6), // 간격 축소 (8 -> 6)
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? PageColors.cateSelect
                    : PageColors.textBlue.withOpacity(0.6),
                fontSize: 12, // 폰트 크기 축소 (13 -> 12)
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                fontFamily: 'GmarketSans',
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
