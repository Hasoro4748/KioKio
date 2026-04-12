import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/screens/customer/cart.dart';
import 'package:kiosk/screens/model_selection.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<Product> products = []; //  상품 리스트
  List<CartItem> cart = []; //  장바구니 목록

  String? selectedTheme; // 장르
  String? selectedType; // 종류
  int _tapCount = 0;
  DateTime? _lastTapTime;
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  List<String> get themes {
    final set = products.map((e) => e.pTheme).toSet().toList();
    set.sort();
    return set;
  }

  List<String> get types {
    final set = products.map((e) => e.pType).toSet().toList();
    set.sort();
    return set;
  }

  List<Product> get filteredProducts {
    return products.where((p) {
      final themeOk = (selectedTheme == null) || p.pTheme == selectedTheme;
      final typeOk = (selectedType == null) || p.pType == selectedType;
      return themeOk && typeOk;
    }).toList();
  }

  void _loadProducts() {
    setState(() {
      products = [
        Product(
            id: '1',
            name: '상품1',
            pTheme: '장르3',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '2',
            name: '상품2',
            pTheme: '장르1',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '3',
            name: '상품3',
            pTheme: '장르5',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '4',
            name: '상품4',
            pTheme: '장르2',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '5',
            name: '상품5',
            pTheme: '장르7',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '6',
            name: '상품6',
            pTheme: '장르4',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '7',
            name: '상품7',
            pTheme: '장르6',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '8',
            name: '상품8',
            pTheme: '장르8',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '9',
            name: '상품9',
            pTheme: '장르1',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '10',
            name: '상품10',
            pTheme: '장르2',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '11',
            name: '상품11',
            pTheme: '장르3',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '12',
            name: '상품12',
            pTheme: '장르4',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '13',
            name: '상품13',
            pTheme: '장르5',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '14',
            name: '상품14',
            pTheme: '장르6',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '15',
            name: '상품15',
            pTheme: '장르7',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '16',
            name: '상품16',
            pTheme: '장르8',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '17',
            name: '상품17',
            pTheme: '장르1',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
        Product(
            id: '18',
            name: '상품18',
            pTheme: '장르2',
            pType: '종류3',
            price: 1000,
            imagePath: 'assets/products/num3.png'),
        Product(
            id: '19',
            name: '상품19',
            pTheme: '장르3',
            pType: '종류2',
            price: 2000,
            imagePath: 'assets/products/num1.png'),
        Product(
            id: '20',
            name: '상품20',
            pTheme: '장르4',
            pType: '종류1',
            price: 3000,
            imagePath: 'assets/products/num2.png'),
      ];
    });
  }

  void _addToCart(Product product) {
    setState(() {
      cart.add(CartItem(product: product, quantity: 1));
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
                      child: Image.asset('assets/logo/logo1.png'),
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
                                    selected: selectedTheme == null,
                                    onTap: () {
                                      setState(() => selectedTheme = null);
                                    },
                                  ),
                                  ...themes.map((t) => _buildCategoryChip(
                                      color1: Color(0xFF181411),
                                      color2: Color(0xFFD80C06),
                                      fSize: 20,
                                      label: t,
                                      selected: selectedTheme == t,
                                      onTap: () {
                                        setState(() => selectedTheme = t);
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
                                    selected: selectedType == null,
                                    fSize: 16,
                                    onTap: () {
                                      setState(() => selectedType = null);
                                    },
                                  ),
                                  ...types.map((t) => _buildCategoryChip(
                                      color1: Color(0xFFEDE1CB),
                                      color2: Color(0xFFEDE1CB),
                                      fSize: 16,
                                      label: t,
                                      selected: selectedType == t,
                                      onTap: () {
                                        setState(() => selectedType = t);
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
                      // Container(
                      //   width: 200,
                      //   color: Color(0xFFFAEAB1),
                      //   child: Column(
                      //     children: [
                      //       const SizedBox(height: 16),
                      //       const Text('종류',
                      //           style: TextStyle(
                      //               fontSize: 18, fontWeight: FontWeight.bold)),
                      //       const SizedBox(height: 8),
                      //       Expanded(
                      //           child: ListView(
                      //         children: [
                      //           _buildSideCategoryChip(
                      //             label: '전체',
                      //             selected: selectedType == null,
                      //             onTap: () {
                      //               setState(() => selectedType = null);
                      //             },
                      //           ),
                      //           ...types.map((t) => _buildSideCategoryChip(
                      //               label: t,
                      //               selected: selectedType == t,
                      //               onTap: () {
                      //                 setState(() => selectedType = t);
                      //               })),
                      //           const SizedBox(
                      //             height: 16,
                      //           )
                      //         ],
                      //       ))
                      //     ],
                      //   ),
                      // ),
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
                              return _buildProductCard(product, _addToCart);
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
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: cart.isEmpty ? null : () => _goToCart(context),
      //   label: Text('장바구니 보기 (${cart.length})'),
      //   icon: Icon(Icons.shopping_cart),
      // ),
    );
  }

  Widget _buildProductCard(Product product, Function(Product) onAdd) {
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
                    image: AssetImage(product.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(product.name,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('${product.price.toString()}원',
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(item.product.name),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () {
                              setState(() {
                                item.quantity--;
                              });
                            }
                          : () {
                              setState(() {
                                cart.remove(item);
                              });
                            },
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text('${item.quantity}개'),
                    IconButton(
                      onPressed: item.quantity > 0 //max 로 변경 필요
                          ? () {
                              setState(() {
                                item.quantity++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.add_circle),
                    ),
                    const Spacer(),
                    Text('${item.product.price * item.quantity}원'),
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
                    '총 금액: ${_totalPrice()}원',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('결제하기'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        )
      ],
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
      (sum, item) => sum + item.product.price * item.quantity,
    );
  }

  Widget _buildSideCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.orange[400] : Colors.white,
            // borderRadius: BorderRadius.circular(24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.orange : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.label,
                size: 16,
                color: selected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetailDialog(Product product) {
    int quantity = 1;

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
                                  product.imagePath,
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
                                const Spacer(),
                                Padding(
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
                                        '가격: ${product.price}원',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text('장르 : ${product.pTheme}'),
                                      Text('종류 : ${product.pType}'),
                                      const SizedBox(height: 20),
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
                                            icon:
                                                const Icon(Icons.remove_circle),
                                          ),
                                          Text(
                                            '$quantity',
                                            style:
                                                const TextStyle(fontSize: 20),
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
                                            icon: const Icon(Icons.add_circle),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(
                                                () {
                                                  cart.add(CartItem(
                                                      product: product,
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
