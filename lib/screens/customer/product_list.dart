import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/network/kiosk_network_status.dart';
import 'package:kiosk/providers/dao_provider.dart';
import 'package:kiosk/providers/kiosk_network_provider.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/providers/remaining_seconds_provider.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/providers/sync_progress_provider.dart';
import 'package:kiosk/providers/user_activity_provider.dart';
import 'package:kiosk/screens/customer/widgets/cart_panel.dart';
import 'package:kiosk/screens/customer/widgets/category_chip.dart';
import 'package:kiosk/screens/customer/widgets/idle_screen.dart';
import 'package:kiosk/screens/customer/widgets/product_card.dart';
import 'package:kiosk/screens/customer/widgets/product_detail_dialog.dart';
import 'package:kiosk/screens/customer/widgets/theme_chip.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/kiosk_helper.dart';
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
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasUserTouched = false;

  final ScrollController _scrollController = ScrollController();
  void _resetScrollPosition() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _startTimer() {
    final settings = ref.read(settingsProvider);
    final idleMode = settings.kioskIdleMode;
    final networkStatus = ref.read(kioskNetworkProvider);

    // ★ POS 서버와 정상 연결(connected)된 상태가 아니면 타이머 동작 중지!
    if (networkStatus != KioskStatus.connected) {
      _countdownTimer?.cancel();
      _updateSeconds(999);
      return;
    }

    // 1. OFF 모드일 때
    if (idleMode == 'off') {
      _countdownTimer?.cancel();
      _updateSeconds(999);
      return;
    }

    // 2. 대기화면 없이 자동 초기화 모드일 때 (첫 터치 발생 전까지 대기)
    if (idleMode == 'reset_only' && !_hasUserTouched && cart.isEmpty) {
      _countdownTimer?.cancel();
      _updateSeconds(999);
      return;
    }

    // 3. 타이머 카운트다운 시작
    final waitTime = settings.kioskWaitTime;
    _countdownTimer?.cancel();
    _updateSeconds(waitTime > 0 ? waitTime : 15);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentStatus = ref.read(kioskNetworkProvider);
      final currentMode = ref.read(settingsProvider).kioskIdleMode;

      // ★ 타이머 도중 연결이 끊기거나 OFF 모드가 되면 즉시 중지
      if (currentStatus != KioskStatus.connected || currentMode == 'off') {
        timer.cancel();
        _updateSeconds(999);
        return;
      }

      if (_remainingSeconds > 0) {
        _updateSeconds(_remainingSeconds - 1);
      } else {
        timer.cancel();
        _onIdleTimeout();
      }
    });
  }

  void _updateSeconds(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
    });
    ref.read(remainingSecondsProvider.notifier).state = seconds;
  }

  void _onIdleTimeout() {
    final idleMode = ref.read(settingsProvider).kioskIdleMode;

    if (mounted) {
      Navigator.of(context)
          .popUntil((route) => route.isFirst || route.settings.name == '/');
    }

    setState(() {
      cart.clear(); // 장바구니 초기화
      initTag(); // 필터 초기화
      _hasUserTouched = false; // ★ 터치 플래그 리셋

      if (idleMode == 'use_idle') {
        _isIdle = true; // 대기화면 표출
      } else {
        _isIdle = false; // 대기화면 표출 안 함 (상품 화면에 머무름)
        _remainingSeconds = 999;
      }
    });
    _resetScrollPosition();
  }

  void _handleUserInteraction([_]) {
    final idleMode = ref.read(settingsProvider).kioskIdleMode;
    if (idleMode == 'off') return;

    if (_isIdle) return;

    _hasUserTouched = true; // ★ 첫 터치 입력 감지!
    _startTimer();
  }

  void initTag() {
    selectedCate = null;
    selectedTheme = null;
    selectedSeller = null;
    _resetScrollPosition();
  }

  List<String> getThemes(
      List<ProductModel> products, List<String> masterThemes) {
    final set = <String>{};
    for (var p in products) {
      if (p.isAvailable) set.addAll(p.themes);
    }
    return sortTagsByMasterOrder(set.toList(), masterThemes);
  }

  List<String> getCategoryGroups(
      List<ProductModel> products, List<String> masterCategories) {
    final filtered = products.where((p) {
      final availableOk = p.isAvailable;
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);
      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);
      return availableOk && themeOk && sellerOk;
    });

    final set = <String>{};
    for (var p in filtered) {
      set.addAll(p.categories);
    }
    return sortTagsByMasterOrder(set.toList(), masterCategories);
  }

  List<String> getSellers(
      List<ProductModel> products, List<String> masterSellers) {
    final set = <String>{};
    for (var p in products) {
      if (p.isAvailable) set.addAll(p.sellers);
    }
    return sortTagsByMasterOrder(set.toList(), masterSellers);
  }

  List<ProductModel> getFilteredProducts(List<ProductModel> products) {
    final list = products.where((p) {
      final availableOk = p.isAvailable;
      final themeOk = selectedTheme == null || p.themes.contains(selectedTheme);

      final cateOk =
          selectedCate == null || p.categories.contains(selectedCate);

      final sellerOk =
          selectedSeller == null || p.sellers.contains(selectedSeller);

      return availableOk && themeOk && cateOk && sellerOk;
    }).toList();

    // ★ displayOrder 오름차순 정렬 추가 (동일한 순서 번호일 경우 생성일순)
    list.sort((a, b) {
      final cmp = a.displayOrder.compareTo(b.displayOrder);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });

    return list;
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

  int _getCartQuantity(int productId) {
    final item = cart.firstWhereOrNull((e) => e.productId == productId);
    return item?.quantity ?? 0;
  }

  void _confirmCheckout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout_rounded,
                color: PageColors.cateSelect, size: 24),
            SizedBox(width: 8),
            Text(
              '주문 내역 확인',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('주문 품목 리스트',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // ★ 1. 주문 상품 목록 (최대 200px 높이 내에서 스크롤 지원)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    children: cart.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            // 상품명 (최대 2줄)
                            Expanded(
                              flex: 6,
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 수량
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.quantity}개',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                            // 금액
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${TextUtil.money(item.totalPrice)}원',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: PageColors.price),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Divider(height: 24, thickness: 1),

              // ★ 2. 결제 요약 정보 박스
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('총 주문 수량',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('${_totalValue()}개',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('최종 결제 금액',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '${TextUtil.money(_totalPrice())}원',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: PageColors.price,
                            fontFamily: 'GmarketSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '위 내용으로 주문을 진행하시겠습니까?',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              checkout();
              setState(() => initTag());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PageColors.cateSelect,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('주문하기',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
    final bool isSent =
        ref.read(kioskNetworkProvider.notifier).sendOrder(order);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (isSent) {
      // ★ 2. 전송 성공 즉시 완료 팝업 노출 및 장바구니 초기화 (체감 속도 0초!)
      _showOrderCompleteOverlay(context);
      final cartItems = List<OrderItemModel>.from(cart);
      setState(() => cart.clear());

      // ★ 3. 로컬 재고 차감은 백그라운드 비동기로 처리 (사용자 대기 시간 0초)
      _updateLocalStockInBackground(cartItems);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ POS 연결을 확인해주세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    setState(() => cart.clear());
  }

  Future<void> _updateLocalStockInBackground(
      List<OrderItemModel> cartItems) async {
    try {
      final products = ref.read(productProvider).value ?? [];
      final Map<int, int> stockUpdates = {};

      for (var item in cartItems) {
        final product =
            products.firstWhereOrNull((p) => p.id == item.productId);
        if (product != null) {
          if (product.isSet && product.componentIds.isNotEmpty) {
            for (var subId in product.componentIds) {
              final subProduct =
                  products.firstWhereOrNull((p) => p.id == subId);
              if (subProduct != null) {
                final currentStock = stockUpdates[subId] ?? subProduct.stock;
                stockUpdates[subId] =
                    (currentStock - item.quantity).clamp(0, 99999).toInt();
              }
            }
          } else {
            final currentStock = stockUpdates[product.id] ?? product.stock;
            stockUpdates[product.id] =
                (currentStock - item.quantity).clamp(0, 99999).toInt();
          }
        }
      }

      if (stockUpdates.isNotEmpty) {
        await ref
            .read(productProvider.notifier)
            .updateProductsStockBatch(stockUpdates);
      }
    } catch (e) {
      print("로컬 재고 차감 실패: $e");
    }
  }

  String generateOrderNumber() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}/'
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  List<String> sortTagsByMasterOrder(
      List<String> tags, List<String> masterOrder) {
    final list = List<String>.from(tags);
    list.sort((a, b) {
      int indexA = masterOrder.indexOf(a);
      int indexB = masterOrder.indexOf(b);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });
    return list;
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
    final useIdleScreen =
        ref.watch(settingsProvider.select((s) => s.useKioskIdleScreen));

    final logoPath = ref.watch(settingsProvider.select((s) => s.kioskLogoPath));
    final WelcomeMessage =
        ref.watch(settingsProvider.select((s) => s.kioskWelcomeMessage));

    // ★ 1. POS 연결 상태 변경 리스너:
    // POS와 연결이 성공(connected)하는 순간 타이머 자동 시작!
    ref.listen<KioskStatus>(kioskNetworkProvider, (previous, next) {
      if (next == KioskStatus.connected) {
        _startTimer(); // 👈 연결 완료 시 타이머 시작!
      } else {
        _countdownTimer?.cancel();
        _updateSeconds(999);
        setState(() => _isIdle = false);
      }
    });

    // ★ 2. POS 환경설정(idleMode) 변경 리스너:
    // 대기화면 모드가 변경되면 타이머 재설정!
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      if (previous?.kioskIdleMode != next.kioskIdleMode) {
        _startTimer(); // 👈 설정 변경 시 타이머 재시작!
      }
    });

    // ★ 3. 팝업 창 등 전역 터치 발생 리스너:
    ref.listen<int>(userActivityProvider, (previous, next) {
      _handleUserInteraction();
    });

    // 'use_idle' 모드이면서 _isIdle이 true일 때 대기화면 표출
    if (_isIdle && ref.watch(settingsProvider).kioskIdleMode == 'use_idle') {
      return IdleScreen(
        welcomeMessage: WelcomeMessage,
        logoPath: logoPath,
        onStart: () {
          setState(() {
            _isIdle = false;
            _hasUserTouched = true;
          });
          _startTimer();
          _resetScrollPosition();
        },
      );
    }

    // 본래 키오스크 메인 화면
    return Listener(
      onPointerDown: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          _buildMainContent(context),
          CountdownWarningBanner(remainingSeconds: _remainingSeconds),
          const SyncProgressOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final rs = Responsive(context);
    final productsAsync = ref.watch(productProvider);
    final networkStatus = ref.watch(kioskNetworkProvider);
    final settings = ref.watch(settingsProvider);

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
          final masterThemes = ref.watch(orderedThemesProvider).value ?? [];
          final masterCategories =
              ref.watch(orderedCategoriesProvider).value ?? [];
          final masterSellers = ref.watch(orderedSellersProvider).value ?? [];

          // 3. 연결 성공 + 상품 존재 시에만 본래의 상품 목록 표시
          final themes = getThemes(products, masterThemes);
          final sellers = getSellers(products, masterSellers);
          final categoryGroups = getCategoryGroups(products, masterCategories);

          final filteredProducts = getFilteredProducts(products);
          final Map<String, List<ProductModel>> groupedProducts = {};
          for (var p in filteredProducts) {
            final themes = p.themes.isEmpty ? ['기타'] : p.themes;
            for (var t in themes) {
              if (selectedTheme == null || selectedTheme == t) {
                groupedProducts.putIfAbsent(t, () => []).add(p);
              }
            }
          }
          final sortedKeys = sortTagsByMasterOrder(
              groupedProducts.keys.toList(), masterThemes);

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
                          child: settings.kioskLogoPath.isEmpty
                              ? Image.asset('assets/img/logo/logo1.png') // 기본값
                              : (settings.kioskLogoPath.startsWith('assets/')
                                  ? Image.asset(settings.kioskLogoPath)
                                  : Image.file(File(settings.kioskLogoPath))),
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
                                              KioskHelper.calculateMaxExtent(
                                                  context,
                                                  settings.kioskGridCount,
                                                  cart.isNotEmpty,
                                                  rs),
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
                                                ? () {
                                                    final int currentInCart =
                                                        _getCartQuantity(
                                                            product.id);
                                                    final int availableToOrder =
                                                        product.stock -
                                                            currentInCart;
                                                    if (availableToOrder <= 0) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              '이미 장바구니에 해당 상품의 모든 재고가 담겨 있습니다.'),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          ProductDetailDialog(
                                                        product: product.copyWith(
                                                            stock:
                                                                availableToOrder),
                                                        onAddCart:
                                                            (targetProduct,
                                                                quantity) {
                                                          final existing = cart
                                                              .firstWhereOrNull(
                                                            (e) =>
                                                                e.productId ==
                                                                targetProduct
                                                                    .id,
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
                                                                      targetProduct
                                                                          .id,
                                                                  name:
                                                                      targetProduct
                                                                          .name,
                                                                  basePrice:
                                                                      targetProduct
                                                                          .basePrice,
                                                                  quantity:
                                                                      quantity,
                                                                ),
                                                              );
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  }
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
                                          onClear: () =>
                                              setState(() => cart.clear()),
                                          onRemoveItem: (item) => setState(() =>
                                              cart.remove(
                                                  item)), // ★ 개별 X 삭제 추가
                                          onIncrease: (item) =>
                                              setState(() => item.quantity++),
                                          onDecrease: (item) => setState(() {
                                            if (item.quantity > 1) {
                                              item.quantity--;
                                            } else {
                                              cart.remove(item);
                                            }
                                          }),
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
                                  /// 왼쪽: 테마별 상품 목록 섹션
                                  Expanded(
                                    child: Container(
                                      color: baseBackgroundColor,
                                      child: ListView.builder(
                                        padding: EdgeInsets.all(rs.padding(8)),
                                        itemCount: sortedKeys.length,
                                        itemBuilder: (context, index) {
                                          final themeName = sortedKeys[index];
                                          final themeProducts =
                                              groupedProducts[themeName]!;

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 테마 섹션 헤더
                                              _buildThemeSectionHeader(
                                                  themeName,
                                                  themeProducts.length,
                                                  rs),

                                              // 테마 내 상품 그리드
                                              GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: rs.padding(16)),
                                                gridDelegate:
                                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                                  maxCrossAxisExtent: cart
                                                          .isNotEmpty
                                                      ? 280
                                                      : KioskHelper
                                                          .calculateMaxExtent(
                                                              context,
                                                              settings
                                                                  .kioskGridCount,
                                                              cart.isNotEmpty,
                                                              rs),
                                                  childAspectRatio: 0.8,
                                                  crossAxisSpacing:
                                                      rs.padding(16),
                                                  mainAxisSpacing:
                                                      rs.padding(16),
                                                ),
                                                itemCount: themeProducts.length,
                                                itemBuilder: (context, pIndex) {
                                                  final product =
                                                      themeProducts[pIndex];
                                                  return ProductCard(
                                                    product: product,
                                                    onTap: !product.isSoldOut
                                                        ? () =>
                                                            _handleProductTap(
                                                                product)
                                                        : null,
                                                  );
                                                },
                                              ),
                                              const SizedBox(
                                                  height: 12), // 섹션 간 여유 공간
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  /// 오른쪽: 고정 장바구니 패널
                                  if (cart.isNotEmpty)
                                    Container(
                                      width: rs.screenWidth * 0.3,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                            left: BorderSide(
                                                color: Colors.grey.shade200)),
                                      ),
                                      child: CartPanel(
                                        cart: cart,
                                        totalValue: _totalValue(),
                                        totalPrice: _totalPrice(),
                                        getStock: (productId) =>
                                            _getStock(products, productId),
                                        onClear: () =>
                                            setState(() => cart.clear()),
                                        onIncrease: (item) =>
                                            setState(() => item.quantity++),
                                        onDecrease: (item) => setState(() {
                                          if (item.quantity > 1) {
                                            item.quantity--;
                                          } else {
                                            cart.remove(item);
                                          }
                                        }),
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

  Widget _buildThemeSectionHeader(String title, int count, Responsive rs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
                color: PageColors.cateSelect,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
                fontSize: rs.font(20),
                fontWeight: FontWeight.w900,
                color: PageColors.textBlue,
                fontFamily: 'GmarketSans'),
          ),
          const SizedBox(width: 8),
          Text('($count)',
              style: TextStyle(
                  fontSize: rs.font(14),
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleProductTap(ProductModel product) {
    final int currentInCart = _getCartQuantity(product.id);
    final int availableToOrder = product.stock - currentInCart;

    if (availableToOrder <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('이미 모든 재고가 장바구니에 담겨 있습니다.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ProductDetailDialog(
        product: product.copyWith(stock: availableToOrder),
        onAddCart: (targetProduct, quantity) {
          final existing =
              cart.firstWhereOrNull((e) => e.productId == targetProduct.id);
          setState(() {
            if (existing != null) {
              existing.quantity += quantity;
            } else {
              cart.add(OrderItemModel(
                productId: targetProduct.id,
                name: targetProduct.name,
                basePrice: targetProduct.basePrice,
                quantity: quantity,
              ));
            }
          });
        },
      ),
    );
  }
}

class SyncProgressOverlay extends ConsumerWidget {
  const SyncProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProgressProvider);

    if (!syncState.isSyncing) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PageColors.cateSelect.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_download_rounded,
                    color: PageColors.cateSelect, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'POS 데이터 동기화 중',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'GmarketSans'),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: syncState.progress,
                  backgroundColor: Colors.grey[200],
                  color: PageColors.cateSelect,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      syncState.message,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${syncState.percentage}%',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PageColors.cateSelect),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountdownWarningBanner extends StatelessWidget {
  final int remainingSeconds;

  const CountdownWarningBanner({super.key, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds > 10) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '조작이 없을 시 $remainingSeconds초 후 화면이 초기화됩니다.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '화면을 터치하면 계속 주문할 수 있습니다.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
