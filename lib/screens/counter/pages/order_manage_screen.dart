import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/screens/counter/widgets/order_detail_dialog.dart';
import 'package:kiosk/screens/counter/widgets/status_color.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';

class OrderManageScreen extends ConsumerStatefulWidget {
  const OrderManageScreen({super.key});

  @override
  ConsumerState<OrderManageScreen> createState() => _OrderManageScreenState();
}

class _OrderManageScreenState extends ConsumerState<OrderManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OrderModel? _selectedOrder; // 태블릿 모드에서 선택된 주문

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final orderAsync = ref.watch(orderProvider);
    final bool useSplitView = rs.isTablet || rs.isDesktop;

    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: const Text('실시간 주문 관리',
            style: TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: PageColors.cateSelect,
          unselectedLabelColor: Colors.grey,
          indicatorColor: PageColors.cateSelect,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '처리중'),
            Tab(text: '승인됨'),
            Tab(text: '취소됨'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('에러: $error')),
        data: (orders) {
          // 탭에 따른 필터링
          final filteredOrders = _filterOrders(orders);

          if (useSplitView) {
            return Row(
              children: [
                // 왼쪽: 주문 리스트
                Expanded(
                  flex: 4,
                  child: _buildOrderList(context, filteredOrders, rs, true),
                ),
                const VerticalDivider(width: 1),
                // 오른쪽: 주문 상세
                Expanded(
                  flex: 6,
                  child: _selectedOrder == null
                      ? _buildEmptyDetailView()
                      : _buildDetailView(context, _selectedOrder!, rs),
                ),
              ],
            );
          }

          // 모바일 레이아웃
          return _buildOrderList(context, filteredOrders, rs, false);
        },
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (_tabController.index) {
      case 1:
        return orders.where((o) => o.status == '처리중').toList();
      case 2:
        return orders.where((o) => o.status == '승인').toList();
      case 3:
        return orders.where((o) => o.status == '취소').toList();
      default:
        return orders;
    }
  }

  Widget _buildOrderList(BuildContext context, List<OrderModel> orders,
      Responsive rs, bool isSplit) {
    if (orders.isEmpty) return const Center(child: Text('접수된 주문이 없습니다.'));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isSelected = _selectedOrder?.id == order.id;
        return _buildOrderCard(context, order, rs, isSplit, isSelected);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, Responsive rs,
      bool isSplit, bool isSelected) {
    return InkWell(
      onTap: () {
        if (isSplit) {
          setState(() => _selectedOrder = order);
        } else {
          _showOrderDetailDialog(context, ref, order, rs);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? PageColors.themeSelect.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? PageColors.themeSelect : Colors.transparent,
              width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 40,
                decoration: BoxDecoration(
                    color: statusColor(order.status),
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '#${order.id} | ${DateFormat('HH:mm').format(order.createdAt)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${order.items.length}개 품목',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text('${TextUtil.money(order.totalPrice)}원',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: PageColors.price)),
            ],
          ),
        ),
      ),
    );
  }

  // 상세 뷰 (태블릿 전용)
  Widget _buildDetailView(
      BuildContext context, OrderModel order, Responsive rs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('주문 상세 #${order.id}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  // 1. 주문 시각 추가 (HH:mm:ss 형식)
                  Text(
                      '주문 일시: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(order.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const Divider(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: order.items.length,
              itemBuilder: (context, i) {
                final item = order.items[i];
                return ListTile(
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${TextUtil.money(item.basePrice)}원'),
                  trailing: Text('${item.quantity}개',
                      style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ),
          const Divider(),

          // 2. 금액 상세 영역 (할인 내역 포함)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('상품 합계',
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text('${TextUtil.money(order.subTotalPrice)}원',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (order.discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('총 할인 금액',
                            style: TextStyle(
                                fontSize: 14, color: Colors.redAccent)),
                        Text('-${TextUtil.money(order.discount)}원',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('최종 결제금액',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${TextUtil.money(order.totalPrice)}원',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('주문을 선택하면 상세 내역을 볼 수 있습니다.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: statusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor(status))),
      child: Text(status,
          style: TextStyle(
              color: statusColor(status), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    // 1. 주문이 '처리중'인 경우: 승인 또는 거절(취소) 버튼 표시
    if (order.status == '처리중') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(orderProvider.notifier).cancelOrder(order),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('주문 거절/취소'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(orderProvider.notifier).approveOrder(order),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('주문 승인'),
            ),
          ),
        ],
      );
    }

    // 2. 이미 '승인'된 주문인 경우: 결제 취소(승인 취소) 버튼 표시 (추가)
    if (order.status == '승인') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmCancelApprovedOrder(order), // 컨펌 다이얼로그 호출
          icon: const Icon(Icons.undo_rounded, size: 20),
          label: const Text('승인 취소 및 결제 환불',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // 3. '취소' 상태인 경우: 아무 버튼도 표시하지 않음
    return const SizedBox();
  }

  void _confirmCancelApprovedOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('승인 취소 확인'),
        content: Text('#${order.id}번 주문의 승인을 취소하고 상태를 "취소"로 변경하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('유지하기')),
          TextButton(
            onPressed: () {
              ref.read(orderProvider.notifier).cancelOrder(order);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('주문 승인이 취소되었습니다.')));
            },
            child: const Text('승인 취소', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 모바일용 다이얼로그 호출 로직 (기존 유지)
  void _showOrderDetailDialog(
      BuildContext context, WidgetRef ref, OrderModel order, Responsive rs) {
    showDialog(
      context: context,
      builder: (ctx) => OrderDetailDialog(
        order: order,
        rs: rs,
        onDelete: () => ref.read(orderProvider.notifier).deleteOrder(order),
        onCancel: () => ref.read(orderProvider.notifier).cancelOrder(order),
        onApprove: () => ref.read(orderProvider.notifier).approveOrder(order),
      ),
    );
  }
}
