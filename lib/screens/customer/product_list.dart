import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/network/kiosk_network_status.dart';
import 'package:kiosk/providers/kiosk_network_provider.dart';
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

  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;

  void _handleLogoTap() {
    final now = DateTime.now();

    // 이전 탭과의 간격이 500ms 이내인지 확인
    if (_lastLogoTapTime == null ||
        now.difference(_lastLogoTapTime!) > const Duration(milliseconds: 500)) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }

    _lastLogoTapTime = now;

    if (_logoTapCount == 3) {
      _logoTapCount = 0;
      _goHome();
    }
  }

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

  /// 네트워크 아이콘 클릭 시 동작
  void _onNetworkIconTap() {
    final status = ref.read(kioskNetworkProvider);
    final notifier = ref.read(kioskNetworkProvider.notifier);

    switch (status) {
      case KioskStatus.idle:
      case KioskStatus.error:
        // 연결이 없거나 에러 상태일 때 탐색 시작
        notifier.searchForPos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔍 POS 서버를 탐색합니다...')),
        );
        break;
      case KioskStatus.searching:
        // 이미 찾는 중일 때
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏳ 현재 POS 서버를 찾는 중입니다.')),
        );
        break;
      case KioskStatus.connected:
        // 이미 연결된 상태일 때
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ POS와 정상적으로 연결되어 있습니다.'),
            backgroundColor: DefaultColors.green,
          ),
        );
        break;
    }
  }

  void checkout() async {
    final order = OrderModel(
      items: List.from(cart),
      createdAt: DateTime.now(),
    );
    // DB에는 주문 저장 하지 않음
    // await ref.read(orderProvider.notifier).addOrder(order);
    final bool isSent =
        ref.read(kioskNetworkProvider.notifier).sendOrder(order);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (isSent) {
      _showOrderCompleteOverlay(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ POS 연결을 확인해주세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    setState(() {
      cart.clear();
    });
  }

  String generateOrderNumber() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}/'
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _showOrderCompleteOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: DefaultColors.green, size: 100),
                const SizedBox(height: 20),
                Text(
                  "주문이 완료되었습니다",
                  style: TextStyle(
                    color: PageColors.textBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'GmarketSans',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetworkIcon(KioskStatus status) {
    switch (status) {
      case KioskStatus.connected:
        return const Icon(
          Icons.check_circle,
          color: DefaultColors.green,
          size: 36,
        );
      case KioskStatus.searching:
        return const Icon(
          Icons.check_circle,
          color: DefaultColors.yellow,
          size: 36,
        );
      case KioskStatus.error:
        return const Icon(
          Icons.check_circle,
          color: DefaultColors.red,
          size: 36,
        );
      default:
        return const Icon(
          Icons.circle,
          color: DefaultColors.white,
          size: 36,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final productsAsync = ref.watch(productProvider);

    final networkStatus = ref.watch(kioskNetworkProvider);
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
                /// 왼쪽 테마 영역 (사이드바)
                /// =========================
                Container(
                  width: rs.isMobile ? 85 : 115,
                  decoration: BoxDecoration(
                    color: PageColors.cateBack, // 테마 배경색
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(2, 0),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // 로고 영역
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: rs.padding(30),
                            horizontal: rs.padding(12)),
                        child: GestureDetector(
                          onTap: _handleLogoTap, // 3번 탭 로직
                          child: Image.asset('assets/img/logo/logo1.png',
                              filterQuality: FilterQuality.high),
                        ),
                      ),

                      // 테마 리스트
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: themes
                              .map((t) => ThemeChip(
                                    label: t,
                                    selected: selectedTheme == t,
                                    enabled: isThemeEnabled(products, t),
                                    onTap: () => setState(() => selectedTheme =
                                        (selectedTheme == t ? null : t)),
                                  ))
                              .toList(),
                        ),
                      ),

                      // 시스템 제어 영역 (하단 고정)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _onNetworkIconTap,
                              icon: _buildNetworkIcon(networkStatus),
                              tooltip: 'POS 연결',
                            ),
                            const SizedBox(height: 12),
                            IconButton(
                              onPressed: () => ref
                                  .read(kioskNetworkProvider.notifier)
                                  .stopDiscoveryService(),
                              icon: Icon(
                                Icons.stop_circle_outlined,
                                color: (networkStatus ==
                                            KioskStatus.connected ||
                                        networkStatus == KioskStatus.searching)
                                    ? DefaultColors.red
                                    : Colors.white.withOpacity(0.3),
                                size: 32,
                              ),
                            ),
                          ],
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
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // ==========================================
                              // '전체보기' 버튼 디자인 차별화 (수정된 부분)
                              // ==========================================
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: InkWell(
                                  onTap: () => setState(() => initTag()),
                                  borderRadius: BorderRadius.circular(30),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      // 전체보기 상태일 때만 배경색을 꽉 채움
                                      color: (selectedSeller == null &&
                                              selectedTheme == null &&
                                              selectedCate == null)
                                          ? PageColors.cateSelect
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: PageColors.cateSelect,
                                        width: 1.5,
                                      ),
                                      boxShadow: (selectedSeller == null &&
                                              selectedTheme == null &&
                                              selectedCate == null)
                                          ? [
                                              BoxShadow(
                                                color: PageColors.cateSelect
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons
                                              .grid_view_rounded, // 전체보기를 상징하는 아이콘 추가
                                          size: 20,
                                          color: (selectedSeller == null &&
                                                  selectedTheme == null &&
                                                  selectedCate == null)
                                              ? Colors.white
                                              : PageColors.cateSelect,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '전체보기',
                                          style: TextStyle(
                                            fontSize: rs.font(16),
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'GmarketSans',
                                            color: (selectedSeller == null &&
                                                    selectedTheme == null &&
                                                    selectedCate == null)
                                                ? Colors.white
                                                : PageColors.cateSelect,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 구분선 디자인 강화
                              Container(
                                height: 30,
                                width: 1.5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                color: Colors.grey.shade300,
                              ),

                              // 기존 판매자 리스트
                              ...sellers.map((s) => CategoryChip(
                                    fSize: rs.font(18),
                                    label: s,
                                    selected: selectedSeller == s,
                                    enabled: isSellerEnabled(products, s),
                                    onTap: () => setState(() => selectedSeller =
                                        (selectedSeller == s ? null : s)),
                                  )),
                            ],
                          ),
                        ),
                      ),

                      /// 2. 카테고리 필터 (서브 바)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: baseBackgroundColor[50], // 아주 연한 배경
                          border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              ...categoryGroups.map((c) => CategoryChip(
                                    enabled: true,
                                    fSize: rs.font(16),
                                    label: c,
                                    selected: selectedCate == c,
                                    onTap: () => setState(() => selectedCate =
                                        (selectedCate == c ? null : c)),
                                  )),
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
                                                                  context)
                                                              .removeCurrentSnackBar();
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
