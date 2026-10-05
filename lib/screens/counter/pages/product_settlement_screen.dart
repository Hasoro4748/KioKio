import 'dart:collection';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiosk/models/order_model.dart';
import 'package:kiosk/models/product_model.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:kiosk/utils/text_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum SettlementGrouping { product, theme, seller }

class ProductSettlementScreen extends ConsumerStatefulWidget {
  const ProductSettlementScreen({super.key});

  @override
  ConsumerState<ProductSettlementScreen> createState() =>
      _ProductSettlementScreenState();
}

class _ProductSettlementScreenState
    extends ConsumerState<ProductSettlementScreen> {
  String _selectedPeriod = '전체'; // 오늘, 7일, 전체 등
  SettlementGrouping _currentGrouping = SettlementGrouping.seller; // 기본값: 상품별
  DateTimeRange? _selectedDateRange;
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023), // 시스템 시작 시점
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ko', 'KR'), // 한국어 설정
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: PageColors.cateSelect)),
        child: child ??
            const SizedBox(), // ★ child! -> child ?? const SizedBox() 변경
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = '사용자설정'; // 커스텀 기간임을 표시
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider);
    final productsAsync = ref.watch(productProvider); // 상품 정보 추가 로드
    final rs = Responsive(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('판매 정산 리포트'),
        actions: [
          _buildPeriodChip('오늘'), _buildPeriodChip('어제'),
          _buildPeriodChip('7일'),
          _buildPeriodChip('전체'),
          IconButton(
            onPressed: _pickDateRange,
            icon: Icon(Icons.date_range,
                color: _selectedPeriod == '사용자설정' ? Colors.blue : Colors.grey),
            tooltip: '기간 직접 선택',
          ),
          const SizedBox(width: 8),
          // 기존 Export 로직 수정 (버튼 클릭 시 데이터 취합 로직은 아래에서 설명)
          IconButton(
            onPressed: () => _handleExport(),
            icon: const Icon(Icons.file_download_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 12),
        ],
        // 그룹화 탭 추가
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: baseBackgroundColor[50],
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                _buildGroupingChip(SettlementGrouping.seller, '판매자별'),
                _buildGroupingChip(SettlementGrouping.theme, '테마별'),
                _buildGroupingChip(SettlementGrouping.product, '전체 상품'),
              ],
            ),
          ),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('에러: $err')),
        data: (orders) {
          return productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                const Center(child: Text('상품 정보를 불러올 수 없어 정밀 정산이 불가합니다.')),
            data: (products) {
              final filteredOrders = _getFilteredOrders(orders);

              final Map<String, List<_SettlementRow>> groupedStats =
                  _calculateGroupedStats(filteredOrders, products);

              final List<_SettlementRow> allStatsList =
                  groupedStats.values.expand((e) => e).toList();

              if (groupedStats.isEmpty)
                return const Center(child: Text('정산 데이터가 없습니다.'));

              return Column(
                children: [
                  // 헤더에는 평탄화된 리스트(allStatsList)를 전달하여 기존 요약 로직 유지
                  _buildSettlementHeader(filteredOrders, allStatsList),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildSettlementTable(
                            groupedStats, rs), // 3. 여기에는 Map(groupedStats) 전달
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<_SettlementRow>> _calculateGroupedStats(
      List<OrderModel> orders, List<ProductModel> products) {
    // 상품 ID별 태그 맵 생성
    final Map<int, List<String>> themeMap = {
      for (var p in products) p.id: p.themes
    };
    final Map<int, List<String>> sellerMap = {
      for (var p in products) p.id: p.sellers
    };

    final Map<String, Map<String, _SettlementRow>> groupedMap = {};

    for (var o in orders) {
      int orderItemSum = o.items
          .fold(0, (sum, item) => sum + (item.basePrice * item.quantity));

      for (var item in o.items) {
        // 할인 배분 로직 유지
        double ratio = orderItemSum > 0
            ? (item.basePrice * item.quantity) / orderItemSum
            : 0;
        int totalItemDiscount = item.discount + (o.discount * ratio).round();
        int itemOriginalPrice = item.basePrice * item.quantity;

        // --- 1. 그룹 결정 로직 수정 ---
        List<String> groups = [];
        if (_currentGrouping == SettlementGrouping.product) {
          groups = ['전체 상품'];
        } else if (_currentGrouping == SettlementGrouping.theme) {
          // 테마가 없으면 ['기타'] 로 할당
          final themes = themeMap[item.productId];
          groups = (themes == null || themes.isEmpty) ? ['기타'] : themes;
        } else if (_currentGrouping == SettlementGrouping.seller) {
          // 판매자가 없으면 ['기타'] 로 할당
          final sellers = sellerMap[item.productId];
          groups = (sellers == null || sellers.isEmpty) ? ['기타'] : sellers;
        }

        // --- 2. 데이터 누적 루프 ---
        for (var group in groups) {
          final productMap = groupedMap.putIfAbsent(group, () => {});

          final existingRow = productMap[item.name];
          if (existingRow != null) {
            existingRow.quantity += item.quantity;
            existingRow.originalRevenue += itemOriginalPrice;
            existingRow.totalDiscount += totalItemDiscount;
          } else {
            productMap[item.name] = _SettlementRow(
              name: item.name,
              quantity: item.quantity,
              originalRevenue: itemOriginalPrice,
              totalDiscount: totalItemDiscount,
            );
          }
        }
      }
    }

    // 알파벳/가나다 순으로 정렬하되 '기타'는 맨 아래로 보내고 싶다면 추가 정렬 가능
    final sortedResult = SplayTreeMap<String, List<_SettlementRow>>.from(
        groupedMap.map((key, value) => MapEntry(key, value.values.toList())),
        (a, b) {
      if (a == '기타') return 1; // a가 기타면 뒤로
      if (b == '기타') return -1; // b가 기타면 앞으로
      return a.compareTo(b); // 나머지는 일반 정렬
    });

    return sortedResult;
  }

  Widget _buildGroupingChip(SettlementGrouping type, String label) {
    final isSelected = _currentGrouping == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        onSelected: (val) =>
            val ? setState(() => _currentGrouping = type) : null,
        selectedColor: PageColors.cateSelect,
      ),
    );
  }
  // --- UI 빌더들 ---

  Widget _buildSettlementHeader(
      List<OrderModel> orders, List<_SettlementRow> stats) {
    String periodText = _selectedPeriod;
    if (_selectedPeriod == '사용자설정' && _selectedDateRange != null) {
      periodText =
          "${DateFormat('MM.dd').format(_selectedDateRange!.start)} ~ ${DateFormat('MM.dd').format(_selectedDateRange!.end)}";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: baseBackgroundColor[50],
      child: Column(
        // Column으로 감싸서 기간 정보 한 줄 추가
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text('조회 기간: $periodText',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderInfo('실제 주문건수', '${orders.length}건'),
              _buildHeaderInfo('순수 매출액',
                  '${TextUtil.money(orders.fold(0, (sum, o) => sum + o.totalPrice))}원'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: PageColors.cateSelect)),
      ],
    );
  }

  Widget _buildSettlementTable(
      Map<String, List<_SettlementRow>> groupedStats, Responsive rs) {
    List<DataRow> allRows = [];
    int totalGrandQty = 0;
    int totalGrandOriginal = 0;
    int totalGrandDiscount = 0;

    groupedStats.forEach((groupName, products) {
      allRows.add(DataRow(
        color: MaterialStateProperty.all(Colors.grey[100]),
        cells: [
          DataCell(Text('📁 $groupName',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: PageColors.cateSelect))),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
        ],
      ));

      int groupQty = 0;
      int groupOriginal = 0;
      int groupDiscount = 0;

      for (var p in products) {
        groupQty += p.quantity;
        groupOriginal += p.originalRevenue;
        groupDiscount += p.totalDiscount;
        allRows.add(DataRow(cells: [
          DataCell(Padding(
              padding: const EdgeInsets.only(left: 12), child: Text(p.name))),
          DataCell(Text('${p.quantity}개')),
          DataCell(Text(TextUtil.money(p.originalRevenue))),
          DataCell(Text(
              groupDiscount > 0 ? '-${TextUtil.money(p.totalDiscount)}' : '0',
              style: const TextStyle(color: Colors.red))),
          DataCell(Text(TextUtil.money(p.finalRevenue),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ]));
      }

      // 그룹 소계
      allRows.add(DataRow(
        cells: [
          const DataCell(Text('└ 소계',
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          DataCell(Text('$groupQty개',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(TextUtil.money(groupOriginal))),
          DataCell(Text('-${TextUtil.money(groupDiscount)}',
              style: const TextStyle(color: Colors.red))),
          DataCell(Text(TextUtil.money(groupOriginal - groupDiscount),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));

      totalGrandQty += groupQty;
      totalGrandOriginal += groupOriginal;
      totalGrandDiscount += groupDiscount;
    });

    // 최종 합계
    allRows.add(DataRow(
      color: MaterialStateProperty.all(PageColors.cateSelect.withOpacity(0.1)),
      cells: [
        const DataCell(
            Text('📊 전체 합계', style: TextStyle(fontWeight: FontWeight.w900))),
        DataCell(Text('$totalGrandQty개',
            style: const TextStyle(fontWeight: FontWeight.w900))),
        DataCell(Text(TextUtil.money(totalGrandOriginal))),
        DataCell(Text('-${TextUtil.money(totalGrandDiscount)}',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold))),
        DataCell(Text(
            '${TextUtil.money(totalGrandOriginal - totalGrandDiscount)}원',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.redAccent))),
      ],
    ));

    return DataTable(
      columnSpacing: rs.isMobile ? 12 : 30,
      columns: const [
        DataColumn(label: Text('분류 / 상품명')),
        DataColumn(label: Text('판매량'), numeric: true),
        DataColumn(label: Text('판매액'), numeric: true),
        DataColumn(label: Text('할인액'), numeric: true),
        DataColumn(label: Text('실매출'), numeric: true),
      ],
      rows: allRows,
    );
  }

  // 필터 및 칩 로직 (OrderTotalScreen과 유사)
  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (val) =>
            val ? setState(() => _selectedPeriod = label) : null,
      ),
    );
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1)); // 어제 자정

    return orders.where((o) {
      if (o.status != '승인') return false;

      final orderDate = o.createdAt;
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

      // 1. 사용자 직접 선택 기간
      if (_selectedPeriod == '사용자설정' && _selectedDateRange != null) {
        return orderDate.isAfter(_selectedDateRange!.start
                .subtract(const Duration(seconds: 1))) &&
            orderDate
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }

      // 2. 어제 필터 (추가)
      if (_selectedPeriod == '어제') {
        return orderDay.isAtSameMomentAs(yesterday);
      }

      // 3. 오늘 필터
      if (_selectedPeriod == '오늘') {
        return orderDay.isAtSameMomentAs(today);
      }

      // 4. 최근 7일 필터
      if (_selectedPeriod == '7일') {
        final diff = now.difference(orderDate).inDays;
        return diff <= 7;
      }

      return true; // 전체
    }).toList();
  }

  // 다이얼로그의 '저장하기' 버튼에 연결
  void _showExportDialog(Map<String, List<_SettlementRow>> stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('상세 리포트 내보내기'),
        content: const Text('현재 보고 계신 그룹별 상세 내역을 CSV 파일로 저장하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _exportToCSV(stats);
              },
              child: const Text('저장하기')),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(
      Map<String, List<_SettlementRow>> groupedStats) async {
    try {
      // 1. 권한 확인 (Android 전용)
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.request().isGranted) {
          _showMessage("📁 '모든 파일 관리 권한'이 필요합니다. 설정에서 허용해 주세요.");
          await openAppSettings();
          return;
        }
      }

      // 2. CSV 데이터 생성
      StringBuffer csvBuffer = StringBuffer();
      // BOM (\uFEFF) 추가로 엑셀 한글 깨짐 방지
      csvBuffer.write("\uFEFF구분/상품명,판매량,판매원가,할인액,실매출액\n");

      int grandQty = 0, grandOrig = 0, grandDisc = 0;

      groupedStats.forEach((groupName, products) {
        csvBuffer.write("[$groupName],,,,\n");
        int gQty = 0, gOrig = 0, gDisc = 0;
        for (var p in products) {
          csvBuffer.write(
              "${p.name},${p.quantity},${p.originalRevenue},${p.totalDiscount},${p.finalRevenue}\n");
          gQty += p.quantity;
          gOrig += p.originalRevenue;
          gDisc += p.totalDiscount;
        }
        csvBuffer
            .write(" > 소계,${gQty}개,${gOrig},${gDisc},${gOrig - gDisc}\n\n");
        grandQty += gQty;
        grandOrig += gOrig;
        grandDisc += gDisc;
      });

      csvBuffer.write("----------------,,,,\n");
      csvBuffer.write(
          "📊 최종 전체 합계,${grandQty}개,${grandOrig},${grandDisc},${grandOrig - grandDisc}\n");

      // 3. 파일 저장 경로 확보 (Download 폴더)
      String path;
      if (Platform.isAndroid) {
        path = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD);
      } else {
        // Windows/Desktop 대응
        final directory = await getDownloadsDirectory();
        path =
            directory?.path ?? (await getApplicationDocumentsDirectory()).path;
      }

      final String timeStamp =
          DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File("$path/정산상세리포트_$timeStamp.csv");

      // 4. [핵심] 실제 파일 쓰기 실행
      await file.writeAsString(csvBuffer.toString());

      _showMessage(
          "✅ CSV 저장이 완료되었습니다!\n경로: $path\n파일명: ${file.path.split('/').last}");
    } catch (e) {
      print("CSV 내보내기 에러 상세: $e");
      _showMessage("❌ 파일 생성 중 오류가 발생했습니다: $e");
    }
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _handleExport() {
    final orders = ref.read(orderProvider).value;
    final products = ref.read(productProvider).value;
    if (orders == null || products == null) return;

    // 현재 화면에 표시된 필터 및 그룹화 기준이 적용된 'Map' 데이터를 계산
    final filtered = _getFilteredOrders(orders);
    final groupedData = _calculateGroupedStats(filtered, products);

    _showExportDialog(groupedData); // Map 전달
  }
}

class _SettlementRow {
  final String name;
  int quantity;
  int originalRevenue; // 할인 전 총액
  int totalDiscount; // 해당 상품에서 발생한 총 할인액

  int get finalRevenue => originalRevenue - totalDiscount; // 실매출

  _SettlementRow(
      {required this.name,
      required this.quantity,
      required this.originalRevenue,
      required this.totalDiscount});
}
