import 'dart:io';

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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: PageColors.cateSelect),
          ),
          child: child!,
        );
      },
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

  List<_SettlementRow> _calculateStats(
      List<OrderModel> orders, List<ProductModel> products) {
    final Map<int, List<String>> themeMap = {
      for (var p in products) p.id: p.themes
    };
    final Map<int, List<String>> sellerMap = {
      for (var p in products) p.id: p.sellers
    };

    final Map<String, _SettlementRow> map = {};

    for (var o in orders) {
      for (var item in o.items) {
        // 현재 그룹화 기준에 따른 키(Key) 결정
        List<String> keys = [];
        if (_currentGrouping == SettlementGrouping.product) {
          keys = [item.name];
        } else if (_currentGrouping == SettlementGrouping.theme) {
          keys = themeMap[item.productId] ?? ['미지정'];
        } else if (_currentGrouping == SettlementGrouping.seller) {
          keys = sellerMap[item.productId] ?? ['미지정'];
        }

        for (var key in keys) {
          if (map.containsKey(key)) {
            map[key]!.quantity += item.quantity;
            map[key]!.totalRevenue += item.totalPrice;
          } else {
            map[key] = _SettlementRow(
              name: key,
              quantity: item.quantity,
              unitPrice: item.basePrice,
              totalRevenue: item.totalPrice,
            );
          }
        }
      }
    }
    return map.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  Map<String, List<_SettlementRow>> _calculateGroupedStats(
      List<OrderModel> orders, List<ProductModel> products) {
    final Map<int, List<String>> themeMap = {
      for (var p in products) p.id: p.themes
    };
    final Map<int, List<String>> sellerMap = {
      for (var p in products) p.id: p.sellers
    };

    // 기준(Key)별 상품 집계
    // Map<그룹명, Map<상품명, 데이터>> 구조로 먼저 중복 제거 합산
    final Map<String, Map<String, _SettlementRow>> groupedMap = {};

    for (var o in orders) {
      for (var item in o.items) {
        List<String> groups = [];
        if (_currentGrouping == SettlementGrouping.product) {
          groups = ['전체 상품'];
        } else if (_currentGrouping == SettlementGrouping.theme) {
          groups = themeMap[item.productId] ?? ['미지정'];
        } else if (_currentGrouping == SettlementGrouping.seller) {
          groups = sellerMap[item.productId] ?? ['미지정'];
        }

        for (var group in groups) {
          groupedMap.putIfAbsent(group, () => {});
          final productMap = groupedMap[group]!;

          if (productMap.containsKey(item.name)) {
            productMap[item.name]!.quantity += item.quantity;
            productMap[item.name]!.totalRevenue += item.totalPrice;
          } else {
            productMap[item.name] = _SettlementRow(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.basePrice,
              totalRevenue: item.totalPrice,
            );
          }
        }
      }
    }

    // 최종 결과 반환 (그룹 이름순 정렬)
    return groupedMap.map((key, value) => MapEntry(key, value.values.toList()));
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
    int totalGrandRev = 0;

    groupedStats.forEach((groupName, products) {
      // A. 그룹 헤더 행 (구분선 역할)
      allRows.add(DataRow(
        color: MaterialStateProperty.all(Colors.grey[100]),
        cells: [
          DataCell(Text('📁 $groupName',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: PageColors.cateSelect))),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
        ],
      ));

      int groupQty = 0;
      int groupRev = 0;

      // B. 상품 개별 행
      for (var p in products) {
        groupQty += p.quantity;
        groupRev += p.totalRevenue;
        allRows.add(DataRow(cells: [
          DataCell(Padding(
              padding: const EdgeInsets.only(left: 12), child: Text(p.name))),
          DataCell(Text('${p.quantity}개')),
          DataCell(Text(TextUtil.money(p.unitPrice))),
          DataCell(Text(TextUtil.money(p.totalRevenue))),
        ]));
      }

      // C. 그룹 소계 행
      allRows.add(DataRow(
        cells: [
          const DataCell(Text('└ 소계',
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          DataCell(Text('$groupQty개',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          const DataCell(Text('')),
          DataCell(Text(TextUtil.money(groupRev),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey))),
        ],
      ));

      totalGrandQty += groupQty;
      totalGrandRev += groupRev;
    });

    // D. 최종 합계 행
    allRows.add(DataRow(
      color: MaterialStateProperty.all(PageColors.cateSelect.withOpacity(0.1)),
      cells: [
        const DataCell(
            Text('📊 전체 합계', style: TextStyle(fontWeight: FontWeight.w900))),
        DataCell(Text('$totalGrandQty개',
            style: const TextStyle(fontWeight: FontWeight.w900))),
        const DataCell(Text('')),
        DataCell(Text(TextUtil.money(totalGrandRev),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.redAccent))),
      ],
    ));

    return DataTable(
      columnSpacing: rs.isMobile ? 20 : 50,
      headingRowColor: MaterialStateProperty.all(baseBackgroundColor[100]),
      columns: const [
        DataColumn(
            label: Text('분류 / 상품명',
                style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('판매량', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true),
        DataColumn(
            label: Text('단가', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true),
        DataColumn(
            label: Text('총 매출', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true),
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
  void _showExportDialog(List<_SettlementRow> stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('리포트 내보내기'),
        content: Text('현재 조회된 ${stats.length}개의 항목을 CSV 파일로 저장하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _exportToCSV(stats); // 실제 파일 저장 함수 호출
              },
              child: const Text('저장하기')),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(List<_SettlementRow> stats) async {
    try {
      // 1. CSV 데이터 생성 (헤더 포함)
      String csvData = "상품명,판매량,단가,총 매출합계\n";
      for (var row in stats) {
        csvData +=
            "${row.name},${row.quantity},${row.unitPrice},${row.totalRevenue}\n";
      }

      // 2. 저장 경로 확보 (문서 폴더)
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          "정산리포트_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";
      final File file = File("${directory.path}/$fileName");

      // 3. 파일 쓰기
      await file.writeAsString(csvData);

      // 4. 완료 알림 및 경로 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 CSV 파일이 저장되었습니다.\n경로: ${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: '확인', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      print("파일 저장 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 파일 저장 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _handleExport() {
    final orders = ref.read(orderProvider).value;
    final products = ref.read(productProvider).value;
    if (orders == null || products == null) return;

    final stats = _calculateStats(_getFilteredOrders(orders), products);
    _showExportDialog(stats);
  }
}

class _SettlementRow {
  final String name;
  int quantity;
  final int unitPrice;
  int totalRevenue;
  _SettlementRow(
      {required this.name,
      required this.quantity,
      required this.unitPrice,
      required this.totalRevenue});
}
