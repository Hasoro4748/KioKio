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

    final pages = [
      const PosScreen(),
      const OrderManageScreen(),
      const OrderHistoryScreen(),
      const ProductManageScreen(),
      const SettingsScreen(),
    ];

    final isPendingLoading = orderAsync.isLoading;
    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 100,
                  color: PageColors.cateBack,
                  child: Column(
                    children: [
                      Expanded(
                        child: NavigationRail(
                          backgroundColor: Colors.transparent,
                          selectedIndex: currentIndex,
                          onDestinationSelected: (index) {
                            setState(() {
                              currentIndex = index;
                            });
                          },
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.point_of_sale),
                              label: Text('POS'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.receipt_long),
                              label: Text('주문관리'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.history),
                              label: Text('주문기록'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.inventory_2_outlined),
                              label: Text('상품관리'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings),
                              label: Text('환경설정'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                ref
                                    .read(posNetworkServiceProvider.notifier)
                                    .startBroadcast();
                              },
                              icon: Icon(
                                isBroadcasting
                                    ? Icons.sensors
                                    : Icons.sensors_off,
                                color: isBroadcasting
                                    ? (connectedCount > 0
                                        ? Colors.blueAccent
                                        : Colors.greenAccent)
                                    : Colors.white,
                                size: 36,
                              ),
                              tooltip: '서버 시작',
                            ),
                            if (connectedCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    '$connectedCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: IconButton(
                          onPressed: () {
                            ref
                                .read(posNetworkServiceProvider.notifier)
                                .stopBroadcast();
                          },
                          icon: Icon(
                            Icons.stop_circle_outlined,
                            color: isBroadcasting
                                ? Colors.redAccent
                                : Colors.white54,
                            size: 36,
                          ),
                          tooltip: '서버 중지',
                        ),
                      ),

                      /// 메인화면 버튼
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ModelSelectionScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                          tooltip: '메인화면',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: pages[currentIndex],
                ),
              ],
            )
          : pages[currentIndex],

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPendingOrders(
          pendingOrders,
          rs,
        ),
        backgroundColor: pendingOrders.isEmpty || isPendingLoading
            ? PageColors.themeSelect
            : Colors.orange,
        icon: const Icon(Icons.notifications_active),
        label: isPendingLoading
            ? const CircularProgressIndicator()
            : Text(
                '${pendingOrders.length} 건',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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
                                              .deleteOrder(order.id!);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onCancel: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .cancelOrder(order.id!);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onApprove: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .approveOrder(order.id!);

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
}
