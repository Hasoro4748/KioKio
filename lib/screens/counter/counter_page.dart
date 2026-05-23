import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/order.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/screens/counter/pages/order_history_screen.dart';
import 'package:kiosk/screens/counter/pages/pos_screen.dart';
import 'package:kiosk/screens/counter/pages/product_manage_screen.dart';
import 'package:kiosk/screens/counter/pages/settings_screen.dart';
import 'package:kiosk/screens/counter/widgets/order_detail_dialog.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:path_provider/path_provider.dart';

import 'pages/order_manage_screen.dart';

class CounterMainScreen extends ConsumerStatefulWidget {
  const CounterMainScreen({super.key});

  @override
  ConsumerState<CounterMainScreen> createState() => _CounterMainScreenState();
}

class _CounterMainScreenState extends ConsumerState<CounterMainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const PosScreen(),
    const OrderManageScreen(),
    const OrderHistoryScreen(),
    const ProductManageScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final orders = ref.watch(orderProvider);
    final pendingOrders = orders.where((o) => o.status == '처리중').toList();

    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 900;

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
        backgroundColor:
            pendingOrders.isEmpty ? PageColors.themeSelect : Colors.orange,
        icon: const Icon(Icons.notifications_active),
        label: Text(
          '${pendingOrders.length} 건',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPendingOrders(
    List<Order> pendingOrders,
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
                                  order.id,
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
                                              .deleteOrder(order.id);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onCancel: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .cancelOrder(order.id);

                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                        onApprove: () async {
                                          await ref
                                              .read(orderProvider.notifier)
                                              .approveOrder(order.id);

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
