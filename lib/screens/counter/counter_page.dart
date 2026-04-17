import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:path_provider/path_provider.dart';

class CounterHomeScreen extends StatefulWidget {
  const CounterHomeScreen({super.key});

  @override
  State<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends State<CounterHomeScreen> {
  List<Order> orders = [];
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/files/orders.json');

    //파일이 없다면
    if (!await file.exists()) {
      setState(() => orders = []);
      print("주문없음");
      return;
    }

    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);

    setState(() {
      orders = jsonList.map((e) => Order.fromJson(e)).toList();
    });
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ModelSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _statusDone(Order order) async {
    try {
      setState(() {
        order.status = '승인';
      });
      await _saveOrders();
    } catch (e) {
      print('저장 실패 : $e');
    }
  }

  Future<void> _statusCancel(Order order) async {
    try {
      setState(() {
        order.status = '취소';
      });
      await _saveOrders();
    } catch (e) {
      print('저장 실패 : $e');
    }
  }

  Future<void> _statusDelete(Order order) async {
    try {
      setState(() {
        orders.removeWhere((o) => o.id == order.id);
      });

      await _saveOrders();
    } catch (e) {
      print('삭제 실패: $e');
    }
  }

  Future<void> _saveOrders() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/files/orders.json');

    final jsonList = orders.map((e) => e.toJson()).toList();

    await file.writeAsString(jsonEncode(jsonList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Color(0xFF1E1E1E),
              ),
              color: Color(0xFF1E1E1E),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          final now = DateTime.now();

                          if (_lastTapTime == null ||
                              now.difference(_lastTapTime!) >
                                  Duration(seconds: 1)) {
                            // 👉 1초 지나면 초기화
                            _tapCount = 1;
                          } else {
                            _tapCount++;
                          }

                          _lastTapTime = now;

                          if (_tapCount == 3) {
                            _goHome();
                            _tapCount = 0;
                          }
                        },
                        child: Image.asset('assets/img/logo/logo1.png'),
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Color(0xFFF5F5F5),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Color(0xFFD7D9CF),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "상품관리",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF181411),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 5,
                          height: 75,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.settings),
                          iconSize: 80,
                          color: Color(0xFF181411),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Color(0xFF3A3A3A),
                      ),
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderCard(order);
                            }),
                      )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      color: _statusBackgroundColor(order.status),
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('주문번호: ${order.id}'),
        subtitle: Text(
          '${order.items.length}개 상품 / ${TextUtil.money(order.totalPrice)}원',
        ),
        trailing: Text(
          order.status,
          style: TextStyle(
            color: _statusColor(order.status),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        onTap: () => _showOrderDetailDialog(order),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case '처리중':
        //처리중
        return Colors.orange;
      case '승인':
        //완료
        return Colors.green;
      case '취소':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status) {
      case '처리중':
        //처리중
        return Colors.orange.shade50;
      case '승인':
        //완료
        return Colors.green.shade50;
      case '취소':
        return Colors.red.shade50;
      default:
        return Colors.white;
    }
  }

  void _showOrderDetailDialog(Order order) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: 800,
                height: 550,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: order.status == '처리중'
                            ? Colors.orange.shade50
                            : order.status == '승인'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20)),
                      ),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '주문번호: ${order.id}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '시간: ${DateFormat('yyyy년 MM월 dd일 - a hh시 mm분 ss초').format(order.createdAt)}',
                                ),
                                const SizedBox(height: 16),
                                Text('─────────────'),
                                Row(
                                  children: [
                                    Text(
                                      '상태 : ',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      order.status,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: order.status == '처리중'
                                            ? Colors.orange
                                            : order.status == '승인'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  TextButton(
                                      onPressed: () async {
                                        await _statusDelete(order);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text(
                                        "주문삭제",
                                        style: TextStyle(color: Colors.red),
                                      )),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                        backgroundColor: Colors.grey.shade300),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                /// 상품명
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.optPrice != 0
                                        ? '${item.optionText} \n(+ ${item.optPrice}'
                                        : item.optionText,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),

                                /// 가격
                                Expanded(
                                  child: Text(
                                    '${TextUtil.money(item.unitPrice)}원',
                                    textAlign: TextAlign.end,
                                  ),
                                ),

                                /// 수량
                                Expanded(
                                  child: Text(
                                    '${item.quantity}개',
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                /// 합계
                                Expanded(
                                  child: Text(
                                    '${TextUtil.money(item.totalPrice)}원',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    /// 🔥 하단 (총 금액 + 버튼)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          /// 총 금액
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '총 금액',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${TextUtil.money(order.totalPrice)}원',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// 버튼
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: order.status == '처리중' ||
                                          order.status == '승인'
                                      ? () {
                                          setState(() {
                                            _statusCancel(order);
                                          });
                                          Navigator.pop(dialogContext);
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                  ),
                                  child: const Text('주문 취소'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: order.status == '처리중'
                                      ? () {
                                          setState(() {
                                            _statusDone(order);
                                          });
                                          Navigator.pop(dialogContext);
                                        }
                                      : null,
                                  child: const Text('주문 승인'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}
