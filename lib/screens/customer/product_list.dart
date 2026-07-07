import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/customer/widgets/cart_panel.dart';
import 'package:kiosk/screens/customer/widgets/category_chip.dart';
import 'package:kiosk/screens/customer/widgets/product_card.dart';
import 'package:kiosk/screens/customer/widgets/product_detail_dialog.dart';
import 'package:kiosk/screens/customer/widgets/theme_chip.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:collection/collection.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  List<OrderItemModel> cart = [];

  String? selectedTheme;
  String? selectedCate;
  String? selectedSeller;

  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
  }

  void initTag() {
    selectedCate = null;
    selectedTheme = null;
    selectedSeller = null;
  }

  List<String> getThemes(List<ProductModel> products) {
    return products.expand((e) => e.themes).toSet().toList()..sort();
  }

  List<String> getCategoryGroups(List<ProductModel> products) {
    final filtered = products.where((p) {
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);

      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      return themeOk && sellerOk;
    });

    return filtered.expand((e) => e.categories).toSet().toList()..sort();
  }

  List<String> getSellers(List<ProductModel> products) {
    return products.expand((e) => e.sellers).toSet().toList();
  }

  List<ProductModel> getFilteredProducts(List<ProductModel> products) {
    return products.where((p) {
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);

      final cateOk =
          selectedCate == null || p.categories.contains(selectedCate);

      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      return themeOk && cateOk && sellerOk;
    }).toList();
  }

  bool isSellerEnabled(
    List<ProductModel> products,
    String sellerName,
  ) {
    return products.any((p) {
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);

      final cateOk =
          selectedCate == null || p.categories.contains(selectedCate);

      final sellerOk = p.sellers.contains(sellerName);

      return themeOk && sellerOk && cateOk;
    });
  }

  bool isThemeEnabled(
    List<ProductModel> products,
    String themeName,
  ) {
    return products.any((p) {
      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      final cateOk =
          selectedCate == null || p.categories.contains(selectedCate);

      final themeOk = p.themes.contains(themeName);

      return themeOk && sellerOk && cateOk;
    });
  }

  bool canOrder(ProductModel product) {
    return product.isAvailable && product.stock > 0;
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ModelSelectionScreen(),
      ),
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

  int _getStock(List<ProductModel> products, int productId) {
    return products.firstWhere((p) => p.id == productId).stock;
  }

  void _confirmCheckout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('주문 확인'),
        content: Text(
          '총 ${_totalValue()}개 / ${TextUtil.money(_totalPrice())}원\n주문하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              checkout();

              setState(() {
                initTag();
              });
            },
            child: const Text('주문하기'),
          ),
        ],
      ),
    );
  }

  void checkout() async {
    final order = OrderModel(
      items: List.from(cart),
      createdAt: DateTime.now(),
    );
    await ref.read(orderProvider.notifier).addOrder(order);

    setState(() {
      cart.clear();
    });
  }

  String generateOrderNumber() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}/'
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final productsAsync = ref.watch(productProvider);

    return productsAsync.when(
        loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        error: (error, stack) => Scaffold(
              body: Center(
                child: Text('상품을 불러오지 못했습니다.\n$error'),
              ),
            ),
        data: (products) {
          final themes = getThemes(products);

          final sellers = getSellers(products);

          final categoryGroups = getCategoryGroups(products);

          final filteredProducts = getFilteredProducts(products);

          return Scaffold(
            body: Row(
              children: [
                /// =========================
                /// 왼쪽 테마 영역
                /// =========================

                Container(
                  width: rs.isMobile ? 80 : 110,
                  decoration: BoxDecoration(
                    color: PageColors.theme,
                    border: Border.all(width: 0),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(
                          rs.padding(8),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            final now = DateTime.now();

                            if (_lastTapTime == null ||
                                now.difference(_lastTapTime!) >
                                    const Duration(seconds: 1)) {
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
                          child: Image.asset(
                            'assets/img/logo/logo1.png',
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...themes.map(
                                (t) => ThemeChip(
                                  label: t,
                                  selected: selectedTheme == t,
                                  enabled: isThemeEnabled(products, t),
                                  onTap: () {
                                    setState(() {
                                      if (selectedTheme != t) {
                                        if (!isThemeEnabled(products, t)) {
                                          selectedSeller = null;
                                          selectedCate = null;
                                        }
                                        selectedTheme = t;
                                      } else {
                                        selectedTheme = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// =========================
                /// 오른쪽 메인 영역
                /// =========================

                Expanded(
                  child: Column(
                    children: [
                      /// 판매자 필터

                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: PageColors.cateBack,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                decoration:
                                    BoxDecoration(color: PageColors.theme),
                                child: CategoryChip(
                                  label: '모든 상품 보기',
                                  fSize: rs.font(20),
                                  selected: selectedSeller == null &&
                                      selectedTheme == null &&
                                      selectedCate == null,
                                  enabled: true,
                                  onTap: () {
                                    setState(() {
                                      initTag();
                                    });
                                  },
                                ),
                              ),
                              ...sellers.map(
                                (t) => CategoryChip(
                                  fSize: rs.font(20),
                                  label: t,
                                  selected: selectedSeller == t,
                                  enabled: isSellerEnabled(products, t),
                                  onTap: () {
                                    setState(() {
                                      if (selectedSeller != t) {
                                        if (!isSellerEnabled(products, t)) {
                                          selectedTheme = null;
                                          selectedCate = null;
                                        }
                                        selectedSeller = t;
                                      } else {
                                        selectedSeller = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: rs.padding(32),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 카테고리 필터

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: baseBackgroundColor,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: rs.padding(32),
                              ),
                              ...categoryGroups.map(
                                (t) => CategoryChip(
                                  enabled: true,
                                  fSize: rs.font(18),
                                  label: t,
                                  selected: selectedCate == t,
                                  onTap: () {
                                    setState(() {
                                      selectedCate =
                                          selectedCate != t ? t : null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: rs.padding(32),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 상품 리스트 + 장바구니

                      Expanded(
                        child: rs.isMobile || rs.isTablet
                            ?

                            /// =========================
                            /// 모바일 / 태블릿
                            /// =========================

                            Column(
                                children: [
                                  /// 상품 리스트
                                  Expanded(
                                    child: Container(
                                      color: baseBackgroundColor,
                                      child: GridView.builder(
                                        padding: EdgeInsets.all(
                                          rs.padding(16),
                                        ),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent:
                                              rs.isMobile ? 220 : 260,
                                          childAspectRatio:
                                              rs.isMobile ? 0.62 : 0.72,
                                          crossAxisSpacing: rs.padding(16),
                                          mainAxisSpacing: rs.padding(16),
                                        ),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              filteredProducts[index];

                                          return ProductCard(
                                            product: product,
                                            onTap: canOrder(product)
                                                ? () => showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          ProductDetailDialog(
                                                        product: product,
                                                        onAddCart: (quantity) {
                                                          final existing = cart
                                                              .firstWhereOrNull(
                                                            (e) =>
                                                                e.productId ==
                                                                product.id,
                                                          );

                                                          setState(() {
                                                            if (existing !=
                                                                null) {
                                                              existing.quantity +=
                                                                  quantity;
                                                            } else {
                                                              cart.add(
                                                                OrderItemModel(
                                                                  productId:
                                                                      product
                                                                          .id,
                                                                  name: product
                                                                      .name,
                                                                  basePrice: product
                                                                      .basePrice,
                                                                  quantity:
                                                                      quantity,
                                                                ),
                                                              );
                                                            }
                                                          });

                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${product.name} ${quantity}개를 장바구니에 담았습니다.',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  /// 하단 장바구니
                                  if (cart.isNotEmpty)
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.46,
                                      decoration: BoxDecoration(
                                        color: baseBackgroundColor,
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      child: SafeArea(
                                        top: false,
                                        child: CartPanel(
                                          cart: cart,
                                          totalValue: _totalValue(),
                                          totalPrice: _totalPrice(),
                                          getStock: (productId) =>
                                              _getStock(products, productId),
                                          onClear: () {
                                            setState(() {
                                              cart.clear();
                                            });
                                          },
                                          onIncrease: (item) {
                                            setState(() {
                                              item.quantity++;
                                            });
                                          },
                                          onDecrease: (item) {
                                            setState(() {
                                              if (item.quantity > 1) {
                                                item.quantity--;
                                              } else {
                                                cart.remove(item);
                                              }
                                            });
                                          },
                                          onCheckout: _confirmCheckout,
                                        ),
                                      ),
                                    ),
                                ],
                              )

                            /// =========================
                            /// 데스크탑
                            /// =========================

                            : Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: baseBackgroundColor,
                                      child: GridView.builder(
                                        padding: EdgeInsets.all(
                                          rs.padding(16),
                                        ),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent:
                                              cart.isNotEmpty ? 280 : 320,
                                          childAspectRatio: 0.8,
                                          crossAxisSpacing: rs.padding(16),
                                          mainAxisSpacing: rs.padding(16),
                                        ),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              filteredProducts[index];

                                          return ProductCard(
                                            product: product,
                                            onTap: canOrder(product)
                                                ? () => showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          ProductDetailDialog(
                                                        product: product,
                                                        onAddCart: (quantity) {
                                                          final existing = cart
                                                              .firstWhereOrNull(
                                                            (e) =>
                                                                e.productId ==
                                                                product.id,
                                                          );

                                                          setState(() {
                                                            if (existing !=
                                                                null) {
                                                              existing.quantity +=
                                                                  quantity;
                                                            } else {
                                                              cart.add(
                                                                OrderItemModel(
                                                                  productId:
                                                                      product
                                                                          .id,
                                                                  name: product
                                                                      .name,
                                                                  basePrice: product
                                                                      .basePrice,
                                                                  quantity:
                                                                      quantity,
                                                                ),
                                                              );
                                                            }
                                                          });

                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${product.name} ${quantity}개를 장바구니에 담았습니다.',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if (cart.isNotEmpty)
                                    Container(
                                      width: rs.screenWidth * 0.3,
                                      color: baseBackgroundColor,
                                      child: CartPanel(
                                        cart: cart,
                                        totalValue: _totalValue(),
                                        totalPrice: _totalPrice(),
                                        getStock: (productId) =>
                                            _getStock(products, productId),
                                        onClear: () {
                                          setState(() {
                                            cart.clear();
                                          });
                                        },
                                        onIncrease: (item) {
                                          setState(() {
                                            item.quantity++;
                                          });
                                        },
                                        onDecrease: (item) {
                                          setState(() {
                                            if (item.quantity > 1) {
                                              item.quantity--;
                                            } else {
                                              cart.remove(item);
                                            }
                                          });
                                        },
                                        onCheckout: _confirmCheckout,
                                      ),
                                    ),
                                ],
                              ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
