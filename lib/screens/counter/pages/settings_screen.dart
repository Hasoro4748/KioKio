import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:path/path.dart' as p;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _welcomeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 초기값 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeController.text = ref.read(settingsProvider).kioskWelcomeMessage;
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  // 로고 선택 로직
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // 로컬 설정을 먼저 업데이트 (이미지 경로는 나중에 동기화 시 데이터로 변환)
      // 실제 구현 시에는 앱 내부 폴더로 복사하는 과정이 권장됩니다.
      await ref.read(settingsProvider.notifier).updateKioskSettings(
            KioskSettingsModel(
              gridCount: ref.read(settingsProvider).kioskGridCount,
              logoPath: image.path,
              welcomeMessage: _welcomeController.text,
              waitTime: ref.read(settingsProvider).kioskWaitTime,
              useIdleScreen: ref.read(settingsProvider).useKioskIdleScreen,
            ),
          );
    }
  }

  // 키오스크로 설정 전송 (동기화)
  Future<void> _syncToKiosks() async {
    final settings = ref.read(settingsProvider);
    Map<String, String>? imageDatas;

    // 로고 이미지가 있다면 Base64로 변환하여 동기화 메시지에 포함
    if (settings.kioskLogoPath.isNotEmpty) {
      final file = File(settings.kioskLogoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = p.basename(settings.kioskLogoPath);
        imageDatas = {fileName: base64Encode(bytes)};
      }
    }

    final model = KioskSettingsModel(
      gridCount: settings.kioskGridCount,
      logoPath: settings.kioskLogoPath.isNotEmpty
          ? p.basename(settings.kioskLogoPath)
          : '',
      welcomeMessage: _welcomeController.text,
      waitTime: settings.kioskWaitTime,
      useIdleScreen: settings.useKioskIdleScreen,
    );

    ref
        .read(posNetworkServiceProvider.notifier)
        .broadcastKioskSettings(model, imageDatas: imageDatas);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 모든 키오스크에 설정이 적용되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: const Text('시스템 환경설정',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(rs.padding(20)),
        child: Column(
          children: [
            // 1. POS 관리 설정 섹션
            _buildSection(
              title: 'POS 관리 화면 설정',
              icon: Icons.monitor,
              children: [
                _buildSliderTile(
                  label: '상품 관리 그리드 개수',
                  value: settings.productManageGridCount.toDouble(),
                  min: 5,
                  max: 10,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateProductManageGridCount(val.toInt()),
                  trailing: '${settings.productManageGridCount}개',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. 원격 키오스크 제어 섹션
            _buildSection(
              title: '원격 키오스크 제어 (실시간)',
              icon: Icons.settings_remote,
              color: Colors.orangeAccent,
              children: [
                // 로고 설정
                ListTile(
                  title: const Text('키오스크 상단 로고'),
                  subtitle: const Text('키오스크 화면 상단에 표시될 이미지를 선택하세요.'),
                  trailing: settings.kioskLogoPath.isEmpty
                      ? const Icon(Icons.add_photo_alternate_outlined)
                      : Image.file(File(settings.kioskLogoPath),
                          width: 50, height: 50, fit: BoxFit.cover),
                  onTap: _pickLogo,
                ),
                const Divider(),
                // 그리드 설정
                _buildSliderTile(
                  label: '키오스크 상품 한 줄 개수',
                  value: settings.kioskGridCount.toDouble(),
                  min: 3,
                  max: 7,
                  onChanged: (val) =>
                      _updateKioskSettingsState(gridCount: val.toInt()),
                  trailing: '${settings.kioskGridCount}개',
                ),
                const Divider(),
                // 대기 시간 설정
                _buildSliderTile(
                  label: '자동 초기화 대기 시간',
                  value: settings.kioskWaitTime.toDouble(),
                  min: 10,
                  max: 60,
                  onChanged: (val) =>
                      _updateKioskSettingsState(waitTime: val.toInt()),
                  trailing: '${settings.kioskWaitTime}초',
                ),
                const Divider(),
                // 대기화면 사용 여부
                SwitchListTile(
                  title: const Text('대기화면(광고) 사용'),
                  subtitle: const Text('일정 시간 미조작 시 대기화면으로 전환합니다.'),
                  value: settings.useKioskIdleScreen,
                  onChanged: (val) => _updateKioskSettingsState(useIdle: val),
                ),
                const Divider(),
                // 웰컴 메시지
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _welcomeController,
                    decoration: const InputDecoration(
                      labelText: '대기화면 안내 문구',
                      border: OutlineInputBorder(),
                      hintText: '예: 터치하여 주문을 시작하세요',
                    ),
                    onChanged: (val) => _updateKioskSettingsState(welcome: val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 전송 버튼
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _syncToKiosks,
                icon: const Icon(Icons.sync_rounded, color: Colors.white),
                label: const Text('키오스크에 설정 실시간 적용하기',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PageColors.cateSelect,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 상태만 로컬에서 변경하는 헬퍼 (저장 및 동기화 버튼 클릭 전 단계)
  void _updateKioskSettingsState(
      {int? gridCount, int? waitTime, bool? useIdle, String? welcome}) {
    final current = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).updateKioskSettings(
          KioskSettingsModel(
            gridCount: gridCount ?? current.kioskGridCount,
            logoPath: current.kioskLogoPath,
            welcomeMessage: welcome ?? _welcomeController.text,
            waitTime: waitTime ?? current.kioskWaitTime,
            useIdleScreen: useIdle ?? current.useKioskIdleScreen,
          ),
        );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required List<Widget> children,
      Color color = PageColors.cateSelect}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderTile(
      {required String label,
      required double value,
      required double min,
      required double max,
      required Function(double) onChanged,
      required String trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 5,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
              width: 40,
              child: Text(trailing,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
