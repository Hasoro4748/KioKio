import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk/models/order.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/screens/customer/cart.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kiosk/utils/text_util.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<Product> products = []; //  상품 리스트
  List<OrderItem> cart = []; //  장바구니 목록

  String? selectedCate2; // 장르
  String? selectedCate3; // 종류
  int _tapCount = 0;
  DateTime? _lastTapTime;
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/files/products.json');

    if (!await file.exists()) {
      final folder = Directory(file.parent.path);

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // 🔥 없으면 assets에서 복사 추후 수정 ‼️‼️‼️‼️
      final jsonString =
          await rootBundle.loadString('assets/files/products.json');

      await file.writeAsString(jsonString);
    }

    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);

    setState(() {
      products = jsonList.map((e) => Product.fromJson(e)).toList();
    });
  }

  List<String> get category2 {
    final set = products.map((e) => e.category2).toSet().toList();
    set.sort();
    return set;
  }

  List<String> get category3 {
    final set = products.map((e) => e.category3).toSet().toList();
    set.sort();
    return set;
  }

  List<Product> get filteredProducts {
    return products.where((p) {
      final Cate2Ok = (selectedCate2 == null) || p.category2 == selectedCate2;
      final Cate3Ok = (selectedCate3 == null) || p.category3 == selectedCate3;
      return Cate2Ok && Cate3Ok;
    }).toList();
  }

  void _addToCart(Product product, List<SelectedOption> selectedOptions) {
    setState(() {
      cart.add(OrderItem(
          productId: product.id,
          basePrice: product.basePrice,
          name: product.name,
          selectedOptions: selectedOptions,
          quantity: 1));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} 상품을 장바구니에 담았습니다.')),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ModelSelectionScreen()),
      (route) => false,
    );
  }

  int _totalValue() {
    return cart.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  int _totalPrice() {
    return cart.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  void checkout() async {
    final order = Order(
      id: generateOrderNumber(),
      items: List.from(cart),
      createdAt: DateTime.now(),
    );

    await saveOrder(order);

    setState(() {
      cart.clear();
    });
  }

  String generateOrderNumber() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}/'
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> saveOrder(Order order) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/files/orders.json');

    List orders = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      orders = jsonDecode(content);
    }
    orders.add(order.toJson());

    await file.writeAsString(jsonEncode(orders));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF181411),
              border: Border.all(width: 0),
            ),
            child: Column(
              children: [
                Padding(
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
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFD7D9CF),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 32),
                                  _buildCategoryChip(
                                    color1: Color(0xFF181411),
                                    color2: Color(0xFFD80C06),
                                    label: '전체',
                                    fSize: 20,
                                    selected: selectedCate2 == null,
                                    onTap: () {
                                      setState(() => selectedCate2 = null);
                                    },
                                  ),
                                  ...category2.map((t) => _buildCategoryChip(
                                      color1: Color(0xFF181411),
                                      color2: Color(0xFFD80C06),
                                      fSize: 20,
                                      label: t,
                                      selected: selectedCate2 == t,
                                      onTap: () {
                                        setState(() => selectedCate2 = t);
                                      })),
                                  const SizedBox(width: 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Color(0xFF343129)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 32),
                                  _buildCategoryChip(
                                    color1: Color(0xFFEDE1CB),
                                    color2: Color(0xFFEDE1CB),
                                    label: '전체',
                                    selected: selectedCate3 == null,
                                    fSize: 16,
                                    onTap: () {
                                      setState(() => selectedCate3 = null);
                                    },
                                  ),
                                  ...category3.map((t) => _buildCategoryChip(
                                      color1: Color(0xFFEDE1CB),
                                      color2: Color(0xFFEDE1CB),
                                      fSize: 16,
                                      label: t,
                                      selected: selectedCate3 == t,
                                      onTap: () {
                                        setState(() => selectedCate3 = t);
                                      })),
                                  const SizedBox(width: 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: Color(0xFFFAF8F1),
                          child: GridView.builder(
                            padding: EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cart.isNotEmpty ? 3 : 5,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
                        ),
                      ),
                      if (cart.isNotEmpty)
                        Container(
                          width: 400,
                          color: Colors.white,
                          child: _buildCartPanel(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap:
          product.isAvailable ? () => _showProductDetailDialog(product) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage(product.images[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text('${TextUtil.money(product.basePrice)}원',
                      style: TextStyle(fontSize: 16, color: Colors.orange)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required Color color1,
    required Color color2,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required double fSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fSize,
                  color: selected ? color2 : color1,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                color: selected ? color2 : Colors.transparent,
              ),
            ),
            Positioned(
              bottom: -8, // 👈 border 아래로 살짝 빼기
              left: 0,
              right: 0,
              child: Center(
                child: CustomPaint(
                  size: Size(20, 10),
                  painter: TrianglePainter(
                      color: selected ? color2 : Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Spacer(),
            const Text(
              '장바구니',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  cart.clear();
                });
              },
              icon: const Icon(
                Icons.delete_rounded,
                color: Colors.black,
              ),
              iconSize: 30,
            )
          ],
        ),
        const Divider(),

        /// 리스트
        Expanded(
          child: ListView.builder(
            itemCount: cart.length,
            itemBuilder: (context, index) {
              final item = cart[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 145,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.selectedOptions.isNotEmpty)
                            Text(
                              item.optionText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () {
                              setState(
                                () {
                                  item.quantity--;
                                },
                              );
                            }
                          : () {
                              setState(
                                () {
                                  cart.remove(item);
                                },
                              );
                            },
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Container(width: 35, child: Text('${item.quantity}개')),
                    IconButton(
                      onPressed: item.quantity > 0 //max 로 변경 필요
                          ? () {
                              setState(
                                () {
                                  item.quantity++;
                                },
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add_circle),
                    ),
                    const Spacer(),
                    Text('${TextUtil.money(item.totalPrice)}원'),
                  ],
                ),
              );
            },
          ),
        ),

        /// 총 금액
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Text(
                    '전체: ${_totalValue()}개',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 32),
                  Text(
                    '총 금액: ${TextUtil.money(_totalPrice())}원',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    checkout();
                    print("완료됨");
                  });
                },
                child: const Text('결제하기'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        )
      ],
    );
  }

  void _showProductDetailDialog(Product product) {
    int quantity = 1;

    Map<String, OptionItem> selectedOptions = {};
    //옵션 초기값
    for (var option in product.options) {
      if (option.items.isNotEmpty) {
        selectedOptions[option.name] = option.items.first;
      }
    }
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
                    Expanded(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(width: 1, color: Colors.grey)),
                              width: 500,
                              height: 500,
                              child: ClipRRect(
                                child: Image.asset(
                                  product.images[0],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Spacer(),
                                    IconButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        icon:
                                            const Icon(Icons.cancel_outlined)),
                                  ],
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '가격: ${TextUtil.money(product.basePrice)}원',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('장르 : ${product.category2}'),
                                          Text('종류 : ${product.category3}'),
                                          const SizedBox(height: 20),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                product.options.map((option) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    option.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Column(
                                                    children: option.items
                                                        .map((item) {
                                                      final isSelected =
                                                          selectedOptions[option
                                                                      .name]
                                                                  ?.name ==
                                                              item.name;
                                                      return RadioListTile<
                                                          String>(
                                                        value: item.name,
                                                        groupValue:
                                                            selectedOptions[
                                                                    option.name]
                                                                ?.name,
                                                        onChanged: (value) {
                                                          setStateDialog(() {
                                                            selectedOptions[
                                                                    option
                                                                        .name] =
                                                                item;
                                                          });
                                                        },
                                                        title: Text(
                                                            '${item.name} (+${TextUtil.money(item.price)}원'),
                                                      );
                                                    }).toList(),
                                                  )
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                          const Text(
                                            '수량',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: quantity > 1
                                                    ? () {
                                                        setStateDialog(() {
                                                          quantity--;
                                                        });
                                                      }
                                                    : null,
                                                icon: const Icon(
                                                    Icons.remove_circle),
                                              ),
                                              Text(
                                                '$quantity',
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    quantity > 0 //max 로 변경 필요
                                                        ? () {
                                                            setStateDialog(() {
                                                              quantity++;
                                                            });
                                                          }
                                                        : null,
                                                icon: const Icon(
                                                    Icons.add_circle),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final selectedOptionList =
                                            selectedOptions.entries.map((e) {
                                          return SelectedOption(
                                            optionName: e.key,
                                            itemName: e.value.name,
                                            price: e.value.price,
                                          );
                                        }).toList();

                                        setState(
                                          () {
                                            cart.add(OrderItem(
                                                productId: product.id,
                                                name: product.name,
                                                basePrice: product.basePrice,
                                                selectedOptions:
                                                    selectedOptionList,
                                                quantity: quantity));
                                          },
                                        );
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            '${product.name} $quantity개를 장바구니에 담았습니다.',
                                          ),
                                        ));
                                      },
                                      child: const Text('장바구니 담기'),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  void _goToCart(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => CartScreen(cart: cart)));
  }
}

class TrianglePainter extends CustomPainter {
  final Color color; // 👈 색상 변수

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color // border 색이랑 맞추기
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, 0 - size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
