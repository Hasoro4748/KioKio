import 'dart:async';

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
import 'package:kiosk/screens/customer/widgets/idle_screen.dart';
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
  bool _isIdle = false;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;

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
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = 30; // 15초로 리셋
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // 0초가 되면 대기화면으로 전환
        timer.cancel();
        _onIdleTimeout();
      }
    });
  }

  void _onIdleTimeout() {
    if (mounted) {
      Navigator.of(context)
          .popUntil((route) => route.isFirst || route.settings.name == '/');
    }
    setState(() {
      _isIdle = true;
      cart.clear(); // 장바구니 초기화
      initTag(); // 카테고리 필터 초기화
    });
  }

  void _handleUserInteraction([_]) {
    if (_isIdle) return; // 이미 대기화면이면 무시
    _startTimer(); // 타이머 리셋
  }

  void initTag() {
    selectedCate = null;
    selectedTheme = null;
    selectedSeller = null;
  }

  List<String> getThemes(List<ProductModel> products) {
    return products
        .where((p) => p.isAvailable) // 판매 가능 상품만 필터링
        .expand((e) => e.themes)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> getCategoryGroups(List<ProductModel> products) {
    final filtered = products.where((p) {
      // 판매 가능 여부 필수 조건 추가
      final availableOk = p.isAvailable;
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);
      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      return availableOk && themeOk && sellerOk;
    });

    return filtered.expand((e) => e.categories).toSet().toList()..sort();
  }

  List<String> getSellers(List<ProductModel> products) {
    return products
        .where((p) => p.isAvailable) // 판매 가능 상품만 필터링
        .expand((e) => e.sellers)
        .toSet()
        .toList();
  }

  List<ProductModel> getFilteredProducts(List<ProductModel> products) {
    return products.where((p) {
      final availableOk = p.isAvailable;
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);

      final cateOk =
          selectedCate == null || p.categories.contains(selectedCate);

      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      return availableOk && themeOk && cateOk && sellerOk;
    }).toList();
  }

  bool isSellerEnabled(List<ProductModel> products, String sellerName) {
    return products.any((p) {
      return p.isAvailable && // 추가
          (selectedTheme == null || p.themes.contains(selectedTheme)) &&
          (selectedCate == null || p.categories.contains(selectedCate)) &&
          p.sellers.contains(sellerName);
    });
  }

  bool isThemeEnabled(List<ProductModel> products, String themeName) {
    return products.any((p) {
      return p.isAvailable && // 추가
          (selectedSeller == null || p.sellers.contains(selectedSeller)) &&
          (selectedCate == null || p.categories.contains(selectedCate)) &&
          p.themes.contains(themeName);
    });
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
      final productNotifier = ref.read(productProvider.notifier);
      final products = ref.read(productProvider).value ?? [];

      for (var item in cart) {
        final product =
            products.firstWhereOrNull((p) => p.id == item.productId);
        if (product != null) {
          // 기존 재고에서 주문 수량만큼 뺀 새로운 모델 생성
          final updatedProduct = product.copyWith(
              stock: (product.stock - item.quantity)
                  .clamp(0, double.infinity)
                  .toInt());
          // DB 업데이트 호출 (Repository 연동)
          await productNotifier.updateProduct(updatedProduct);
        }
      }
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
          child: Material(
            // 1. 여기에 Material 위젯을 추가합니다.
            color: Colors.transparent, // 배경은 투명하게 유지
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  const BoxShadow(color: Colors.black26, blurRadius: 20)
                ],
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
                      decoration: TextDecoration.none, // 2. 확실히 하기 위해 데코레이션 제거
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Responsive rs, KioskStatus status) {
    String message;
    IconData icon;
    Color iconColor;

    switch (status) {
      case KioskStatus.connected:
        message = '등록된 상품이 없습니다.\nPOS에서 상품을 추가하거나 동기화해 주세요.';
        icon = Icons.inventory_2_outlined;
        iconColor = iconThemeColor[300]!;
        break;
      case KioskStatus.searching:
        message = 'POS 서버를 찾는 중입니다...\n서버가 켜져 있는지 확인해 주세요.';
        icon = Icons.manage_search_rounded;
        iconColor = DefaultColors.yellow;
        break;
      case KioskStatus.error:
        message = 'POS 연결 중 오류가 발생했습니다.\n다시 시도해 주세요.';
        icon = Icons.sync_problem_rounded;
        iconColor = DefaultColors.red;
        break;
      default:
        message = 'POS 서버와 연결되지 않았습니다.\n아래 버튼을 눌러 연결을 시작하세요.';
        icon = Icons.cloud_off_rounded;
        iconColor = iconThemeColor[200]!;
    }

    return Scaffold(
      backgroundColor: baseBackgroundColor[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _handleLogoTap,
              child: Opacity(
                opacity: 0.3,
                child: Image.asset('assets/icon/appIcon2.png', width: 80),
              ),
            ),
            const SizedBox(height: 48),

            // 탐색 중일 때 회전 애니메이션 추가 (옵션)
            if (status == KioskStatus.searching)
              const CircularProgressIndicator()
            else
              Icon(icon, size: rs.font(80), color: iconColor),

            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rs.font(18),
                fontWeight: FontWeight.w500,
                color: iconThemeColor[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // --- 상황별 버튼 배치 (핵심 수정 부분) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 연결 시작 버튼 (대기/에러 상태일 때)
                if (status == KioskStatus.idle || status == KioskStatus.error)
                  ElevatedButton.icon(
                    onPressed: _onNetworkIconTap,
                    icon: const Icon(Icons.sync),
                    label: const Text('POS 서버 연결 시도'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      backgroundColor: iconThemeColor[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                // 2. 탐색 중단 버튼 (탐색 중이거나 에러 상태일 때)
                if (status == KioskStatus.searching ||
                    status == KioskStatus.error)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(kioskNetworkProvider.notifier)
                            .stopDiscoveryService();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🛑 탐색이 중단되었습니다.')),
                        );
                      },
                      icon: const Icon(Icons.stop_circle_outlined,
                          color: Colors.red),
                      label: const Text('탐색 중단',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),
            TextButton(
              onPressed: _goHome,
              child: Text(
                '메인으로 돌아가기',
                style: TextStyle(color: iconThemeColor[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isIdle) {
      return IdleScreen(onStart: () {
        setState(() {
          _isIdle = false;
          _startTimer(); // 다시 15초 카운트 시작
        });
      });
    }

    // 2. 본래 화면을 Listener로 감싸서 터치 감지
    return Listener(
      onPointerDown: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        // 카운트다운 문구를 겹쳐서 띄우기 위해 Stack 사용
        children: [
          _buildMainContent(context),

          // --- 카운트다운 경고 문구 추가 (10초 이하일 때만 노출) ---
          if (_remainingSeconds <= 10)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  // 1. Material 위젯으로 감싸줍니다.
                  color: Colors.transparent, // 배경은 투명하게
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '조작이 없을 시 $_remainingSeconds초 후 화면이 초기화됩니다.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration:
                                TextDecoration.none, // 2. (선택사항) 밑줄 강제 제거
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '화면을 터치하면 계속 주문할 수 있습니다.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration:
                                TextDecoration.none, // 2. (선택사항) 밑줄 강제 제거
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final rs = Responsive(context);
    final productsAsync = ref.watch(productProvider);
    final networkStatus = ref.watch(kioskNetworkProvider);

    return productsAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) =>
            Scaffold(body: Center(child: Text('상품 로드 실패\n$error'))),
        data: (products) {
          // --- 핵심 수정 부분: 연결 상태를 최우선으로 확인 ---

          // 1. POS와 연결되지 않은 경우, 무조건 안내 화면 표시
          if (networkStatus != KioskStatus.connected) {
            return _buildEmptyState(rs, networkStatus);
          }

          // 2. 연결은 되었으나 상품이 아직 동기화되지 않은 경우
          if (products.isEmpty) {
            return _buildEmptyState(rs, networkStatus);
          }

          // 3. 연결 성공 + 상품 존재 시에만 본래의 상품 목록 표시
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
                          child: Image.asset('assets/icon/appIcon2.png',
                              filterQuality: FilterQuality.high),
                        ),
                      ),

                      // 테마 리스트
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: themes.map((t) {
                            final bool isEnabled = isThemeEnabled(products, t);
                            return ThemeChip(
                              label: t,
                              selected: selectedTheme == t,
                              enabled: isEnabled,
                              onTap: () {
                                setState(() {
                                  if (!isEnabled) {
                                    // 비활성 상태에서 클릭 시: 다른 필터 초기화 후 강제 선택
                                    selectedSeller = null;
                                    selectedCate = null;
                                  }
                                  selectedTheme =
                                      (selectedTheme == t ? null : t);
                                });
                              },
                            );
                          }).toList(),
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
                              ...sellers.map((s) {
                                final bool isEnabled =
                                    isSellerEnabled(products, s);
                                return CategoryChip(
                                  fSize: rs.font(18),
                                  label: s,
                                  selected: selectedSeller == s,
                                  enabled: isEnabled,
                                  onTap: () {
                                    setState(() {
                                      if (!isEnabled) {
                                        // 비활성 상태에서 클릭 시: 다른 필터 초기화 후 강제 선택
                                        selectedTheme = null;
                                        selectedCate = null;
                                      }
                                      selectedSeller =
                                          (selectedSeller == s ? null : s);
                                    });
                                  },
                                );
                              }),
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
                                            onTap: !product.isSoldOut
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
                                            onTap: !product.isSoldOut
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
